import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import 'data/goals_dao.dart';

/// Semua target tabungan beserta setorannya (urutan dibuat).
final goalsProvider = StreamProvider<List<GoalWithDeposits>>(
  (ref) => ref.watch(appDatabaseProvider).goalsDao.watchAll(),
);
