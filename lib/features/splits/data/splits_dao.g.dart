// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splits_dao.dart';

// ignore_for_file: type=lint
mixin _$SplitsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WalletsTable get wallets => attachedDatabase.wallets;
  $CategoriesTable get categories => attachedDatabase.categories;
  $SplitsTable get splits => attachedDatabase.splits;
  $DebtsTable get debts => attachedDatabase.debts;
  $SplitMembersTable get splitMembers => attachedDatabase.splitMembers;
  $SplitItemsTable get splitItems => attachedDatabase.splitItems;
  $DebtPaymentsTable get debtPayments => attachedDatabase.debtPayments;
  $BillsTable get bills => attachedDatabase.bills;
  $RecurringTxsTable get recurringTxs => attachedDatabase.recurringTxs;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  SplitsDaoManager get managers => SplitsDaoManager(this);
}

class SplitsDaoManager {
  final _$SplitsDaoMixin _db;
  SplitsDaoManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db.attachedDatabase, _db.wallets);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$SplitsTableTableManager get splits =>
      $$SplitsTableTableManager(_db.attachedDatabase, _db.splits);
  $$DebtsTableTableManager get debts =>
      $$DebtsTableTableManager(_db.attachedDatabase, _db.debts);
  $$SplitMembersTableTableManager get splitMembers =>
      $$SplitMembersTableTableManager(_db.attachedDatabase, _db.splitMembers);
  $$SplitItemsTableTableManager get splitItems =>
      $$SplitItemsTableTableManager(_db.attachedDatabase, _db.splitItems);
  $$DebtPaymentsTableTableManager get debtPayments =>
      $$DebtPaymentsTableTableManager(_db.attachedDatabase, _db.debtPayments);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db.attachedDatabase, _db.bills);
  $$RecurringTxsTableTableManager get recurringTxs =>
      $$RecurringTxsTableTableManager(_db.attachedDatabase, _db.recurringTxs);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
