import '../../../core/db/app_database.dart';
import '../../debts/data/debts_dao.dart';
import '../../wallets/data/wallets_dao.dart';

/// Nilai satu aset/kewajiban manual. Emas = miligram × harga per gram.
int netItemValue(NetItem i) => i.kind == NetItemKind.emas
    ? ((i.milligrams ?? 0) * (i.pricePerGram ?? 0) / 1000).round()
    : i.value;

/// Pengingat perbarui nilai: lebih dari 30 hari.
const int netItemStaleDays = 30;

bool netItemStale(NetItem i, DateTime now) => now.difference(i.updatedAt).inDays > netItemStaleDays;

/// Kelompok komposisi aset.
enum NetGroup {
  dompet('Dompet & piutang'),
  emas('Emas'),
  investasi('Investasi'),
  properti('Properti & kendaraan'),
  lainnya('Lainnya');

  const NetGroup(this.label);
  final String label;
}

/// Satu baris aset/kewajiban; [item] kosong = dihitung otomatis.
typedef NetLine = ({String name, String hint, int value, NetGroup? group, NetItem? item, String icon});

/// Hasil Kekayaan bersih.
class NetWorth {
  const NetWorth({required this.assets, required this.liabilities});

  final List<NetLine> assets;
  final List<NetLine> liabilities;

  int get totalAssets => assets.fold(0, (s, l) => s + l.value);
  int get totalLiabilities => liabilities.fold(0, (s, l) => s + l.value);
  int get net => totalAssets - totalLiabilities;

  Map<NetGroup, int> get composition {
    final Map<NetGroup, int> out = {};
    for (final NetLine l in assets) {
      if (l.group == null || l.value <= 0) continue;
      out[l.group!] = (out[l.group!] ?? 0) + l.value;
    }
    return out;
  }
}

NetGroup _groupOf(NetItemKind k) => switch (k) {
      NetItemKind.emas => NetGroup.emas,
      NetItemKind.investasi => NetGroup.investasi,
      NetItemKind.properti => NetGroup.properti,
      _ => NetGroup.lainnya,
    };

/// Hitung kekayaan bersih. Otomatis: saldo dompet aktif, piutang, utang,
/// sisa cicilan tagihan. Manual ([items]) hanya bila [includeManual] (Pro).
/// [setAside] = uang yang disisihkan ke target (rincian, tidak dihitung dua kali).
NetWorth computeNetWorth({
  required List<WalletBalance> wallets,
  required List<DebtWithPayments> debts,
  required List<Bill> bills,
  required List<NetItem> items,
  required bool includeManual,
  int setAside = 0,
  String Function(NetItem)? hintOf,
}) {
  final List<WalletBalance> active = [for (final w in wallets) if (!w.wallet.archived) w];
  final int walletTotal = active.fold(0, (s, w) => s + w.balance);
  final List<DebtWithPayments> receivable = [
    for (final d in debts) if (d.debt.direction == DebtDirection.piutang && d.left > 0) d,
  ];
  final List<DebtWithPayments> payable = [
    for (final d in debts) if (d.debt.direction == DebtDirection.utang && d.left > 0) d,
  ];
  final List<Bill> installments = [
    for (final b in bills)
      if (b.active && b.installmentTotal != null && b.installmentTotal! > b.installmentPaid) b,
  ];
  String names(Iterable<String> n) => n.length <= 2 ? n.join(', ') : '${n.take(2).join(', ')} +${n.length - 2}';

  final List<NetLine> assets = [
    (
      name: 'Dompet',
      hint: '${active.length} dompet${setAside > 0 ? ' · termasuk disisihkan untuk target' : ''}',
      value: walletTotal,
      group: NetGroup.dompet,
      item: null,
      icon: 'wallet',
    ),
    if (receivable.isNotEmpty)
      (
        name: 'Piutang',
        hint: names(receivable.map((d) => d.debt.name)),
        value: receivable.fold(0, (s, d) => s + d.left),
        group: NetGroup.dompet,
        item: null,
        icon: 'debtSwap',
      ),
    if (includeManual)
      for (final i in items)
        if (!i.kind.isLiability)
          (name: i.name, hint: hintOf?.call(i) ?? i.kind.label, value: netItemValue(i), group: _groupOf(i.kind), item: i, icon: i.kind.name),
  ];
  final List<NetLine> liabilities = [
    for (final d in payable)
      (name: 'Utang ke ${d.debt.name}', hint: 'Utang-piutang', value: d.left, group: null, item: null, icon: 'debtSwap'),
    for (final b in installments)
      (
        name: b.name,
        hint: 'Sisa ${b.installmentTotal! - b.installmentPaid} dari ${b.installmentTotal} cicilan',
        value: (b.installmentTotal! - b.installmentPaid) * b.amount,
        group: null,
        item: null,
        icon: 'installment',
      ),
    if (includeManual)
      for (final i in items)
        if (i.kind.isLiability)
          (name: i.name, hint: hintOf?.call(i) ?? i.kind.label, value: netItemValue(i), group: null, item: i, icon: 'pinjaman'),
  ];
  return NetWorth(assets: assets, liabilities: liabilities);
}
