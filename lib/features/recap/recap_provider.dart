import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/data_providers.dart';
import '../../core/db/providers.dart';
import '../../core/security/secure_store.dart';
import '../settings/data/settings_dao.dart';
import '../transactions/data/transactions_dao.dart';
import 'data/weekly_recap.dart';

/// Hari dengan catatan buatan pengguna.
final loggedDaysProvider = StreamProvider<Set<DateTime>>(
  (ref) => ref.watch(appDatabaseProvider).transactionsDao.watchLoggedDays(),
);

final streakProvider = Provider<Streak?>((ref) {
  final Set<DateTime>? days = ref.watch(loggedDaysProvider).valueOrNull;
  ref.watch(currentDayProvider);
  return days == null ? null : computeStreak(days, ref.read(clockProvider)());
});

/// Rekap minggu ke-[offset] ke belakang (0 = minggu ini, 1 = minggu lalu).
final weeklyRecapProvider = StreamProvider.family<WeeklyRecap, int>((ref, offset) {
  final DateTime today = ref.watch(currentDayProvider);
  final DateTime thisWeek = weekStart(today);
  final DateTime start = DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * offset);
  final DateTime from = DateTime(start.year, start.month, start.day - 7);
  final DateTime to = DateTime(start.year, start.month, start.day + 7);
  return ref.watch(appDatabaseProvider).transactionsDao.watchBetween(from, to).map((rows) {
    final Set<DateTime> logged = ref.read(loggedDaysProvider).valueOrNull ?? {
      for (final TxDetail d in rows)
        if (d.tx.recurringId == null) DateTime(d.tx.occurredAt.year, d.tx.occurredAt.month, d.tx.occurredAt.day),
    };
    return computeWeeklyRecap(
      start: start,
      loggedDays: logged,
      txs: [
        for (final TxDetail d in rows)
          (
            kind: d.tx.kind,
            amount: d.tx.amount,
            at: d.tx.occurredAt,
            categoryId: d.tx.categoryId,
            category: d.category?.name ?? 'Lainnya',
          ),
      ],
    );
  });
});

/// Pengaturan notifikasi rekap (P3a): rekap Senin menyala, pengingat malam mati.
final recapWeeklyProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.recapWeekly).map((v) => v != 'false'),
);

final recapEveningProvider = StreamProvider<bool>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.recapEvening).map((v) => v == 'true'),
);

/// Minggu (Senin) yang kartu rekapnya sudah ditutup di Beranda.
final recapDismissedProvider = StreamProvider<String?>(
  (ref) => ref.watch(appDatabaseProvider).settingsDao.watch(SettingKeys.recapDismissed),
);
