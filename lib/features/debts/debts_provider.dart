import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/providers.dart';
import 'data/debts_dao.dart';

/// Semua catatan utang-piutang beserta pembayarannya (terbaru dulu).
final debtsProvider = StreamProvider<List<DebtWithPayments>>(
  (ref) => ref.watch(appDatabaseProvider).debtsDao.watchAll(),
);
