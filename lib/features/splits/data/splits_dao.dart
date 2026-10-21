import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

part 'splits_dao.g.dart';

/// Patungan beserta peserta (urut posisi) dan item menunya.
typedef SplitFull = ({Split split, List<SplitMember> members, List<SplitItem> items});

/// Isian satu peserta saat menyimpan.
typedef MemberInput = ({String name, bool isMe, bool payer, int share});

/// Isian satu item menu saat menyimpan ([who] = posisi peserta).
typedef ItemInput = ({String name, int price, Set<int> who});

extension SplitFullX on SplitFull {
  SplitMember get me => members.firstWhere((m) => m.isMe);
  SplitMember get payer => members.firstWhere((m) => m.payer);
  bool get iPaid => payer.isMe;

  /// Item menu milik peserta di [position].
  List<String> itemsOf(int position) => [
        for (final i in items)
          if (i.who.split(',').contains('$position')) i.name,
      ];
}

@DriftAccessor(tables: [Splits, SplitMembers, SplitItems, Debts, DebtPayments, Transactions])
class SplitsDao extends DatabaseAccessor<AppDatabase> with _$SplitsDaoMixin {
  SplitsDao(super.attachedDatabase);

  /// Semua patungan, terbaru dulu.
  Stream<List<SplitFull>> watchAll() {
    final Stream<List<Split>> head = (select(splits)
          ..orderBy([(s) => OrderingTerm.desc(s.occurredAt), (s) => OrderingTerm.desc(s.id)]))
        .watch();
    return head.asyncMap((list) async {
      final List<SplitMember> ms = await (select(splitMembers)..orderBy([(m) => OrderingTerm(expression: m.position)])).get();
      final List<SplitItem> its = await (select(splitItems)..orderBy([(i) => OrderingTerm(expression: i.position)])).get();
      return [
        for (final s in list)
          (
            split: s,
            members: [for (final m in ms) if (m.splitId == s.id) m],
            items: [for (final i in its) if (i.splitId == s.id) i],
          ),
      ];
    });
  }

  Future<SplitFull?> byId(int id) async {
    final Split? s = await (select(splits)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (s == null) return null;
    return (
      split: s,
      members: await (select(splitMembers)
            ..where((m) => m.splitId.equals(id))
            ..orderBy([(m) => OrderingTerm(expression: m.position)]))
          .get(),
      items: await (select(splitItems)
            ..where((i) => i.splitId.equals(id))
            ..orderBy([(i) => OrderingTerm(expression: i.position)]))
          .get(),
    );
  }

  /// Simpan patungan baru ([id] null) atau ganti isinya. Aku yang bayar →
  /// pengeluaran bagianku + piutang tiap teman (saldo berkurang total).
  /// Teman yang bayar → pengeluaran bagianku + utangku ke dia (saldo tetap).
  /// Mengubah patungan yang sudah ada pembayarannya ditolak.
  Future<int> save({
    int? id,
    required String title,
    required SplitMode mode,
    required int total,
    required int walletId,
    int? categoryId,
    required DateTime occurredAt,
    required List<MemberInput> members,
    List<ItemInput> items = const [],
    int taxPermille = 0,
    int servicePermille = 0,
    int extraFee = 0,
    int discount = 0,
  }) =>
      transaction(() async {
        _validate(title, total, members);
        final SplitsCompanion row = SplitsCompanion(
          title: Value(title.trim()),
          mode: Value(mode),
          total: Value(total),
          walletId: Value(walletId),
          categoryId: Value(categoryId),
          taxPermille: Value(taxPermille),
          servicePermille: Value(servicePermille),
          extraFee: Value(extraFee),
          discount: Value(discount),
          occurredAt: Value(occurredAt),
        );
        final int splitId;
        if (id == null) {
          splitId = await into(splits).insert(row);
        } else {
          if (await hasPayments(id)) {
            throw StateError('Sudah ada pembayaran di Utang-piutang');
          }
          splitId = id;
          await (update(splits)..where((s) => s.id.equals(id))).write(row);
          await (delete(transactions)..where((t) => t.splitId.equals(id))).go();
          await (delete(debts)..where((d) => d.splitId.equals(id))).go();
          await (delete(splitMembers)..where((m) => m.splitId.equals(id))).go();
          await (delete(splitItems)..where((i) => i.splitId.equals(id))).go();
        }
        final String name = title.trim();
        final MemberInput me = members.firstWhere((m) => m.isMe);
        final MemberInput payer = members.firstWhere((m) => m.payer);
        if (me.share > 0) {
          await into(transactions).insert(TransactionsCompanion.insert(
            kind: TxKind.pengeluaran,
            amount: me.share,
            walletId: walletId,
            categoryId: Value(categoryId),
            note: Value(name),
            occurredAt: occurredAt,
            splitId: Value(splitId),
          ));
        }
        for (final (int pos, MemberInput m) in members.indexed) {
          int? debtId;
          if (payer.isMe && !m.isMe && m.share > 0) {
            debtId = await attachedDatabase.debtsDao.add(
              direction: DebtDirection.piutang,
              name: m.name.trim(),
              amount: m.share,
              occurredAt: occurredAt,
              walletId: walletId,
              note: 'Patungan $name',
              splitId: splitId,
            );
          } else if (!payer.isMe && m.payer && me.share > 0) {
            debtId = await attachedDatabase.debtsDao.add(
              direction: DebtDirection.utang,
              name: m.name.trim(),
              amount: me.share,
              occurredAt: occurredAt,
              walletId: walletId,
              note: 'Patungan $name',
              splitId: splitId,
            );
          }
          await into(splitMembers).insert(SplitMembersCompanion.insert(
            splitId: splitId,
            name: m.name.trim(),
            isMe: Value(m.isMe),
            payer: Value(m.payer),
            share: m.share,
            position: pos,
            debtId: Value(debtId),
          ));
        }
        for (final (int pos, ItemInput it) in items.indexed) {
          await into(splitItems).insert(SplitItemsCompanion.insert(
            splitId: splitId,
            name: it.name.trim(),
            price: it.price,
            who: (it.who.toList()..sort()).join(','),
            position: pos,
          ));
        }
        return splitId;
      });

  /// Ada pembayaran tercatat di salah satu catatan utang-piutangnya.
  Future<bool> hasPayments(int splitId) async {
    final q = select(debtPayments).join([innerJoin(debts, debts.id.equalsExp(debtPayments.debtId))])
      ..where(debts.splitId.equals(splitId));
    return (await q.get()).isNotEmpty;
  }

  /// Hapus patungan beserta pengeluaran, catatan utang-piutang & pembayarannya
  /// (saldo dompet kembali).
  Future<void> remove(int id) => (delete(splits)..where((s) => s.id.equals(id))).go();

  static void _validate(String title, int total, List<MemberInput> members) {
    if (title.trim().isEmpty) throw ArgumentError('Judul wajib diisi');
    if (total <= 0) throw ArgumentError.value(total, 'total', 'Total harus lebih dari 0');
    if (members.length < 2) throw ArgumentError('Minimal dua peserta');
    if (members.where((m) => m.isMe).length != 1) throw ArgumentError('Harus ada tepat satu "aku"');
    if (members.where((m) => m.payer).length != 1) throw ArgumentError('Harus ada tepat satu pembayar');
    if (members.fold(0, (a, m) => a + m.share) != total) throw ArgumentError('Jumlah bagian tidak sama dengan total');
  }
}
