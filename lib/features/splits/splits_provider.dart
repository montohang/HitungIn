import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/providers.dart';
import '../debts/data/debts_dao.dart';
import '../debts/debts_provider.dart';
import 'data/splits_dao.dart';

/// Semua patungan, terbaru dulu.
final splitsProvider = StreamProvider<List<SplitFull>>(
  (ref) => ref.watch(appDatabaseProvider).splitsDao.watchAll(),
);

/// Status bayar satu peserta (dari catatan utang-piutangnya).
typedef MemberStatus = ({int share, int paid, int left, bool settled});

/// Status tiap peserta (kunci = id peserta). Peserta tanpa catatan utang
/// (aku, atau teman lain saat bukan aku yang bayar) dianggap selesai.
Map<int, MemberStatus> memberStatuses(SplitFull s, Map<int, DebtWithPayments> debts) => {
      for (final SplitMember m in s.members)
        m.id: switch (m.debtId == null ? null : debts[m.debtId]) {
          final DebtWithPayments d? => (share: d.debt.amount, paid: d.paid, left: d.left, settled: d.left == 0),
          _ => (share: m.share, paid: 0, left: 0, settled: true),
        },
    };

/// Ringkas: berapa teman yang sudah bayar dari yang harus bayar, dan sisa
/// yang belum kembali ke aku (aku yang bayar) atau utangku (teman yang bayar).
typedef SplitProgress = ({int settled, int count, int owedToMe, int iOwe});

SplitProgress splitProgress(SplitFull s, Map<int, DebtWithPayments> debts) {
  final Map<int, MemberStatus> st = memberStatuses(s, debts);
  final List<SplitMember> withDebt = [for (final m in s.members) if (m.debtId != null) m];
  final int left = withDebt.fold(0, (a, m) => a + st[m.id]!.left);
  return (
    settled: withDebt.where((m) => st[m.id]!.settled).length,
    count: withDebt.length,
    owedToMe: s.iPaid ? left : 0,
    iOwe: s.iPaid ? 0 : left,
  );
}

/// Catatan utang-piutang per id, untuk status patungan.
final debtsByIdProvider = Provider<Map<int, DebtWithPayments>>((ref) => {
      for (final d in ref.watch(debtsProvider).valueOrNull ?? const <DebtWithPayments>[]) d.debt.id: d,
    });
