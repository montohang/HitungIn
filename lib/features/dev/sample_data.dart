import '../../core/db/app_database.dart';

/// Data uji fiktif untuk build debug (menu Lainnya › Isi data uji): dompet,
/// ±3 bulan transaksi, budget mulai bulan lalu, dan dua target tabungan.
/// Nama & nominal karangan, bukan data siapa pun.
Future<int> seedSampleData(AppDatabase db, DateTime now) => db.transaction(() async {
      final List<Category> cats = await db.categoriesDao.active();
      int? cat(String name, TxKind kind) => cats.where((c) => c.name == name && c.kind == kind).firstOrNull?.id;
      final List<Wallet> wallets = await db.walletsDao.active();
      final int bca = await db.walletsDao.add(name: 'BCA (uji)', type: WalletType.bank, initialBalance: 4000000);
      final int gopay = await db.walletsDao.add(name: 'GoPay (uji)', type: WalletType.ewallet, initialBalance: 300000);
      final int tunai = wallets.firstOrNull?.id ?? bca;

      int n = 0;
      Future<void> spend(String category, int amount, int wallet, DateTime at, String note) async {
        final int? id = cat(category, TxKind.pengeluaran);
        if (id == null || at.isAfter(now)) return;
        await db.transactionsDao.add(
            kind: TxKind.pengeluaran, amount: amount, walletId: wallet, categoryId: id, note: note, occurredAt: at);
        n++;
      }

      // Pola bulanan (nominal ribuan); bulan berjalan sampai hari ini saja.
      for (int k = 3; k >= 0; k--) {
        final DateTime m = DateTime(now.year, now.month - k);
        final int? gaji = cat('Gaji', TxKind.pemasukan);
        if (gaji != null && DateTime(m.year, m.month - 1, 25).isBefore(now)) {
          await db.transactionsDao.add(
              kind: TxKind.pemasukan,
              amount: 8500000,
              walletId: bca,
              categoryId: gaji,
              note: 'Gaji (uji)',
              occurredAt: DateTime(m.year, m.month - 1, 25, 9));
          n++;
        }
        final bool thisMonth = k == 0;
        for (int d = 1; d <= 28; d++) {
          final DateTime day = DateTime(m.year, m.month, d, 12);
          await spend('Makan & Minum', thisMonth ? 56000 : 42000 + (d % 3) * 3000, gopay, day, 'Makan (uji)');
          if (d % 2 == 0) await spend('Transportasi', 22000, tunai, day.add(const Duration(hours: 6)), 'Ojol (uji)');
          if (d % 7 == 3) await spend('Belanja', 210000, bca, day, 'Belanja bulanan (uji)');
          if (d % 10 == 5) await spend('Hiburan', thisMonth ? 60000 : 95000, gopay, day, 'Nonton (uji)');
        }
        await spend('Tagihan', 350000, bca, DateTime(m.year, m.month, 5, 10), 'Internet (uji)');
        await spend('Tagihan', 250000, bca, DateTime(m.year, m.month, 6, 10), 'Listrik (uji)');
      }

      // Budget mulai bulan lalu: bulan lalu ada sisa, bulan ini Makan lewat batas.
      final DateTime from = DateTime(now.year, now.month - 1);
      final Map<String, int> limits = {
        'Makan & Minum': 1400000,
        'Transportasi': 400000,
        'Belanja': 1000000,
        'Hiburan': 400000,
        'Tagihan': 650000,
      };
      await db.budgetsDao.setLimit(limitAmount: 4200000, from: from);
      for (final MapEntry<String, int> e in limits.entries) {
        final int? id = cat(e.key, TxKind.pengeluaran);
        if (id != null) await db.budgetsDao.setLimit(categoryId: id, limitAmount: e.value, from: from);
      }

      await db.goalsDao.add(name: 'Liburan (uji)', target: 6000000, emoji: '🏝️', dueDate: DateTime(now.year + 1, 4, 20));
      await db.goalsDao.add(name: 'Dana darurat (uji)', target: 3000000, emoji: '🛟');
      return n;
    });
