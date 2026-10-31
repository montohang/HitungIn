// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets with TableInfo<$WalletsTable, Wallet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<WalletType, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<WalletType>($WalletsTable.$convertertype);
  static const VerificationMeta _initialBalanceMeta =
      const VerificationMeta('initialBalance');
  @override
  late final GeneratedColumn<int> initialBalance = GeneratedColumn<int>(
      'initial_balance', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('wallet'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        initialBalance,
        icon,
        color,
        sortOrder,
        archived,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(Insertable<Wallet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
          _initialBalanceMeta,
          initialBalance.isAcceptableOrUnknown(
              data['initial_balance']!, _initialBalanceMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Wallet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wallet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $WalletsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      initialBalance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}initial_balance'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WalletType, String, String> $convertertype =
      const EnumNameConverter<WalletType>(WalletType.values);
}

class Wallet extends DataClass implements Insertable<Wallet> {
  final int id;
  final String name;
  final WalletType type;

  /// Saldo saat dompet dibuat. Saldo berjalan = ini + mutasi transaksi.
  final int initialBalance;

  /// Kunci ikon (lihat `AppIcons`), bukan IconData, supaya lapisan data
  /// tidak bergantung pada Flutter.
  final String icon;

  /// Indeks warna di `AppPalette` (v4).
  final int color;
  final int sortOrder;
  final bool archived;
  final DateTime createdAt;
  const Wallet(
      {required this.id,
      required this.name,
      required this.type,
      required this.initialBalance,
      required this.icon,
      required this.color,
      required this.sortOrder,
      required this.archived,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($WalletsTable.$convertertype.toSql(type));
    }
    map['initial_balance'] = Variable<int>(initialBalance);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<int>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      initialBalance: Value(initialBalance),
      icon: Value(icon),
      color: Value(color),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wallet(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $WalletsTable.$convertertype
          .fromJson(serializer.fromJson<String>(json['type'])),
      initialBalance: serializer.fromJson<int>(json['initialBalance']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<int>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type':
          serializer.toJson<String>($WalletsTable.$convertertype.toJson(type)),
      'initialBalance': serializer.toJson<int>(initialBalance),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<int>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Wallet copyWith(
          {int? id,
          String? name,
          WalletType? type,
          int? initialBalance,
          String? icon,
          int? color,
          int? sortOrder,
          bool? archived,
          DateTime? createdAt}) =>
      Wallet(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalance: initialBalance ?? this.initialBalance,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
        archived: archived ?? this.archived,
        createdAt: createdAt ?? this.createdAt,
      );
  Wallet copyWithCompanion(WalletsCompanion data) {
    return Wallet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wallet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, initialBalance, icon, color,
      sortOrder, archived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wallet &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.initialBalance == this.initialBalance &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class WalletsCompanion extends UpdateCompanion<Wallet> {
  final Value<int> id;
  final Value<String> name;
  final Value<WalletType> type;
  final Value<int> initialBalance;
  final Value<String> icon;
  final Value<int> color;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WalletsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required WalletType type,
    this.initialBalance = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<Wallet> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? initialBalance,
    Expression<String>? icon,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WalletsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<WalletType>? type,
      Value<int>? initialBalance,
      Value<String>? icon,
      Value<int>? color,
      Value<int>? sortOrder,
      Value<bool>? archived,
      Value<DateTime>? createdAt}) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($WalletsTable.$convertertype.toSql(type.value));
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<int>(initialBalance.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<TxKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TxKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('other'));
  static const VerificationMeta _keywordsMeta =
      const VerificationMeta('keywords');
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
      'keywords', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _subsMeta = const VerificationMeta('subs');
  @override
  late final GeneratedColumn<String> subs = GeneratedColumn<String>(
      'subs', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, kind, icon, keywords, color, subs, sortOrder, archived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('keywords')) {
      context.handle(_keywordsMeta,
          keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('subs')) {
      context.handle(
          _subsMeta, subs.isAcceptableOrUnknown(data['subs']!, _subsMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $CategoriesTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      keywords: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}keywords'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      subs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subs'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxKind, String, String> $converterkind =
      const EnumNameConverter<TxKind>(TxKind.values);
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;

  /// Hanya [TxKind.pengeluaran] atau [TxKind.pemasukan].
  final TxKind kind;
  final String icon;

  /// Kata kunci untuk Catat Cepat, dipisah koma: `kopi,makan,nasi`.
  final String keywords;

  /// Indeks warna di `AppPalette` (v4).
  final int color;

  /// Sub-kategori, dipisah koma: `Kopi,Makan siang,Jajan` (v4). Juga dikenali Catat cepat.
  final String subs;
  final int sortOrder;
  final bool archived;
  const Category(
      {required this.id,
      required this.name,
      required this.kind,
      required this.icon,
      required this.keywords,
      required this.color,
      required this.subs,
      required this.sortOrder,
      required this.archived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] =
          Variable<String>($CategoriesTable.$converterkind.toSql(kind));
    }
    map['icon'] = Variable<String>(icon);
    map['keywords'] = Variable<String>(keywords);
    map['color'] = Variable<int>(color);
    map['subs'] = Variable<String>(subs);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      icon: Value(icon),
      keywords: Value(keywords),
      color: Value(color),
      subs: Value(subs),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $CategoriesTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      icon: serializer.fromJson<String>(json['icon']),
      keywords: serializer.fromJson<String>(json['keywords']),
      color: serializer.fromJson<int>(json['color']),
      subs: serializer.fromJson<String>(json['subs']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer
          .toJson<String>($CategoriesTable.$converterkind.toJson(kind)),
      'icon': serializer.toJson<String>(icon),
      'keywords': serializer.toJson<String>(keywords),
      'color': serializer.toJson<int>(color),
      'subs': serializer.toJson<String>(subs),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Category copyWith(
          {int? id,
          String? name,
          TxKind? kind,
          String? icon,
          String? keywords,
          int? color,
          String? subs,
          int? sortOrder,
          bool? archived}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        icon: icon ?? this.icon,
        keywords: keywords ?? this.keywords,
        color: color ?? this.color,
        subs: subs ?? this.subs,
        sortOrder: sortOrder ?? this.sortOrder,
        archived: archived ?? this.archived,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      icon: data.icon.present ? data.icon.value : this.icon,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      color: data.color.present ? data.color.value : this.color,
      subs: data.subs.present ? data.subs.value : this.subs,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('keywords: $keywords, ')
          ..write('color: $color, ')
          ..write('subs: $subs, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, kind, icon, keywords, color, subs, sortOrder, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.icon == this.icon &&
          other.keywords == this.keywords &&
          other.color == this.color &&
          other.subs == this.subs &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<TxKind> kind;
  final Value<String> icon;
  final Value<String> keywords;
  final Value<int> color;
  final Value<String> subs;
  final Value<int> sortOrder;
  final Value<bool> archived;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.icon = const Value.absent(),
    this.keywords = const Value.absent(),
    this.color = const Value.absent(),
    this.subs = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required TxKind kind,
    this.icon = const Value.absent(),
    this.keywords = const Value.absent(),
    this.color = const Value.absent(),
    this.subs = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  })  : name = Value(name),
        kind = Value(kind);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? icon,
    Expression<String>? keywords,
    Expression<int>? color,
    Expression<String>? subs,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (icon != null) 'icon': icon,
      if (keywords != null) 'keywords': keywords,
      if (color != null) 'color': color,
      if (subs != null) 'subs': subs,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<TxKind>? kind,
      Value<String>? icon,
      Value<String>? keywords,
      Value<int>? color,
      Value<String>? subs,
      Value<int>? sortOrder,
      Value<bool>? archived}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      icon: icon ?? this.icon,
      keywords: keywords ?? this.keywords,
      color: color ?? this.color,
      subs: subs ?? this.subs,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($CategoriesTable.$converterkind.toSql(kind.value));
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (subs.present) {
      map['subs'] = Variable<String>(subs.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('icon: $icon, ')
          ..write('keywords: $keywords, ')
          ..write('color: $color, ')
          ..write('subs: $subs, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => ComparableExpr(amount).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES wallets (id) ON DELETE SET NULL'));
  static const VerificationMeta _nextDueMeta =
      const VerificationMeta('nextDue');
  @override
  late final GeneratedColumn<DateTime> nextDue = GeneratedColumn<DateTime>(
      'next_due', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<BillRepeat, String> repeat =
      GeneratedColumn<String>('repeat', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<BillRepeat>($BillsTable.$converterrepeat);
  static const VerificationMeta _anchorDayMeta =
      const VerificationMeta('anchorDay');
  @override
  late final GeneratedColumn<int> anchorDay = GeneratedColumn<int>(
      'anchor_day', aliasedName, false,
      check: () => ComparableExpr(anchorDay).isBetweenValues(1, 31),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _remindDaysBeforeMeta =
      const VerificationMeta('remindDaysBefore');
  @override
  late final GeneratedColumn<int> remindDaysBefore = GeneratedColumn<int>(
      'remind_days_before', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _installmentTotalMeta =
      const VerificationMeta('installmentTotal');
  @override
  late final GeneratedColumn<int> installmentTotal = GeneratedColumn<int>(
      'installment_total', aliasedName, true,
      check: () => ComparableExpr(installmentTotal).isBetweenValues(2, 60),
      type: DriftSqlType.int,
      requiredDuringInsert: false);
  static const VerificationMeta _installmentPaidMeta =
      const VerificationMeta('installmentPaid');
  @override
  late final GeneratedColumn<int> installmentPaid = GeneratedColumn<int>(
      'installment_paid', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        amount,
        categoryId,
        walletId,
        nextDue,
        repeat,
        anchorDay,
        remindDaysBefore,
        active,
        installmentTotal,
        installmentPaid,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(Insertable<Bill> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    }
    if (data.containsKey('next_due')) {
      context.handle(_nextDueMeta,
          nextDue.isAcceptableOrUnknown(data['next_due']!, _nextDueMeta));
    } else if (isInserting) {
      context.missing(_nextDueMeta);
    }
    if (data.containsKey('anchor_day')) {
      context.handle(_anchorDayMeta,
          anchorDay.isAcceptableOrUnknown(data['anchor_day']!, _anchorDayMeta));
    } else if (isInserting) {
      context.missing(_anchorDayMeta);
    }
    if (data.containsKey('remind_days_before')) {
      context.handle(
          _remindDaysBeforeMeta,
          remindDaysBefore.isAcceptableOrUnknown(
              data['remind_days_before']!, _remindDaysBeforeMeta));
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('installment_total')) {
      context.handle(
          _installmentTotalMeta,
          installmentTotal.isAcceptableOrUnknown(
              data['installment_total']!, _installmentTotalMeta));
    }
    if (data.containsKey('installment_paid')) {
      context.handle(
          _installmentPaidMeta,
          installmentPaid.isAcceptableOrUnknown(
              data['installment_paid']!, _installmentPaidMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id']),
      nextDue: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_due'])!,
      repeat: $BillsTable.$converterrepeat.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat'])!),
      anchorDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}anchor_day'])!,
      remindDaysBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}remind_days_before'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      installmentTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}installment_total']),
      installmentPaid: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}installment_paid'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BillRepeat, String, String> $converterrepeat =
      const EnumNameConverter<BillRepeat>(BillRepeat.values);
}

class Bill extends DataClass implements Insertable<Bill> {
  final int id;
  final String name;
  final int amount;
  final int? categoryId;
  final int? walletId;

  /// Jatuh tempo berikutnya (tanggal saja, jam 00.00).
  final DateTime nextDue;
  final BillRepeat repeat;

  /// Tanggal asli jatuh tempo (1–31), supaya tagihan tanggal 31 tidak
  /// bergeser permanen ke 28 setelah melewati Februari.
  final int anchorDay;
  final int remindDaysBefore;
  final bool active;

  /// Cicilan (v5): jumlah cicilan (tenor, 2–60); kosong = tagihan biasa.
  final int? installmentTotal;

  /// Cicilan yang sudah dibayar. Saat sama dengan tenor, tagihan selesai.
  final int installmentPaid;
  final DateTime createdAt;
  const Bill(
      {required this.id,
      required this.name,
      required this.amount,
      this.categoryId,
      this.walletId,
      required this.nextDue,
      required this.repeat,
      required this.anchorDay,
      required this.remindDaysBefore,
      required this.active,
      this.installmentTotal,
      required this.installmentPaid,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<int>(walletId);
    }
    map['next_due'] = Variable<DateTime>(nextDue);
    {
      map['repeat'] =
          Variable<String>($BillsTable.$converterrepeat.toSql(repeat));
    }
    map['anchor_day'] = Variable<int>(anchorDay);
    map['remind_days_before'] = Variable<int>(remindDaysBefore);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || installmentTotal != null) {
      map['installment_total'] = Variable<int>(installmentTotal);
    }
    map['installment_paid'] = Variable<int>(installmentPaid);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      nextDue: Value(nextDue),
      repeat: Value(repeat),
      anchorDay: Value(anchorDay),
      remindDaysBefore: Value(remindDaysBefore),
      active: Value(active),
      installmentTotal: installmentTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentTotal),
      installmentPaid: Value(installmentPaid),
      createdAt: Value(createdAt),
    );
  }

  factory Bill.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      walletId: serializer.fromJson<int?>(json['walletId']),
      nextDue: serializer.fromJson<DateTime>(json['nextDue']),
      repeat: $BillsTable.$converterrepeat
          .fromJson(serializer.fromJson<String>(json['repeat'])),
      anchorDay: serializer.fromJson<int>(json['anchorDay']),
      remindDaysBefore: serializer.fromJson<int>(json['remindDaysBefore']),
      active: serializer.fromJson<bool>(json['active']),
      installmentTotal: serializer.fromJson<int?>(json['installmentTotal']),
      installmentPaid: serializer.fromJson<int>(json['installmentPaid']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'categoryId': serializer.toJson<int?>(categoryId),
      'walletId': serializer.toJson<int?>(walletId),
      'nextDue': serializer.toJson<DateTime>(nextDue),
      'repeat': serializer
          .toJson<String>($BillsTable.$converterrepeat.toJson(repeat)),
      'anchorDay': serializer.toJson<int>(anchorDay),
      'remindDaysBefore': serializer.toJson<int>(remindDaysBefore),
      'active': serializer.toJson<bool>(active),
      'installmentTotal': serializer.toJson<int?>(installmentTotal),
      'installmentPaid': serializer.toJson<int>(installmentPaid),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bill copyWith(
          {int? id,
          String? name,
          int? amount,
          Value<int?> categoryId = const Value.absent(),
          Value<int?> walletId = const Value.absent(),
          DateTime? nextDue,
          BillRepeat? repeat,
          int? anchorDay,
          int? remindDaysBefore,
          bool? active,
          Value<int?> installmentTotal = const Value.absent(),
          int? installmentPaid,
          DateTime? createdAt}) =>
      Bill(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        walletId: walletId.present ? walletId.value : this.walletId,
        nextDue: nextDue ?? this.nextDue,
        repeat: repeat ?? this.repeat,
        anchorDay: anchorDay ?? this.anchorDay,
        remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
        active: active ?? this.active,
        installmentTotal: installmentTotal.present
            ? installmentTotal.value
            : this.installmentTotal,
        installmentPaid: installmentPaid ?? this.installmentPaid,
        createdAt: createdAt ?? this.createdAt,
      );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
      anchorDay: data.anchorDay.present ? data.anchorDay.value : this.anchorDay,
      remindDaysBefore: data.remindDaysBefore.present
          ? data.remindDaysBefore.value
          : this.remindDaysBefore,
      active: data.active.present ? data.active.value : this.active,
      installmentTotal: data.installmentTotal.present
          ? data.installmentTotal.value
          : this.installmentTotal,
      installmentPaid: data.installmentPaid.present
          ? data.installmentPaid.value
          : this.installmentPaid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('walletId: $walletId, ')
          ..write('nextDue: $nextDue, ')
          ..write('repeat: $repeat, ')
          ..write('anchorDay: $anchorDay, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('active: $active, ')
          ..write('installmentTotal: $installmentTotal, ')
          ..write('installmentPaid: $installmentPaid, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      amount,
      categoryId,
      walletId,
      nextDue,
      repeat,
      anchorDay,
      remindDaysBefore,
      active,
      installmentTotal,
      installmentPaid,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.categoryId == this.categoryId &&
          other.walletId == this.walletId &&
          other.nextDue == this.nextDue &&
          other.repeat == this.repeat &&
          other.anchorDay == this.anchorDay &&
          other.remindDaysBefore == this.remindDaysBefore &&
          other.active == this.active &&
          other.installmentTotal == this.installmentTotal &&
          other.installmentPaid == this.installmentPaid &&
          other.createdAt == this.createdAt);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> amount;
  final Value<int?> categoryId;
  final Value<int?> walletId;
  final Value<DateTime> nextDue;
  final Value<BillRepeat> repeat;
  final Value<int> anchorDay;
  final Value<int> remindDaysBefore;
  final Value<bool> active;
  final Value<int?> installmentTotal;
  final Value<int> installmentPaid;
  final Value<DateTime> createdAt;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.walletId = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.repeat = const Value.absent(),
    this.anchorDay = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.active = const Value.absent(),
    this.installmentTotal = const Value.absent(),
    this.installmentPaid = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BillsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int amount,
    this.categoryId = const Value.absent(),
    this.walletId = const Value.absent(),
    required DateTime nextDue,
    required BillRepeat repeat,
    required int anchorDay,
    this.remindDaysBefore = const Value.absent(),
    this.active = const Value.absent(),
    this.installmentTotal = const Value.absent(),
    this.installmentPaid = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        amount = Value(amount),
        nextDue = Value(nextDue),
        repeat = Value(repeat),
        anchorDay = Value(anchorDay);
  static Insertable<Bill> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<int>? categoryId,
    Expression<int>? walletId,
    Expression<DateTime>? nextDue,
    Expression<String>? repeat,
    Expression<int>? anchorDay,
    Expression<int>? remindDaysBefore,
    Expression<bool>? active,
    Expression<int>? installmentTotal,
    Expression<int>? installmentPaid,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (walletId != null) 'wallet_id': walletId,
      if (nextDue != null) 'next_due': nextDue,
      if (repeat != null) 'repeat': repeat,
      if (anchorDay != null) 'anchor_day': anchorDay,
      if (remindDaysBefore != null) 'remind_days_before': remindDaysBefore,
      if (active != null) 'active': active,
      if (installmentTotal != null) 'installment_total': installmentTotal,
      if (installmentPaid != null) 'installment_paid': installmentPaid,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BillsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? amount,
      Value<int?>? categoryId,
      Value<int?>? walletId,
      Value<DateTime>? nextDue,
      Value<BillRepeat>? repeat,
      Value<int>? anchorDay,
      Value<int>? remindDaysBefore,
      Value<bool>? active,
      Value<int?>? installmentTotal,
      Value<int>? installmentPaid,
      Value<DateTime>? createdAt}) {
    return BillsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      nextDue: nextDue ?? this.nextDue,
      repeat: repeat ?? this.repeat,
      anchorDay: anchorDay ?? this.anchorDay,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      active: active ?? this.active,
      installmentTotal: installmentTotal ?? this.installmentTotal,
      installmentPaid: installmentPaid ?? this.installmentPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<DateTime>(nextDue.value);
    }
    if (repeat.present) {
      map['repeat'] =
          Variable<String>($BillsTable.$converterrepeat.toSql(repeat.value));
    }
    if (anchorDay.present) {
      map['anchor_day'] = Variable<int>(anchorDay.value);
    }
    if (remindDaysBefore.present) {
      map['remind_days_before'] = Variable<int>(remindDaysBefore.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (installmentTotal.present) {
      map['installment_total'] = Variable<int>(installmentTotal.value);
    }
    if (installmentPaid.present) {
      map['installment_paid'] = Variable<int>(installmentPaid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('categoryId: $categoryId, ')
          ..write('walletId: $walletId, ')
          ..write('nextDue: $nextDue, ')
          ..write('repeat: $repeat, ')
          ..write('anchorDay: $anchorDay, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('active: $active, ')
          ..write('installmentTotal: $installmentTotal, ')
          ..write('installmentPaid: $installmentPaid, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $RecurringTxsTable extends RecurringTxs
    with TableInfo<$RecurringTxsTable, RecurringTx> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTxsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<TxKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TxKind>($RecurringTxsTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => ComparableExpr(amount).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (id)'));
  static const VerificationMeta _toWalletIdMeta =
      const VerificationMeta('toWalletId');
  @override
  late final GeneratedColumn<int> toWalletId = GeneratedColumn<int>(
      'to_wallet_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<BillRepeat, String> repeat =
      GeneratedColumn<String>('repeat', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<BillRepeat>($RecurringTxsTable.$converterrepeat);
  static const VerificationMeta _anchorDayMeta =
      const VerificationMeta('anchorDay');
  @override
  late final GeneratedColumn<int> anchorDay = GeneratedColumn<int>(
      'anchor_day', aliasedName, false,
      check: () => ComparableExpr(anchorDay).isBetweenValues(1, 31),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _nextRunMeta =
      const VerificationMeta('nextRun');
  @override
  late final GeneratedColumn<DateTime> nextRun = GeneratedColumn<DateTime>(
      'next_run', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
      'active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        amount,
        walletId,
        toWalletId,
        categoryId,
        note,
        repeat,
        anchorDay,
        nextRun,
        active,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_txs';
  @override
  VerificationContext validateIntegrity(Insertable<RecurringTx> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('to_wallet_id')) {
      context.handle(
          _toWalletIdMeta,
          toWalletId.isAcceptableOrUnknown(
              data['to_wallet_id']!, _toWalletIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('anchor_day')) {
      context.handle(_anchorDayMeta,
          anchorDay.isAcceptableOrUnknown(data['anchor_day']!, _anchorDayMeta));
    } else if (isInserting) {
      context.missing(_anchorDayMeta);
    }
    if (data.containsKey('next_run')) {
      context.handle(_nextRunMeta,
          nextRun.isAcceptableOrUnknown(data['next_run']!, _nextRunMeta));
    } else if (isInserting) {
      context.missing(_nextRunMeta);
    }
    if (data.containsKey('active')) {
      context.handle(_activeMeta,
          active.isAcceptableOrUnknown(data['active']!, _activeMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTx map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTx(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: $RecurringTxsTable.$converterkind.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id'])!,
      toWalletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_wallet_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      repeat: $RecurringTxsTable.$converterrepeat.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat'])!),
      anchorDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}anchor_day'])!,
      nextRun: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_run'])!,
      active: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RecurringTxsTable createAlias(String alias) {
    return $RecurringTxsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxKind, String, String> $converterkind =
      const EnumNameConverter<TxKind>(TxKind.values);
  static JsonTypeConverter2<BillRepeat, String, String> $converterrepeat =
      const EnumNameConverter<BillRepeat>(BillRepeat.values);
}

class RecurringTx extends DataClass implements Insertable<RecurringTx> {
  final int id;
  final TxKind kind;
  final int amount;
  final int walletId;
  final int? toWalletId;
  final int? categoryId;
  final String note;

  /// Hanya mingguan/bulanan/tahunan (bukan [BillRepeat.sekali]).
  final BillRepeat repeat;
  final int anchorDay;

  /// Tanggal pencatatan berikutnya (00.00).
  final DateTime nextRun;
  final bool active;
  final DateTime createdAt;
  const RecurringTx(
      {required this.id,
      required this.kind,
      required this.amount,
      required this.walletId,
      this.toWalletId,
      this.categoryId,
      required this.note,
      required this.repeat,
      required this.anchorDay,
      required this.nextRun,
      required this.active,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] =
          Variable<String>($RecurringTxsTable.$converterkind.toSql(kind));
    }
    map['amount'] = Variable<int>(amount);
    map['wallet_id'] = Variable<int>(walletId);
    if (!nullToAbsent || toWalletId != null) {
      map['to_wallet_id'] = Variable<int>(toWalletId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['note'] = Variable<String>(note);
    {
      map['repeat'] =
          Variable<String>($RecurringTxsTable.$converterrepeat.toSql(repeat));
    }
    map['anchor_day'] = Variable<int>(anchorDay);
    map['next_run'] = Variable<DateTime>(nextRun);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RecurringTxsCompanion toCompanion(bool nullToAbsent) {
    return RecurringTxsCompanion(
      id: Value(id),
      kind: Value(kind),
      amount: Value(amount),
      walletId: Value(walletId),
      toWalletId: toWalletId == null && nullToAbsent
          ? const Value.absent()
          : Value(toWalletId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      note: Value(note),
      repeat: Value(repeat),
      anchorDay: Value(anchorDay),
      nextRun: Value(nextRun),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringTx.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTx(
      id: serializer.fromJson<int>(json['id']),
      kind: $RecurringTxsTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      amount: serializer.fromJson<int>(json['amount']),
      walletId: serializer.fromJson<int>(json['walletId']),
      toWalletId: serializer.fromJson<int?>(json['toWalletId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      note: serializer.fromJson<String>(json['note']),
      repeat: $RecurringTxsTable.$converterrepeat
          .fromJson(serializer.fromJson<String>(json['repeat'])),
      anchorDay: serializer.fromJson<int>(json['anchorDay']),
      nextRun: serializer.fromJson<DateTime>(json['nextRun']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer
          .toJson<String>($RecurringTxsTable.$converterkind.toJson(kind)),
      'amount': serializer.toJson<int>(amount),
      'walletId': serializer.toJson<int>(walletId),
      'toWalletId': serializer.toJson<int?>(toWalletId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'note': serializer.toJson<String>(note),
      'repeat': serializer
          .toJson<String>($RecurringTxsTable.$converterrepeat.toJson(repeat)),
      'anchorDay': serializer.toJson<int>(anchorDay),
      'nextRun': serializer.toJson<DateTime>(nextRun),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringTx copyWith(
          {int? id,
          TxKind? kind,
          int? amount,
          int? walletId,
          Value<int?> toWalletId = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          String? note,
          BillRepeat? repeat,
          int? anchorDay,
          DateTime? nextRun,
          bool? active,
          DateTime? createdAt}) =>
      RecurringTx(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
        walletId: walletId ?? this.walletId,
        toWalletId: toWalletId.present ? toWalletId.value : this.toWalletId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        note: note ?? this.note,
        repeat: repeat ?? this.repeat,
        anchorDay: anchorDay ?? this.anchorDay,
        nextRun: nextRun ?? this.nextRun,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
      );
  RecurringTx copyWithCompanion(RecurringTxsCompanion data) {
    return RecurringTx(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      toWalletId:
          data.toWalletId.present ? data.toWalletId.value : this.toWalletId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      repeat: data.repeat.present ? data.repeat.value : this.repeat,
      anchorDay: data.anchorDay.present ? data.anchorDay.value : this.anchorDay,
      nextRun: data.nextRun.present ? data.nextRun.value : this.nextRun,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTx(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('toWalletId: $toWalletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('repeat: $repeat, ')
          ..write('anchorDay: $anchorDay, ')
          ..write('nextRun: $nextRun, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, amount, walletId, toWalletId,
      categoryId, note, repeat, anchorDay, nextRun, active, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTx &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.walletId == this.walletId &&
          other.toWalletId == this.toWalletId &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.repeat == this.repeat &&
          other.anchorDay == this.anchorDay &&
          other.nextRun == this.nextRun &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class RecurringTxsCompanion extends UpdateCompanion<RecurringTx> {
  final Value<int> id;
  final Value<TxKind> kind;
  final Value<int> amount;
  final Value<int> walletId;
  final Value<int?> toWalletId;
  final Value<int?> categoryId;
  final Value<String> note;
  final Value<BillRepeat> repeat;
  final Value<int> anchorDay;
  final Value<DateTime> nextRun;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const RecurringTxsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.toWalletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.repeat = const Value.absent(),
    this.anchorDay = const Value.absent(),
    this.nextRun = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RecurringTxsCompanion.insert({
    this.id = const Value.absent(),
    required TxKind kind,
    required int amount,
    required int walletId,
    this.toWalletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    required BillRepeat repeat,
    required int anchorDay,
    required DateTime nextRun,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : kind = Value(kind),
        amount = Value(amount),
        walletId = Value(walletId),
        repeat = Value(repeat),
        anchorDay = Value(anchorDay),
        nextRun = Value(nextRun);
  static Insertable<RecurringTx> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<int>? walletId,
    Expression<int>? toWalletId,
    Expression<int>? categoryId,
    Expression<String>? note,
    Expression<String>? repeat,
    Expression<int>? anchorDay,
    Expression<DateTime>? nextRun,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (walletId != null) 'wallet_id': walletId,
      if (toWalletId != null) 'to_wallet_id': toWalletId,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (repeat != null) 'repeat': repeat,
      if (anchorDay != null) 'anchor_day': anchorDay,
      if (nextRun != null) 'next_run': nextRun,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RecurringTxsCompanion copyWith(
      {Value<int>? id,
      Value<TxKind>? kind,
      Value<int>? amount,
      Value<int>? walletId,
      Value<int?>? toWalletId,
      Value<int?>? categoryId,
      Value<String>? note,
      Value<BillRepeat>? repeat,
      Value<int>? anchorDay,
      Value<DateTime>? nextRun,
      Value<bool>? active,
      Value<DateTime>? createdAt}) {
    return RecurringTxsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      repeat: repeat ?? this.repeat,
      anchorDay: anchorDay ?? this.anchorDay,
      nextRun: nextRun ?? this.nextRun,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($RecurringTxsTable.$converterkind.toSql(kind.value));
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (toWalletId.present) {
      map['to_wallet_id'] = Variable<int>(toWalletId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (repeat.present) {
      map['repeat'] = Variable<String>(
          $RecurringTxsTable.$converterrepeat.toSql(repeat.value));
    }
    if (anchorDay.present) {
      map['anchor_day'] = Variable<int>(anchorDay.value);
    }
    if (nextRun.present) {
      map['next_run'] = Variable<DateTime>(nextRun.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTxsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('toWalletId: $toWalletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('repeat: $repeat, ')
          ..write('anchorDay: $anchorDay, ')
          ..write('nextRun: $nextRun, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SplitsTable extends Splits with TableInfo<$SplitsTable, Split> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SplitMode, String> mode =
      GeneratedColumn<String>('mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<SplitMode>($SplitsTable.$convertermode);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
      'total', aliasedName, false,
      check: () => ComparableExpr(total).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _taxPermilleMeta =
      const VerificationMeta('taxPermille');
  @override
  late final GeneratedColumn<int> taxPermille = GeneratedColumn<int>(
      'tax_permille', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _servicePermilleMeta =
      const VerificationMeta('servicePermille');
  @override
  late final GeneratedColumn<int> servicePermille = GeneratedColumn<int>(
      'service_permille', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _extraFeeMeta =
      const VerificationMeta('extraFee');
  @override
  late final GeneratedColumn<int> extraFee = GeneratedColumn<int>(
      'extra_fee', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<int> discount = GeneratedColumn<int>(
      'discount', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        mode,
        total,
        walletId,
        categoryId,
        taxPermille,
        servicePermille,
        extraFee,
        discount,
        occurredAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'splits';
  @override
  VerificationContext validateIntegrity(Insertable<Split> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('tax_permille')) {
      context.handle(
          _taxPermilleMeta,
          taxPermille.isAcceptableOrUnknown(
              data['tax_permille']!, _taxPermilleMeta));
    }
    if (data.containsKey('service_permille')) {
      context.handle(
          _servicePermilleMeta,
          servicePermille.isAcceptableOrUnknown(
              data['service_permille']!, _servicePermilleMeta));
    }
    if (data.containsKey('extra_fee')) {
      context.handle(_extraFeeMeta,
          extraFee.isAcceptableOrUnknown(data['extra_fee']!, _extraFeeMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Split map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Split(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      mode: $SplitsTable.$convertermode.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!),
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total'])!,
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      taxPermille: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tax_permille'])!,
      servicePermille: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}service_permille'])!,
      extraFee: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}extra_fee'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}discount'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SplitsTable createAlias(String alias) {
    return $SplitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SplitMode, String, String> $convertermode =
      const EnumNameConverter<SplitMode>(SplitMode.values);
}

class Split extends DataClass implements Insertable<Split> {
  final int id;
  final String title;
  final SplitMode mode;
  final int total;

  /// Dompet yang dipakai: membayar (aku yang bayar) atau tempat utangku dicatat.
  final int walletId;
  final int? categoryId;

  /// Per menu: pajak & service dalam persen ×10 (100 = 10%), ongkir, diskon.
  final int taxPermille;
  final int servicePermille;
  final int extraFee;
  final int discount;
  final DateTime occurredAt;
  final DateTime createdAt;
  const Split(
      {required this.id,
      required this.title,
      required this.mode,
      required this.total,
      required this.walletId,
      this.categoryId,
      required this.taxPermille,
      required this.servicePermille,
      required this.extraFee,
      required this.discount,
      required this.occurredAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    {
      map['mode'] = Variable<String>($SplitsTable.$convertermode.toSql(mode));
    }
    map['total'] = Variable<int>(total);
    map['wallet_id'] = Variable<int>(walletId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['tax_permille'] = Variable<int>(taxPermille);
    map['service_permille'] = Variable<int>(servicePermille);
    map['extra_fee'] = Variable<int>(extraFee);
    map['discount'] = Variable<int>(discount);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SplitsCompanion toCompanion(bool nullToAbsent) {
    return SplitsCompanion(
      id: Value(id),
      title: Value(title),
      mode: Value(mode),
      total: Value(total),
      walletId: Value(walletId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      taxPermille: Value(taxPermille),
      servicePermille: Value(servicePermille),
      extraFee: Value(extraFee),
      discount: Value(discount),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
    );
  }

  factory Split.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Split(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      mode: $SplitsTable.$convertermode
          .fromJson(serializer.fromJson<String>(json['mode'])),
      total: serializer.fromJson<int>(json['total']),
      walletId: serializer.fromJson<int>(json['walletId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      taxPermille: serializer.fromJson<int>(json['taxPermille']),
      servicePermille: serializer.fromJson<int>(json['servicePermille']),
      extraFee: serializer.fromJson<int>(json['extraFee']),
      discount: serializer.fromJson<int>(json['discount']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'mode':
          serializer.toJson<String>($SplitsTable.$convertermode.toJson(mode)),
      'total': serializer.toJson<int>(total),
      'walletId': serializer.toJson<int>(walletId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'taxPermille': serializer.toJson<int>(taxPermille),
      'servicePermille': serializer.toJson<int>(servicePermille),
      'extraFee': serializer.toJson<int>(extraFee),
      'discount': serializer.toJson<int>(discount),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Split copyWith(
          {int? id,
          String? title,
          SplitMode? mode,
          int? total,
          int? walletId,
          Value<int?> categoryId = const Value.absent(),
          int? taxPermille,
          int? servicePermille,
          int? extraFee,
          int? discount,
          DateTime? occurredAt,
          DateTime? createdAt}) =>
      Split(
        id: id ?? this.id,
        title: title ?? this.title,
        mode: mode ?? this.mode,
        total: total ?? this.total,
        walletId: walletId ?? this.walletId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        taxPermille: taxPermille ?? this.taxPermille,
        servicePermille: servicePermille ?? this.servicePermille,
        extraFee: extraFee ?? this.extraFee,
        discount: discount ?? this.discount,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Split copyWithCompanion(SplitsCompanion data) {
    return Split(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      mode: data.mode.present ? data.mode.value : this.mode,
      total: data.total.present ? data.total.value : this.total,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      taxPermille:
          data.taxPermille.present ? data.taxPermille.value : this.taxPermille,
      servicePermille: data.servicePermille.present
          ? data.servicePermille.value
          : this.servicePermille,
      extraFee: data.extraFee.present ? data.extraFee.value : this.extraFee,
      discount: data.discount.present ? data.discount.value : this.discount,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Split(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mode: $mode, ')
          ..write('total: $total, ')
          ..write('walletId: $walletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('taxPermille: $taxPermille, ')
          ..write('servicePermille: $servicePermille, ')
          ..write('extraFee: $extraFee, ')
          ..write('discount: $discount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, mode, total, walletId, categoryId,
      taxPermille, servicePermille, extraFee, discount, occurredAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Split &&
          other.id == this.id &&
          other.title == this.title &&
          other.mode == this.mode &&
          other.total == this.total &&
          other.walletId == this.walletId &&
          other.categoryId == this.categoryId &&
          other.taxPermille == this.taxPermille &&
          other.servicePermille == this.servicePermille &&
          other.extraFee == this.extraFee &&
          other.discount == this.discount &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt);
}

class SplitsCompanion extends UpdateCompanion<Split> {
  final Value<int> id;
  final Value<String> title;
  final Value<SplitMode> mode;
  final Value<int> total;
  final Value<int> walletId;
  final Value<int?> categoryId;
  final Value<int> taxPermille;
  final Value<int> servicePermille;
  final Value<int> extraFee;
  final Value<int> discount;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  const SplitsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.mode = const Value.absent(),
    this.total = const Value.absent(),
    this.walletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.taxPermille = const Value.absent(),
    this.servicePermille = const Value.absent(),
    this.extraFee = const Value.absent(),
    this.discount = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SplitsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required SplitMode mode,
    required int total,
    required int walletId,
    this.categoryId = const Value.absent(),
    this.taxPermille = const Value.absent(),
    this.servicePermille = const Value.absent(),
    this.extraFee = const Value.absent(),
    this.discount = const Value.absent(),
    required DateTime occurredAt,
    this.createdAt = const Value.absent(),
  })  : title = Value(title),
        mode = Value(mode),
        total = Value(total),
        walletId = Value(walletId),
        occurredAt = Value(occurredAt);
  static Insertable<Split> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? mode,
    Expression<int>? total,
    Expression<int>? walletId,
    Expression<int>? categoryId,
    Expression<int>? taxPermille,
    Expression<int>? servicePermille,
    Expression<int>? extraFee,
    Expression<int>? discount,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (mode != null) 'mode': mode,
      if (total != null) 'total': total,
      if (walletId != null) 'wallet_id': walletId,
      if (categoryId != null) 'category_id': categoryId,
      if (taxPermille != null) 'tax_permille': taxPermille,
      if (servicePermille != null) 'service_permille': servicePermille,
      if (extraFee != null) 'extra_fee': extraFee,
      if (discount != null) 'discount': discount,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SplitsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<SplitMode>? mode,
      Value<int>? total,
      Value<int>? walletId,
      Value<int?>? categoryId,
      Value<int>? taxPermille,
      Value<int>? servicePermille,
      Value<int>? extraFee,
      Value<int>? discount,
      Value<DateTime>? occurredAt,
      Value<DateTime>? createdAt}) {
    return SplitsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      total: total ?? this.total,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      taxPermille: taxPermille ?? this.taxPermille,
      servicePermille: servicePermille ?? this.servicePermille,
      extraFee: extraFee ?? this.extraFee,
      discount: discount ?? this.discount,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mode.present) {
      map['mode'] =
          Variable<String>($SplitsTable.$convertermode.toSql(mode.value));
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (taxPermille.present) {
      map['tax_permille'] = Variable<int>(taxPermille.value);
    }
    if (servicePermille.present) {
      map['service_permille'] = Variable<int>(servicePermille.value);
    }
    if (extraFee.present) {
      map['extra_fee'] = Variable<int>(extraFee.value);
    }
    if (discount.present) {
      map['discount'] = Variable<int>(discount.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mode: $mode, ')
          ..write('total: $total, ')
          ..write('walletId: $walletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('taxPermille: $taxPermille, ')
          ..write('servicePermille: $servicePermille, ')
          ..write('extraFee: $extraFee, ')
          ..write('discount: $discount, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DebtsTable extends Debts with TableInfo<$DebtsTable, Debt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<DebtDirection, String> direction =
      GeneratedColumn<String>('direction', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<DebtDirection>($DebtsTable.$converterdirection);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => ComparableExpr(amount).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES wallets (id) ON DELETE SET NULL'));
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _splitIdMeta =
      const VerificationMeta('splitId');
  @override
  late final GeneratedColumn<int> splitId = GeneratedColumn<int>(
      'split_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES splits (id) ON DELETE CASCADE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        direction,
        name,
        amount,
        walletId,
        occurredAt,
        dueDate,
        note,
        splitId,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(Insertable<Debt> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('split_id')) {
      context.handle(_splitIdMeta,
          splitId.isAcceptableOrUnknown(data['split_id']!, _splitIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Debt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Debt(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      direction: $DebtsTable.$converterdirection.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      splitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DebtsTable createAlias(String alias) {
    return $DebtsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DebtDirection, String, String> $converterdirection =
      const EnumNameConverter<DebtDirection>(DebtDirection.values);
}

class Debt extends DataClass implements Insertable<Debt> {
  final int id;
  final DebtDirection direction;
  final String name;
  final int amount;
  final int? walletId;
  final DateTime occurredAt;

  /// Jatuh tempo (tanggal saja), opsional.
  final DateTime? dueDate;
  final String note;

  /// Patungan asal (v7); ikut terhapus bersama patungannya.
  final int? splitId;
  final DateTime createdAt;
  const Debt(
      {required this.id,
      required this.direction,
      required this.name,
      required this.amount,
      this.walletId,
      required this.occurredAt,
      this.dueDate,
      required this.note,
      this.splitId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['direction'] =
          Variable<String>($DebtsTable.$converterdirection.toSql(direction));
    }
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<int>(walletId);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || splitId != null) {
      map['split_id'] = Variable<int>(splitId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DebtsCompanion toCompanion(bool nullToAbsent) {
    return DebtsCompanion(
      id: Value(id),
      direction: Value(direction),
      name: Value(name),
      amount: Value(amount),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      occurredAt: Value(occurredAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      note: Value(note),
      splitId: splitId == null && nullToAbsent
          ? const Value.absent()
          : Value(splitId),
      createdAt: Value(createdAt),
    );
  }

  factory Debt.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Debt(
      id: serializer.fromJson<int>(json['id']),
      direction: $DebtsTable.$converterdirection
          .fromJson(serializer.fromJson<String>(json['direction'])),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      walletId: serializer.fromJson<int?>(json['walletId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      note: serializer.fromJson<String>(json['note']),
      splitId: serializer.fromJson<int?>(json['splitId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'direction': serializer
          .toJson<String>($DebtsTable.$converterdirection.toJson(direction)),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'walletId': serializer.toJson<int?>(walletId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'note': serializer.toJson<String>(note),
      'splitId': serializer.toJson<int?>(splitId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Debt copyWith(
          {int? id,
          DebtDirection? direction,
          String? name,
          int? amount,
          Value<int?> walletId = const Value.absent(),
          DateTime? occurredAt,
          Value<DateTime?> dueDate = const Value.absent(),
          String? note,
          Value<int?> splitId = const Value.absent(),
          DateTime? createdAt}) =>
      Debt(
        id: id ?? this.id,
        direction: direction ?? this.direction,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        walletId: walletId.present ? walletId.value : this.walletId,
        occurredAt: occurredAt ?? this.occurredAt,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        note: note ?? this.note,
        splitId: splitId.present ? splitId.value : this.splitId,
        createdAt: createdAt ?? this.createdAt,
      );
  Debt copyWithCompanion(DebtsCompanion data) {
    return Debt(
      id: data.id.present ? data.id.value : this.id,
      direction: data.direction.present ? data.direction.value : this.direction,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      note: data.note.present ? data.note.value : this.note,
      splitId: data.splitId.present ? data.splitId.value : this.splitId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Debt(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('splitId: $splitId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, direction, name, amount, walletId,
      occurredAt, dueDate, note, splitId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Debt &&
          other.id == this.id &&
          other.direction == this.direction &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.walletId == this.walletId &&
          other.occurredAt == this.occurredAt &&
          other.dueDate == this.dueDate &&
          other.note == this.note &&
          other.splitId == this.splitId &&
          other.createdAt == this.createdAt);
}

class DebtsCompanion extends UpdateCompanion<Debt> {
  final Value<int> id;
  final Value<DebtDirection> direction;
  final Value<String> name;
  final Value<int> amount;
  final Value<int?> walletId;
  final Value<DateTime> occurredAt;
  final Value<DateTime?> dueDate;
  final Value<String> note;
  final Value<int?> splitId;
  final Value<DateTime> createdAt;
  const DebtsCompanion({
    this.id = const Value.absent(),
    this.direction = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.splitId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DebtsCompanion.insert({
    this.id = const Value.absent(),
    required DebtDirection direction,
    required String name,
    required int amount,
    this.walletId = const Value.absent(),
    required DateTime occurredAt,
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.splitId = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : direction = Value(direction),
        name = Value(name),
        amount = Value(amount),
        occurredAt = Value(occurredAt);
  static Insertable<Debt> custom({
    Expression<int>? id,
    Expression<String>? direction,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<int>? walletId,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? dueDate,
    Expression<String>? note,
    Expression<int>? splitId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (direction != null) 'direction': direction,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (walletId != null) 'wallet_id': walletId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (dueDate != null) 'due_date': dueDate,
      if (note != null) 'note': note,
      if (splitId != null) 'split_id': splitId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DebtsCompanion copyWith(
      {Value<int>? id,
      Value<DebtDirection>? direction,
      Value<String>? name,
      Value<int>? amount,
      Value<int?>? walletId,
      Value<DateTime>? occurredAt,
      Value<DateTime?>? dueDate,
      Value<String>? note,
      Value<int?>? splitId,
      Value<DateTime>? createdAt}) {
    return DebtsCompanion(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      occurredAt: occurredAt ?? this.occurredAt,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      splitId: splitId ?? this.splitId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
          $DebtsTable.$converterdirection.toSql(direction.value));
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (splitId.present) {
      map['split_id'] = Variable<int>(splitId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtsCompanion(')
          ..write('id: $id, ')
          ..write('direction: $direction, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('splitId: $splitId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DebtPaymentsTable extends DebtPayments
    with TableInfo<$DebtPaymentsTable, DebtPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<int> debtId = GeneratedColumn<int>(
      'debt_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES debts (id) ON DELETE CASCADE'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => ComparableExpr(amount).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES wallets (id) ON DELETE SET NULL'));
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
      'paid_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, debtId, amount, walletId, paidAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_payments';
  @override
  VerificationContext validateIntegrity(Insertable<DebtPayment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('debt_id')) {
      context.handle(_debtIdMeta,
          debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta));
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    }
    if (data.containsKey('paid_at')) {
      context.handle(_paidAtMeta,
          paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta));
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtPayment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      debtId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}debt_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id']),
      paidAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}paid_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DebtPaymentsTable createAlias(String alias) {
    return $DebtPaymentsTable(attachedDatabase, alias);
  }
}

class DebtPayment extends DataClass implements Insertable<DebtPayment> {
  final int id;
  final int debtId;
  final int amount;
  final int? walletId;
  final DateTime paidAt;
  final DateTime createdAt;
  const DebtPayment(
      {required this.id,
      required this.debtId,
      required this.amount,
      this.walletId,
      required this.paidAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['debt_id'] = Variable<int>(debtId);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<int>(walletId);
    }
    map['paid_at'] = Variable<DateTime>(paidAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DebtPaymentsCompanion toCompanion(bool nullToAbsent) {
    return DebtPaymentsCompanion(
      id: Value(id),
      debtId: Value(debtId),
      amount: Value(amount),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      paidAt: Value(paidAt),
      createdAt: Value(createdAt),
    );
  }

  factory DebtPayment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtPayment(
      id: serializer.fromJson<int>(json['id']),
      debtId: serializer.fromJson<int>(json['debtId']),
      amount: serializer.fromJson<int>(json['amount']),
      walletId: serializer.fromJson<int?>(json['walletId']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'debtId': serializer.toJson<int>(debtId),
      'amount': serializer.toJson<int>(amount),
      'walletId': serializer.toJson<int?>(walletId),
      'paidAt': serializer.toJson<DateTime>(paidAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DebtPayment copyWith(
          {int? id,
          int? debtId,
          int? amount,
          Value<int?> walletId = const Value.absent(),
          DateTime? paidAt,
          DateTime? createdAt}) =>
      DebtPayment(
        id: id ?? this.id,
        debtId: debtId ?? this.debtId,
        amount: amount ?? this.amount,
        walletId: walletId.present ? walletId.value : this.walletId,
        paidAt: paidAt ?? this.paidAt,
        createdAt: createdAt ?? this.createdAt,
      );
  DebtPayment copyWithCompanion(DebtPaymentsCompanion data) {
    return DebtPayment(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtPayment(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, debtId, amount, walletId, paidAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtPayment &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.amount == this.amount &&
          other.walletId == this.walletId &&
          other.paidAt == this.paidAt &&
          other.createdAt == this.createdAt);
}

class DebtPaymentsCompanion extends UpdateCompanion<DebtPayment> {
  final Value<int> id;
  final Value<int> debtId;
  final Value<int> amount;
  final Value<int?> walletId;
  final Value<DateTime> paidAt;
  final Value<DateTime> createdAt;
  const DebtPaymentsCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DebtPaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int debtId,
    required int amount,
    this.walletId = const Value.absent(),
    required DateTime paidAt,
    this.createdAt = const Value.absent(),
  })  : debtId = Value(debtId),
        amount = Value(amount),
        paidAt = Value(paidAt);
  static Insertable<DebtPayment> custom({
    Expression<int>? id,
    Expression<int>? debtId,
    Expression<int>? amount,
    Expression<int>? walletId,
    Expression<DateTime>? paidAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debt_id': debtId,
      if (amount != null) 'amount': amount,
      if (walletId != null) 'wallet_id': walletId,
      if (paidAt != null) 'paid_at': paidAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DebtPaymentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? debtId,
      Value<int>? amount,
      Value<int?>? walletId,
      Value<DateTime>? paidAt,
      Value<DateTime>? createdAt}) {
    return DebtPaymentsCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<int>(debtId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('paidAt: $paidAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Txn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<TxKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TxKind>($TransactionsTable.$converterkind);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => ComparableExpr(amount).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (id)'));
  static const VerificationMeta _toWalletIdMeta =
      const VerificationMeta('toWalletId');
  @override
  late final GeneratedColumn<int> toWalletId = GeneratedColumn<int>(
      'to_wallet_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES wallets (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _subMeta = const VerificationMeta('sub');
  @override
  late final GeneratedColumn<String> sub = GeneratedColumn<String>(
      'sub', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<int> billId = GeneratedColumn<int>(
      'bill_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES bills (id) ON DELETE SET NULL'));
  static const VerificationMeta _billDueMeta =
      const VerificationMeta('billDue');
  @override
  late final GeneratedColumn<DateTime> billDue = GeneratedColumn<DateTime>(
      'bill_due', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _recurringIdMeta =
      const VerificationMeta('recurringId');
  @override
  late final GeneratedColumn<int> recurringId = GeneratedColumn<int>(
      'recurring_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES recurring_txs (id) ON DELETE SET NULL'));
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<int> debtId = GeneratedColumn<int>(
      'debt_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES debts (id) ON DELETE CASCADE'));
  static const VerificationMeta _debtPaymentIdMeta =
      const VerificationMeta('debtPaymentId');
  @override
  late final GeneratedColumn<int> debtPaymentId = GeneratedColumn<int>(
      'debt_payment_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES debt_payments (id) ON DELETE CASCADE'));
  static const VerificationMeta _splitIdMeta =
      const VerificationMeta('splitId');
  @override
  late final GeneratedColumn<int> splitId = GeneratedColumn<int>(
      'split_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES splits (id) ON DELETE CASCADE'));
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        amount,
        walletId,
        toWalletId,
        categoryId,
        note,
        sub,
        billId,
        billDue,
        recurringId,
        debtId,
        debtPaymentId,
        splitId,
        occurredAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Txn> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('to_wallet_id')) {
      context.handle(
          _toWalletIdMeta,
          toWalletId.isAcceptableOrUnknown(
              data['to_wallet_id']!, _toWalletIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('sub')) {
      context.handle(
          _subMeta, sub.isAcceptableOrUnknown(data['sub']!, _subMeta));
    }
    if (data.containsKey('bill_id')) {
      context.handle(_billIdMeta,
          billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta));
    }
    if (data.containsKey('bill_due')) {
      context.handle(_billDueMeta,
          billDue.isAcceptableOrUnknown(data['bill_due']!, _billDueMeta));
    }
    if (data.containsKey('recurring_id')) {
      context.handle(
          _recurringIdMeta,
          recurringId.isAcceptableOrUnknown(
              data['recurring_id']!, _recurringIdMeta));
    }
    if (data.containsKey('debt_id')) {
      context.handle(_debtIdMeta,
          debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta));
    }
    if (data.containsKey('debt_payment_id')) {
      context.handle(
          _debtPaymentIdMeta,
          debtPaymentId.isAcceptableOrUnknown(
              data['debt_payment_id']!, _debtPaymentIdMeta));
    }
    if (data.containsKey('split_id')) {
      context.handle(_splitIdMeta,
          splitId.isAcceptableOrUnknown(data['split_id']!, _splitIdMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Txn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Txn(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: $TransactionsTable.$converterkind.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id'])!,
      toWalletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_wallet_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      sub: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sub'])!,
      billId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bill_id']),
      billDue: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}bill_due']),
      recurringId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recurring_id']),
      debtId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}debt_id']),
      debtPaymentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}debt_payment_id']),
      splitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_id']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}occurred_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TxKind, String, String> $converterkind =
      const EnumNameConverter<TxKind>(TxKind.values);
}

class Txn extends DataClass implements Insertable<Txn> {
  final int id;
  final TxKind kind;

  /// Selalu positif; arah uang ditentukan oleh [kind].
  final int amount;

  /// Dompet sumber (pengeluaran/transfer) atau tujuan (pemasukan).
  final int walletId;

  /// Dompet tujuan, hanya untuk transfer.
  final int? toWalletId;

  /// Kosong untuk transfer.
  final int? categoryId;
  final String note;

  /// Sub-kategori terpilih (salah satu dari `Categories.subs`), kosong = tidak ada (v4).
  final String sub;

  /// Tagihan asal, bila transaksi dibuat dari "Bayar tagihan".
  final int? billId;

  /// Jatuh tempo tagihan yang dibayar transaksi ini (v8), untuk menilai
  /// ketepatan waktu di Rapor. Kosong untuk pembayaran sebelum v8.
  final DateTime? billDue;

  /// Jadwal asal, bila transaksi dicatat otomatis oleh transaksi berulang (v2).
  final int? recurringId;

  /// Catatan utang-piutang asal (v5). Ikut terhapus bersama catatannya.
  final int? debtId;

  /// Pembayaran utang asal (v5); kosong = transaksi pinjaman awal.
  final int? debtPaymentId;

  /// Patungan asal (v7): pengeluaran sebesar bagianku. Ikut terhapus bersama patungannya.
  final int? splitId;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Txn(
      {required this.id,
      required this.kind,
      required this.amount,
      required this.walletId,
      this.toWalletId,
      this.categoryId,
      required this.note,
      required this.sub,
      this.billId,
      this.billDue,
      this.recurringId,
      this.debtId,
      this.debtPaymentId,
      this.splitId,
      required this.occurredAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] =
          Variable<String>($TransactionsTable.$converterkind.toSql(kind));
    }
    map['amount'] = Variable<int>(amount);
    map['wallet_id'] = Variable<int>(walletId);
    if (!nullToAbsent || toWalletId != null) {
      map['to_wallet_id'] = Variable<int>(toWalletId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['note'] = Variable<String>(note);
    map['sub'] = Variable<String>(sub);
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<int>(billId);
    }
    if (!nullToAbsent || billDue != null) {
      map['bill_due'] = Variable<DateTime>(billDue);
    }
    if (!nullToAbsent || recurringId != null) {
      map['recurring_id'] = Variable<int>(recurringId);
    }
    if (!nullToAbsent || debtId != null) {
      map['debt_id'] = Variable<int>(debtId);
    }
    if (!nullToAbsent || debtPaymentId != null) {
      map['debt_payment_id'] = Variable<int>(debtPaymentId);
    }
    if (!nullToAbsent || splitId != null) {
      map['split_id'] = Variable<int>(splitId);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      amount: Value(amount),
      walletId: Value(walletId),
      toWalletId: toWalletId == null && nullToAbsent
          ? const Value.absent()
          : Value(toWalletId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      note: Value(note),
      sub: Value(sub),
      billId:
          billId == null && nullToAbsent ? const Value.absent() : Value(billId),
      billDue: billDue == null && nullToAbsent
          ? const Value.absent()
          : Value(billDue),
      recurringId: recurringId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringId),
      debtId:
          debtId == null && nullToAbsent ? const Value.absent() : Value(debtId),
      debtPaymentId: debtPaymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(debtPaymentId),
      splitId: splitId == null && nullToAbsent
          ? const Value.absent()
          : Value(splitId),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Txn.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Txn(
      id: serializer.fromJson<int>(json['id']),
      kind: $TransactionsTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      amount: serializer.fromJson<int>(json['amount']),
      walletId: serializer.fromJson<int>(json['walletId']),
      toWalletId: serializer.fromJson<int?>(json['toWalletId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      note: serializer.fromJson<String>(json['note']),
      sub: serializer.fromJson<String>(json['sub']),
      billId: serializer.fromJson<int?>(json['billId']),
      billDue: serializer.fromJson<DateTime?>(json['billDue']),
      recurringId: serializer.fromJson<int?>(json['recurringId']),
      debtId: serializer.fromJson<int?>(json['debtId']),
      debtPaymentId: serializer.fromJson<int?>(json['debtPaymentId']),
      splitId: serializer.fromJson<int?>(json['splitId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer
          .toJson<String>($TransactionsTable.$converterkind.toJson(kind)),
      'amount': serializer.toJson<int>(amount),
      'walletId': serializer.toJson<int>(walletId),
      'toWalletId': serializer.toJson<int?>(toWalletId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'note': serializer.toJson<String>(note),
      'sub': serializer.toJson<String>(sub),
      'billId': serializer.toJson<int?>(billId),
      'billDue': serializer.toJson<DateTime?>(billDue),
      'recurringId': serializer.toJson<int?>(recurringId),
      'debtId': serializer.toJson<int?>(debtId),
      'debtPaymentId': serializer.toJson<int?>(debtPaymentId),
      'splitId': serializer.toJson<int?>(splitId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Txn copyWith(
          {int? id,
          TxKind? kind,
          int? amount,
          int? walletId,
          Value<int?> toWalletId = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          String? note,
          String? sub,
          Value<int?> billId = const Value.absent(),
          Value<DateTime?> billDue = const Value.absent(),
          Value<int?> recurringId = const Value.absent(),
          Value<int?> debtId = const Value.absent(),
          Value<int?> debtPaymentId = const Value.absent(),
          Value<int?> splitId = const Value.absent(),
          DateTime? occurredAt,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Txn(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
        walletId: walletId ?? this.walletId,
        toWalletId: toWalletId.present ? toWalletId.value : this.toWalletId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        note: note ?? this.note,
        sub: sub ?? this.sub,
        billId: billId.present ? billId.value : this.billId,
        billDue: billDue.present ? billDue.value : this.billDue,
        recurringId: recurringId.present ? recurringId.value : this.recurringId,
        debtId: debtId.present ? debtId.value : this.debtId,
        debtPaymentId:
            debtPaymentId.present ? debtPaymentId.value : this.debtPaymentId,
        splitId: splitId.present ? splitId.value : this.splitId,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Txn copyWithCompanion(TransactionsCompanion data) {
    return Txn(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      toWalletId:
          data.toWalletId.present ? data.toWalletId.value : this.toWalletId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      note: data.note.present ? data.note.value : this.note,
      sub: data.sub.present ? data.sub.value : this.sub,
      billId: data.billId.present ? data.billId.value : this.billId,
      billDue: data.billDue.present ? data.billDue.value : this.billDue,
      recurringId:
          data.recurringId.present ? data.recurringId.value : this.recurringId,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      debtPaymentId: data.debtPaymentId.present
          ? data.debtPaymentId.value
          : this.debtPaymentId,
      splitId: data.splitId.present ? data.splitId.value : this.splitId,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Txn(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('toWalletId: $toWalletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('sub: $sub, ')
          ..write('billId: $billId, ')
          ..write('billDue: $billDue, ')
          ..write('recurringId: $recurringId, ')
          ..write('debtId: $debtId, ')
          ..write('debtPaymentId: $debtPaymentId, ')
          ..write('splitId: $splitId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      amount,
      walletId,
      toWalletId,
      categoryId,
      note,
      sub,
      billId,
      billDue,
      recurringId,
      debtId,
      debtPaymentId,
      splitId,
      occurredAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Txn &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.walletId == this.walletId &&
          other.toWalletId == this.toWalletId &&
          other.categoryId == this.categoryId &&
          other.note == this.note &&
          other.sub == this.sub &&
          other.billId == this.billId &&
          other.billDue == this.billDue &&
          other.recurringId == this.recurringId &&
          other.debtId == this.debtId &&
          other.debtPaymentId == this.debtPaymentId &&
          other.splitId == this.splitId &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransactionsCompanion extends UpdateCompanion<Txn> {
  final Value<int> id;
  final Value<TxKind> kind;
  final Value<int> amount;
  final Value<int> walletId;
  final Value<int?> toWalletId;
  final Value<int?> categoryId;
  final Value<String> note;
  final Value<String> sub;
  final Value<int?> billId;
  final Value<DateTime?> billDue;
  final Value<int?> recurringId;
  final Value<int?> debtId;
  final Value<int?> debtPaymentId;
  final Value<int?> splitId;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.toWalletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.sub = const Value.absent(),
    this.billId = const Value.absent(),
    this.billDue = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.debtId = const Value.absent(),
    this.debtPaymentId = const Value.absent(),
    this.splitId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required TxKind kind,
    required int amount,
    required int walletId,
    this.toWalletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.note = const Value.absent(),
    this.sub = const Value.absent(),
    this.billId = const Value.absent(),
    this.billDue = const Value.absent(),
    this.recurringId = const Value.absent(),
    this.debtId = const Value.absent(),
    this.debtPaymentId = const Value.absent(),
    this.splitId = const Value.absent(),
    required DateTime occurredAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  })  : kind = Value(kind),
        amount = Value(amount),
        walletId = Value(walletId),
        occurredAt = Value(occurredAt);
  static Insertable<Txn> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<int>? walletId,
    Expression<int>? toWalletId,
    Expression<int>? categoryId,
    Expression<String>? note,
    Expression<String>? sub,
    Expression<int>? billId,
    Expression<DateTime>? billDue,
    Expression<int>? recurringId,
    Expression<int>? debtId,
    Expression<int>? debtPaymentId,
    Expression<int>? splitId,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (walletId != null) 'wallet_id': walletId,
      if (toWalletId != null) 'to_wallet_id': toWalletId,
      if (categoryId != null) 'category_id': categoryId,
      if (note != null) 'note': note,
      if (sub != null) 'sub': sub,
      if (billId != null) 'bill_id': billId,
      if (billDue != null) 'bill_due': billDue,
      if (recurringId != null) 'recurring_id': recurringId,
      if (debtId != null) 'debt_id': debtId,
      if (debtPaymentId != null) 'debt_payment_id': debtPaymentId,
      if (splitId != null) 'split_id': splitId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<TxKind>? kind,
      Value<int>? amount,
      Value<int>? walletId,
      Value<int?>? toWalletId,
      Value<int?>? categoryId,
      Value<String>? note,
      Value<String>? sub,
      Value<int?>? billId,
      Value<DateTime?>? billDue,
      Value<int?>? recurringId,
      Value<int?>? debtId,
      Value<int?>? debtPaymentId,
      Value<int?>? splitId,
      Value<DateTime>? occurredAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      sub: sub ?? this.sub,
      billId: billId ?? this.billId,
      billDue: billDue ?? this.billDue,
      recurringId: recurringId ?? this.recurringId,
      debtId: debtId ?? this.debtId,
      debtPaymentId: debtPaymentId ?? this.debtPaymentId,
      splitId: splitId ?? this.splitId,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($TransactionsTable.$converterkind.toSql(kind.value));
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (toWalletId.present) {
      map['to_wallet_id'] = Variable<int>(toWalletId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sub.present) {
      map['sub'] = Variable<String>(sub.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<int>(billId.value);
    }
    if (billDue.present) {
      map['bill_due'] = Variable<DateTime>(billDue.value);
    }
    if (recurringId.present) {
      map['recurring_id'] = Variable<int>(recurringId.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<int>(debtId.value);
    }
    if (debtPaymentId.present) {
      map['debt_payment_id'] = Variable<int>(debtPaymentId.value);
    }
    if (splitId.present) {
      map['split_id'] = Variable<int>(splitId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('toWalletId: $toWalletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('note: $note, ')
          ..write('sub: $sub, ')
          ..write('billId: $billId, ')
          ..write('billDue: $billDue, ')
          ..write('recurringId: $recurringId, ')
          ..write('debtId: $debtId, ')
          ..write('debtPaymentId: $debtPaymentId, ')
          ..write('splitId: $splitId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE CASCADE'));
  static const VerificationMeta _limitAmountMeta =
      const VerificationMeta('limitAmount');
  @override
  late final GeneratedColumn<int> limitAmount = GeneratedColumn<int>(
      'limit_amount', aliasedName, false,
      check: () => ComparableExpr(limitAmount).isBiggerOrEqualValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _fromMonthMeta =
      const VerificationMeta('fromMonth');
  @override
  late final GeneratedColumn<DateTime> fromMonth = GeneratedColumn<DateTime>(
      'from_month', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime(2000)));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, limitAmount, fromMonth, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('limit_amount')) {
      context.handle(
          _limitAmountMeta,
          limitAmount.isAcceptableOrUnknown(
              data['limit_amount']!, _limitAmountMeta));
    } else if (isInserting) {
      context.missing(_limitAmountMeta);
    }
    if (data.containsKey('from_month')) {
      context.handle(_fromMonthMeta,
          fromMonth.isAcceptableOrUnknown(data['from_month']!, _fromMonthMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {categoryId, fromMonth},
      ];
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      limitAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}limit_amount'])!,
      fromMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}from_month'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final int? categoryId;

  /// 0 = "tanpa budget mulai [fromMonth]" (menghapus target lama untuk bulan itu dst.).
  final int limitAmount;

  /// Bulan (tanggal 1) target ini mulai berlaku (v3). Target bulan M = baris
  /// dengan [fromMonth] terbesar yang ≤ M. Data lama = berlaku sejak awal.
  final DateTime fromMonth;
  final DateTime createdAt;
  const Budget(
      {required this.id,
      this.categoryId,
      required this.limitAmount,
      required this.fromMonth,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['limit_amount'] = Variable<int>(limitAmount);
    map['from_month'] = Variable<DateTime>(fromMonth);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      limitAmount: Value(limitAmount),
      fromMonth: Value(fromMonth),
      createdAt: Value(createdAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      limitAmount: serializer.fromJson<int>(json['limitAmount']),
      fromMonth: serializer.fromJson<DateTime>(json['fromMonth']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int?>(categoryId),
      'limitAmount': serializer.toJson<int>(limitAmount),
      'fromMonth': serializer.toJson<DateTime>(fromMonth),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Budget copyWith(
          {int? id,
          Value<int?> categoryId = const Value.absent(),
          int? limitAmount,
          DateTime? fromMonth,
          DateTime? createdAt}) =>
      Budget(
        id: id ?? this.id,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        limitAmount: limitAmount ?? this.limitAmount,
        fromMonth: fromMonth ?? this.fromMonth,
        createdAt: createdAt ?? this.createdAt,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      limitAmount:
          data.limitAmount.present ? data.limitAmount.value : this.limitAmount,
      fromMonth: data.fromMonth.present ? data.fromMonth.value : this.fromMonth,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('fromMonth: $fromMonth, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, limitAmount, fromMonth, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.limitAmount == this.limitAmount &&
          other.fromMonth == this.fromMonth &&
          other.createdAt == this.createdAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int?> categoryId;
  final Value<int> limitAmount;
  final Value<DateTime> fromMonth;
  final Value<DateTime> createdAt;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.limitAmount = const Value.absent(),
    this.fromMonth = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int limitAmount,
    this.fromMonth = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : limitAmount = Value(limitAmount);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<int>? limitAmount,
    Expression<DateTime>? fromMonth,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (limitAmount != null) 'limit_amount': limitAmount,
      if (fromMonth != null) 'from_month': fromMonth,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? categoryId,
      Value<int>? limitAmount,
      Value<DateTime>? fromMonth,
      Value<DateTime>? createdAt}) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      fromMonth: fromMonth ?? this.fromMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (limitAmount.present) {
      map['limit_amount'] = Variable<int>(limitAmount.value);
    }
    if (fromMonth.present) {
      map['from_month'] = Variable<DateTime>(fromMonth.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('limitAmount: $limitAmount, ')
          ..write('fromMonth: $fromMonth, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) => Setting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('🎯'));
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<int> target = GeneratedColumn<int>(
      'target', aliasedName, false,
      check: () => ComparableExpr(target).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _achievedAtMeta =
      const VerificationMeta('achievedAt');
  @override
  late final GeneratedColumn<DateTime> achievedAt = GeneratedColumn<DateTime>(
      'achieved_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remindMeta = const VerificationMeta('remind');
  @override
  late final GeneratedColumn<bool> remind = GeneratedColumn<bool>(
      'remind', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("remind" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remindWeekdayMeta =
      const VerificationMeta('remindWeekday');
  @override
  late final GeneratedColumn<int> remindWeekday = GeneratedColumn<int>(
      'remind_weekday', aliasedName, false,
      check: () => ComparableExpr(remindWeekday).isBetweenValues(1, 7),
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _remindHourMeta =
      const VerificationMeta('remindHour');
  @override
  late final GeneratedColumn<int> remindHour = GeneratedColumn<int>(
      'remind_hour', aliasedName, false,
      check: () => ComparableExpr(remindHour).isBetweenValues(0, 23),
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(19));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        emoji,
        target,
        dueDate,
        note,
        achievedAt,
        archived,
        remind,
        remindWeekday,
        remindHour,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta,
          target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
          _achievedAtMeta,
          achievedAt.isAcceptableOrUnknown(
              data['achieved_at']!, _achievedAtMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('remind')) {
      context.handle(_remindMeta,
          remind.isAcceptableOrUnknown(data['remind']!, _remindMeta));
    }
    if (data.containsKey('remind_weekday')) {
      context.handle(
          _remindWeekdayMeta,
          remindWeekday.isAcceptableOrUnknown(
              data['remind_weekday']!, _remindWeekdayMeta));
    }
    if (data.containsKey('remind_hour')) {
      context.handle(
          _remindHourMeta,
          remindHour.isAcceptableOrUnknown(
              data['remind_hour']!, _remindHourMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      target: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      achievedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}achieved_at']),
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      remind: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}remind'])!,
      remindWeekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remind_weekday'])!,
      remindHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remind_hour'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String name;

  /// Satu emoji (ikon target).
  final String emoji;
  final int target;

  /// Tanggal target (tanggal saja), opsional.
  final DateTime? dueDate;
  final String note;

  /// Saat terkumpul pertama kali mencapai target.
  final DateTime? achievedAt;

  /// Diarsipkan: tidak tampil di daftar aktif dan tidak lagi disisihkan dari Jatah.
  final bool archived;

  /// Pengingat setoran mingguan (bawaan mati): hari (1 = Senin) & jam.
  final bool remind;
  final int remindWeekday;
  final int remindHour;
  final DateTime createdAt;
  const Goal(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.target,
      this.dueDate,
      required this.note,
      this.achievedAt,
      required this.archived,
      required this.remind,
      required this.remindWeekday,
      required this.remindHour,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['target'] = Variable<int>(target);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<DateTime>(achievedAt);
    }
    map['archived'] = Variable<bool>(archived);
    map['remind'] = Variable<bool>(remind);
    map['remind_weekday'] = Variable<int>(remindWeekday);
    map['remind_hour'] = Variable<int>(remindHour);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      target: Value(target),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      note: Value(note),
      achievedAt: achievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedAt),
      archived: Value(archived),
      remind: Value(remind),
      remindWeekday: Value(remindWeekday),
      remindHour: Value(remindHour),
      createdAt: Value(createdAt),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      target: serializer.fromJson<int>(json['target']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      note: serializer.fromJson<String>(json['note']),
      achievedAt: serializer.fromJson<DateTime?>(json['achievedAt']),
      archived: serializer.fromJson<bool>(json['archived']),
      remind: serializer.fromJson<bool>(json['remind']),
      remindWeekday: serializer.fromJson<int>(json['remindWeekday']),
      remindHour: serializer.fromJson<int>(json['remindHour']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'target': serializer.toJson<int>(target),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'note': serializer.toJson<String>(note),
      'achievedAt': serializer.toJson<DateTime?>(achievedAt),
      'archived': serializer.toJson<bool>(archived),
      'remind': serializer.toJson<bool>(remind),
      'remindWeekday': serializer.toJson<int>(remindWeekday),
      'remindHour': serializer.toJson<int>(remindHour),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Goal copyWith(
          {int? id,
          String? name,
          String? emoji,
          int? target,
          Value<DateTime?> dueDate = const Value.absent(),
          String? note,
          Value<DateTime?> achievedAt = const Value.absent(),
          bool? archived,
          bool? remind,
          int? remindWeekday,
          int? remindHour,
          DateTime? createdAt}) =>
      Goal(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        target: target ?? this.target,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        note: note ?? this.note,
        achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
        archived: archived ?? this.archived,
        remind: remind ?? this.remind,
        remindWeekday: remindWeekday ?? this.remindWeekday,
        remindHour: remindHour ?? this.remindHour,
        createdAt: createdAt ?? this.createdAt,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      target: data.target.present ? data.target.value : this.target,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      note: data.note.present ? data.note.value : this.note,
      achievedAt:
          data.achievedAt.present ? data.achievedAt.value : this.achievedAt,
      archived: data.archived.present ? data.archived.value : this.archived,
      remind: data.remind.present ? data.remind.value : this.remind,
      remindWeekday: data.remindWeekday.present
          ? data.remindWeekday.value
          : this.remindWeekday,
      remindHour:
          data.remindHour.present ? data.remindHour.value : this.remindHour,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('target: $target, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('archived: $archived, ')
          ..write('remind: $remind, ')
          ..write('remindWeekday: $remindWeekday, ')
          ..write('remindHour: $remindHour, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emoji, target, dueDate, note,
      achievedAt, archived, remind, remindWeekday, remindHour, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.target == this.target &&
          other.dueDate == this.dueDate &&
          other.note == this.note &&
          other.achievedAt == this.achievedAt &&
          other.archived == this.archived &&
          other.remind == this.remind &&
          other.remindWeekday == this.remindWeekday &&
          other.remindHour == this.remindHour &&
          other.createdAt == this.createdAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<int> target;
  final Value<DateTime?> dueDate;
  final Value<String> note;
  final Value<DateTime?> achievedAt;
  final Value<bool> archived;
  final Value<bool> remind;
  final Value<int> remindWeekday;
  final Value<int> remindHour;
  final Value<DateTime> createdAt;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.target = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.remind = const Value.absent(),
    this.remindWeekday = const Value.absent(),
    this.remindHour = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.emoji = const Value.absent(),
    required int target,
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.archived = const Value.absent(),
    this.remind = const Value.absent(),
    this.remindWeekday = const Value.absent(),
    this.remindHour = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        target = Value(target);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<int>? target,
    Expression<DateTime>? dueDate,
    Expression<String>? note,
    Expression<DateTime>? achievedAt,
    Expression<bool>? archived,
    Expression<bool>? remind,
    Expression<int>? remindWeekday,
    Expression<int>? remindHour,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (target != null) 'target': target,
      if (dueDate != null) 'due_date': dueDate,
      if (note != null) 'note': note,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (archived != null) 'archived': archived,
      if (remind != null) 'remind': remind,
      if (remindWeekday != null) 'remind_weekday': remindWeekday,
      if (remindHour != null) 'remind_hour': remindHour,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GoalsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? emoji,
      Value<int>? target,
      Value<DateTime?>? dueDate,
      Value<String>? note,
      Value<DateTime?>? achievedAt,
      Value<bool>? archived,
      Value<bool>? remind,
      Value<int>? remindWeekday,
      Value<int>? remindHour,
      Value<DateTime>? createdAt}) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      target: target ?? this.target,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      achievedAt: achievedAt ?? this.achievedAt,
      archived: archived ?? this.archived,
      remind: remind ?? this.remind,
      remindWeekday: remindWeekday ?? this.remindWeekday,
      remindHour: remindHour ?? this.remindHour,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (target.present) {
      map['target'] = Variable<int>(target.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<DateTime>(achievedAt.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (remind.present) {
      map['remind'] = Variable<bool>(remind.value);
    }
    if (remindWeekday.present) {
      map['remind_weekday'] = Variable<int>(remindWeekday.value);
    }
    if (remindHour.present) {
      map['remind_hour'] = Variable<int>(remindHour.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('target: $target, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('archived: $archived, ')
          ..write('remind: $remind, ')
          ..write('remindWeekday: $remindWeekday, ')
          ..write('remindHour: $remindHour, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GoalDepositsTable extends GoalDeposits
    with TableInfo<$GoalDepositsTable, GoalDeposit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalDepositsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
      'goal_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES goals (id) ON DELETE CASCADE'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => BooleanExpressionOperators(amount.equals(0)).not(),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _walletIdMeta =
      const VerificationMeta('walletId');
  @override
  late final GeneratedColumn<int> walletId = GeneratedColumn<int>(
      'wallet_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES wallets (id) ON DELETE SET NULL'));
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
      'at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, goalId, amount, walletId, at, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_deposits';
  @override
  VerificationContext validateIntegrity(Insertable<GoalDeposit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(_goalIdMeta,
          goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta));
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(_walletIdMeta,
          walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalDeposit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalDeposit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      goalId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}goal_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      walletId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wallet_id']),
      at: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GoalDepositsTable createAlias(String alias) {
    return $GoalDepositsTable(attachedDatabase, alias);
  }
}

class GoalDeposit extends DataClass implements Insertable<GoalDeposit> {
  final int id;
  final int goalId;
  final int amount;
  final int? walletId;
  final DateTime at;
  final DateTime createdAt;
  const GoalDeposit(
      {required this.id,
      required this.goalId,
      required this.amount,
      this.walletId,
      required this.at,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['goal_id'] = Variable<int>(goalId);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<int>(walletId);
    }
    map['at'] = Variable<DateTime>(at);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GoalDepositsCompanion toCompanion(bool nullToAbsent) {
    return GoalDepositsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      amount: Value(amount),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      at: Value(at),
      createdAt: Value(createdAt),
    );
  }

  factory GoalDeposit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalDeposit(
      id: serializer.fromJson<int>(json['id']),
      goalId: serializer.fromJson<int>(json['goalId']),
      amount: serializer.fromJson<int>(json['amount']),
      walletId: serializer.fromJson<int?>(json['walletId']),
      at: serializer.fromJson<DateTime>(json['at']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'goalId': serializer.toJson<int>(goalId),
      'amount': serializer.toJson<int>(amount),
      'walletId': serializer.toJson<int?>(walletId),
      'at': serializer.toJson<DateTime>(at),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GoalDeposit copyWith(
          {int? id,
          int? goalId,
          int? amount,
          Value<int?> walletId = const Value.absent(),
          DateTime? at,
          DateTime? createdAt}) =>
      GoalDeposit(
        id: id ?? this.id,
        goalId: goalId ?? this.goalId,
        amount: amount ?? this.amount,
        walletId: walletId.present ? walletId.value : this.walletId,
        at: at ?? this.at,
        createdAt: createdAt ?? this.createdAt,
      );
  GoalDeposit copyWithCompanion(GoalDepositsCompanion data) {
    return GoalDeposit(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      amount: data.amount.present ? data.amount.value : this.amount,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      at: data.at.present ? data.at.value : this.at,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalDeposit(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('at: $at, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, amount, walletId, at, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalDeposit &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.amount == this.amount &&
          other.walletId == this.walletId &&
          other.at == this.at &&
          other.createdAt == this.createdAt);
}

class GoalDepositsCompanion extends UpdateCompanion<GoalDeposit> {
  final Value<int> id;
  final Value<int> goalId;
  final Value<int> amount;
  final Value<int?> walletId;
  final Value<DateTime> at;
  final Value<DateTime> createdAt;
  const GoalDepositsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.amount = const Value.absent(),
    this.walletId = const Value.absent(),
    this.at = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GoalDepositsCompanion.insert({
    this.id = const Value.absent(),
    required int goalId,
    required int amount,
    this.walletId = const Value.absent(),
    required DateTime at,
    this.createdAt = const Value.absent(),
  })  : goalId = Value(goalId),
        amount = Value(amount),
        at = Value(at);
  static Insertable<GoalDeposit> custom({
    Expression<int>? id,
    Expression<int>? goalId,
    Expression<int>? amount,
    Expression<int>? walletId,
    Expression<DateTime>? at,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (amount != null) 'amount': amount,
      if (walletId != null) 'wallet_id': walletId,
      if (at != null) 'at': at,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GoalDepositsCompanion copyWith(
      {Value<int>? id,
      Value<int>? goalId,
      Value<int>? amount,
      Value<int?>? walletId,
      Value<DateTime>? at,
      Value<DateTime>? createdAt}) {
    return GoalDepositsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      walletId: walletId ?? this.walletId,
      at: at ?? this.at,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<int>(walletId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalDepositsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('amount: $amount, ')
          ..write('walletId: $walletId, ')
          ..write('at: $at, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SplitMembersTable extends SplitMembers
    with TableInfo<$SplitMembersTable, SplitMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _splitIdMeta =
      const VerificationMeta('splitId');
  @override
  late final GeneratedColumn<int> splitId = GeneratedColumn<int>(
      'split_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES splits (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
      'is_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_me" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _payerMeta = const VerificationMeta('payer');
  @override
  late final GeneratedColumn<bool> payer = GeneratedColumn<bool>(
      'payer', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("payer" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _shareMeta = const VerificationMeta('share');
  @override
  late final GeneratedColumn<int> share = GeneratedColumn<int>(
      'share', aliasedName, false,
      check: () => ComparableExpr(share).isBiggerOrEqualValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<int> debtId = GeneratedColumn<int>(
      'debt_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES debts (id) ON DELETE SET NULL'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, splitId, name, isMe, payer, share, position, debtId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_members';
  @override
  VerificationContext validateIntegrity(Insertable<SplitMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_id')) {
      context.handle(_splitIdMeta,
          splitId.isAcceptableOrUnknown(data['split_id']!, _splitIdMeta));
    } else if (isInserting) {
      context.missing(_splitIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_me')) {
      context.handle(
          _isMeMeta, isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta));
    }
    if (data.containsKey('payer')) {
      context.handle(
          _payerMeta, payer.isAcceptableOrUnknown(data['payer']!, _payerMeta));
    }
    if (data.containsKey('share')) {
      context.handle(
          _shareMeta, share.isAcceptableOrUnknown(data['share']!, _shareMeta));
    } else if (isInserting) {
      context.missing(_shareMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('debt_id')) {
      context.handle(_debtIdMeta,
          debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitMember(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      splitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_me'])!,
      payer: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}payer'])!,
      share: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}share'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      debtId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}debt_id']),
    );
  }

  @override
  $SplitMembersTable createAlias(String alias) {
    return $SplitMembersTable(attachedDatabase, alias);
  }
}

class SplitMember extends DataClass implements Insertable<SplitMember> {
  final int id;
  final int splitId;
  final String name;
  final bool isMe;
  final bool payer;
  final int share;
  final int position;

  /// Catatan utang-piutang untuk bagian ini (kosong untuk aku / bila tidak perlu).
  final int? debtId;
  const SplitMember(
      {required this.id,
      required this.splitId,
      required this.name,
      required this.isMe,
      required this.payer,
      required this.share,
      required this.position,
      this.debtId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_id'] = Variable<int>(splitId);
    map['name'] = Variable<String>(name);
    map['is_me'] = Variable<bool>(isMe);
    map['payer'] = Variable<bool>(payer);
    map['share'] = Variable<int>(share);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || debtId != null) {
      map['debt_id'] = Variable<int>(debtId);
    }
    return map;
  }

  SplitMembersCompanion toCompanion(bool nullToAbsent) {
    return SplitMembersCompanion(
      id: Value(id),
      splitId: Value(splitId),
      name: Value(name),
      isMe: Value(isMe),
      payer: Value(payer),
      share: Value(share),
      position: Value(position),
      debtId:
          debtId == null && nullToAbsent ? const Value.absent() : Value(debtId),
    );
  }

  factory SplitMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitMember(
      id: serializer.fromJson<int>(json['id']),
      splitId: serializer.fromJson<int>(json['splitId']),
      name: serializer.fromJson<String>(json['name']),
      isMe: serializer.fromJson<bool>(json['isMe']),
      payer: serializer.fromJson<bool>(json['payer']),
      share: serializer.fromJson<int>(json['share']),
      position: serializer.fromJson<int>(json['position']),
      debtId: serializer.fromJson<int?>(json['debtId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitId': serializer.toJson<int>(splitId),
      'name': serializer.toJson<String>(name),
      'isMe': serializer.toJson<bool>(isMe),
      'payer': serializer.toJson<bool>(payer),
      'share': serializer.toJson<int>(share),
      'position': serializer.toJson<int>(position),
      'debtId': serializer.toJson<int?>(debtId),
    };
  }

  SplitMember copyWith(
          {int? id,
          int? splitId,
          String? name,
          bool? isMe,
          bool? payer,
          int? share,
          int? position,
          Value<int?> debtId = const Value.absent()}) =>
      SplitMember(
        id: id ?? this.id,
        splitId: splitId ?? this.splitId,
        name: name ?? this.name,
        isMe: isMe ?? this.isMe,
        payer: payer ?? this.payer,
        share: share ?? this.share,
        position: position ?? this.position,
        debtId: debtId.present ? debtId.value : this.debtId,
      );
  SplitMember copyWithCompanion(SplitMembersCompanion data) {
    return SplitMember(
      id: data.id.present ? data.id.value : this.id,
      splitId: data.splitId.present ? data.splitId.value : this.splitId,
      name: data.name.present ? data.name.value : this.name,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
      payer: data.payer.present ? data.payer.value : this.payer,
      share: data.share.present ? data.share.value : this.share,
      position: data.position.present ? data.position.value : this.position,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitMember(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('name: $name, ')
          ..write('isMe: $isMe, ')
          ..write('payer: $payer, ')
          ..write('share: $share, ')
          ..write('position: $position, ')
          ..write('debtId: $debtId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, splitId, name, isMe, payer, share, position, debtId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitMember &&
          other.id == this.id &&
          other.splitId == this.splitId &&
          other.name == this.name &&
          other.isMe == this.isMe &&
          other.payer == this.payer &&
          other.share == this.share &&
          other.position == this.position &&
          other.debtId == this.debtId);
}

class SplitMembersCompanion extends UpdateCompanion<SplitMember> {
  final Value<int> id;
  final Value<int> splitId;
  final Value<String> name;
  final Value<bool> isMe;
  final Value<bool> payer;
  final Value<int> share;
  final Value<int> position;
  final Value<int?> debtId;
  const SplitMembersCompanion({
    this.id = const Value.absent(),
    this.splitId = const Value.absent(),
    this.name = const Value.absent(),
    this.isMe = const Value.absent(),
    this.payer = const Value.absent(),
    this.share = const Value.absent(),
    this.position = const Value.absent(),
    this.debtId = const Value.absent(),
  });
  SplitMembersCompanion.insert({
    this.id = const Value.absent(),
    required int splitId,
    required String name,
    this.isMe = const Value.absent(),
    this.payer = const Value.absent(),
    required int share,
    required int position,
    this.debtId = const Value.absent(),
  })  : splitId = Value(splitId),
        name = Value(name),
        share = Value(share),
        position = Value(position);
  static Insertable<SplitMember> custom({
    Expression<int>? id,
    Expression<int>? splitId,
    Expression<String>? name,
    Expression<bool>? isMe,
    Expression<bool>? payer,
    Expression<int>? share,
    Expression<int>? position,
    Expression<int>? debtId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitId != null) 'split_id': splitId,
      if (name != null) 'name': name,
      if (isMe != null) 'is_me': isMe,
      if (payer != null) 'payer': payer,
      if (share != null) 'share': share,
      if (position != null) 'position': position,
      if (debtId != null) 'debt_id': debtId,
    });
  }

  SplitMembersCompanion copyWith(
      {Value<int>? id,
      Value<int>? splitId,
      Value<String>? name,
      Value<bool>? isMe,
      Value<bool>? payer,
      Value<int>? share,
      Value<int>? position,
      Value<int?>? debtId}) {
    return SplitMembersCompanion(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      name: name ?? this.name,
      isMe: isMe ?? this.isMe,
      payer: payer ?? this.payer,
      share: share ?? this.share,
      position: position ?? this.position,
      debtId: debtId ?? this.debtId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitId.present) {
      map['split_id'] = Variable<int>(splitId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    if (payer.present) {
      map['payer'] = Variable<bool>(payer.value);
    }
    if (share.present) {
      map['share'] = Variable<int>(share.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<int>(debtId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitMembersCompanion(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('name: $name, ')
          ..write('isMe: $isMe, ')
          ..write('payer: $payer, ')
          ..write('share: $share, ')
          ..write('position: $position, ')
          ..write('debtId: $debtId')
          ..write(')'))
        .toString();
  }
}

class $SplitItemsTable extends SplitItems
    with TableInfo<$SplitItemsTable, SplitItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _splitIdMeta =
      const VerificationMeta('splitId');
  @override
  late final GeneratedColumn<int> splitId = GeneratedColumn<int>(
      'split_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES splits (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, false,
      check: () => ComparableExpr(price).isBiggerThanValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  static const VerificationMeta _whoMeta = const VerificationMeta('who');
  @override
  late final GeneratedColumn<String> who = GeneratedColumn<String>(
      'who', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, splitId, name, price, who, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_items';
  @override
  VerificationContext validateIntegrity(Insertable<SplitItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('split_id')) {
      context.handle(_splitIdMeta,
          splitId.isAcceptableOrUnknown(data['split_id']!, _splitIdMeta));
    } else if (isInserting) {
      context.missing(_splitIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('who')) {
      context.handle(
          _whoMeta, who.isAcceptableOrUnknown(data['who']!, _whoMeta));
    } else if (isInserting) {
      context.missing(_whoMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      splitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price'])!,
      who: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}who'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $SplitItemsTable createAlias(String alias) {
    return $SplitItemsTable(attachedDatabase, alias);
  }
}

class SplitItem extends DataClass implements Insertable<SplitItem> {
  final int id;
  final int splitId;
  final String name;
  final int price;
  final String who;
  final int position;
  const SplitItem(
      {required this.id,
      required this.splitId,
      required this.name,
      required this.price,
      required this.who,
      required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['split_id'] = Variable<int>(splitId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<int>(price);
    map['who'] = Variable<String>(who);
    map['position'] = Variable<int>(position);
    return map;
  }

  SplitItemsCompanion toCompanion(bool nullToAbsent) {
    return SplitItemsCompanion(
      id: Value(id),
      splitId: Value(splitId),
      name: Value(name),
      price: Value(price),
      who: Value(who),
      position: Value(position),
    );
  }

  factory SplitItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitItem(
      id: serializer.fromJson<int>(json['id']),
      splitId: serializer.fromJson<int>(json['splitId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int>(json['price']),
      who: serializer.fromJson<String>(json['who']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'splitId': serializer.toJson<int>(splitId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int>(price),
      'who': serializer.toJson<String>(who),
      'position': serializer.toJson<int>(position),
    };
  }

  SplitItem copyWith(
          {int? id,
          int? splitId,
          String? name,
          int? price,
          String? who,
          int? position}) =>
      SplitItem(
        id: id ?? this.id,
        splitId: splitId ?? this.splitId,
        name: name ?? this.name,
        price: price ?? this.price,
        who: who ?? this.who,
        position: position ?? this.position,
      );
  SplitItem copyWithCompanion(SplitItemsCompanion data) {
    return SplitItem(
      id: data.id.present ? data.id.value : this.id,
      splitId: data.splitId.present ? data.splitId.value : this.splitId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      who: data.who.present ? data.who.value : this.who,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitItem(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('who: $who, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, splitId, name, price, who, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitItem &&
          other.id == this.id &&
          other.splitId == this.splitId &&
          other.name == this.name &&
          other.price == this.price &&
          other.who == this.who &&
          other.position == this.position);
}

class SplitItemsCompanion extends UpdateCompanion<SplitItem> {
  final Value<int> id;
  final Value<int> splitId;
  final Value<String> name;
  final Value<int> price;
  final Value<String> who;
  final Value<int> position;
  const SplitItemsCompanion({
    this.id = const Value.absent(),
    this.splitId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.who = const Value.absent(),
    this.position = const Value.absent(),
  });
  SplitItemsCompanion.insert({
    this.id = const Value.absent(),
    required int splitId,
    required String name,
    required int price,
    required String who,
    required int position,
  })  : splitId = Value(splitId),
        name = Value(name),
        price = Value(price),
        who = Value(who),
        position = Value(position);
  static Insertable<SplitItem> custom({
    Expression<int>? id,
    Expression<int>? splitId,
    Expression<String>? name,
    Expression<int>? price,
    Expression<String>? who,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (splitId != null) 'split_id': splitId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (who != null) 'who': who,
      if (position != null) 'position': position,
    });
  }

  SplitItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? splitId,
      Value<String>? name,
      Value<int>? price,
      Value<String>? who,
      Value<int>? position}) {
    return SplitItemsCompanion(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      name: name ?? this.name,
      price: price ?? this.price,
      who: who ?? this.who,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (splitId.present) {
      map['split_id'] = Variable<int>(splitId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (who.present) {
      map['who'] = Variable<String>(who.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitItemsCompanion(')
          ..write('id: $id, ')
          ..write('splitId: $splitId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('who: $who, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $BudgetAdjustmentsTable extends BudgetAdjustments
    with TableInfo<$BudgetAdjustmentsTable, BudgetAdjustment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetAdjustmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<DateTime> month = GeneratedColumn<DateTime>(
      'month', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES categories (id) ON DELETE CASCADE'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
      'amount', aliasedName, false,
      check: () => BooleanExpressionOperators(amount.equals(0)).not(),
      type: DriftSqlType.int,
      requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<BudgetAdjustReason, String>
      reason = GeneratedColumn<String>('reason', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<BudgetAdjustReason>(
              $BudgetAdjustmentsTable.$converterreason);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, month, categoryId, amount, reason, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_adjustments';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetAdjustment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetAdjustment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetAdjustment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}month'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount'])!,
      reason: $BudgetAdjustmentsTable.$converterreason.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BudgetAdjustmentsTable createAlias(String alias) {
    return $BudgetAdjustmentsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BudgetAdjustReason, String, String>
      $converterreason =
      const EnumNameConverter<BudgetAdjustReason>(BudgetAdjustReason.values);
}

class BudgetAdjustment extends DataClass
    implements Insertable<BudgetAdjustment> {
  final int id;

  /// Tanggal 1 bulan yang disesuaikan.
  final DateTime month;
  final int? categoryId;

  /// Bisa negatif (kategori asal pindah batas). Tidak boleh 0.
  final int amount;
  final BudgetAdjustReason reason;
  final DateTime createdAt;
  const BudgetAdjustment(
      {required this.id,
      required this.month,
      this.categoryId,
      required this.amount,
      required this.reason,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<DateTime>(month);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['amount'] = Variable<int>(amount);
    {
      map['reason'] = Variable<String>(
          $BudgetAdjustmentsTable.$converterreason.toSql(reason));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetAdjustmentsCompanion toCompanion(bool nullToAbsent) {
    return BudgetAdjustmentsCompanion(
      id: Value(id),
      month: Value(month),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      reason: Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory BudgetAdjustment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetAdjustment(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<DateTime>(json['month']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: $BudgetAdjustmentsTable.$converterreason
          .fromJson(serializer.fromJson<String>(json['reason'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<DateTime>(month),
      'categoryId': serializer.toJson<int?>(categoryId),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<String>(
          $BudgetAdjustmentsTable.$converterreason.toJson(reason)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BudgetAdjustment copyWith(
          {int? id,
          DateTime? month,
          Value<int?> categoryId = const Value.absent(),
          int? amount,
          BudgetAdjustReason? reason,
          DateTime? createdAt}) =>
      BudgetAdjustment(
        id: id ?? this.id,
        month: month ?? this.month,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
        createdAt: createdAt ?? this.createdAt,
      );
  BudgetAdjustment copyWithCompanion(BudgetAdjustmentsCompanion data) {
    return BudgetAdjustment(
      id: data.id.present ? data.id.value : this.id,
      month: data.month.present ? data.month.value : this.month,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetAdjustment(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, month, categoryId, amount, reason, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetAdjustment &&
          other.id == this.id &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class BudgetAdjustmentsCompanion extends UpdateCompanion<BudgetAdjustment> {
  final Value<int> id;
  final Value<DateTime> month;
  final Value<int?> categoryId;
  final Value<int> amount;
  final Value<BudgetAdjustReason> reason;
  final Value<DateTime> createdAt;
  const BudgetAdjustmentsCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetAdjustmentsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime month,
    this.categoryId = const Value.absent(),
    required int amount,
    required BudgetAdjustReason reason,
    this.createdAt = const Value.absent(),
  })  : month = Value(month),
        amount = Value(amount),
        reason = Value(reason);
  static Insertable<BudgetAdjustment> custom({
    Expression<int>? id,
    Expression<DateTime>? month,
    Expression<int>? categoryId,
    Expression<int>? amount,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetAdjustmentsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? month,
      Value<int?>? categoryId,
      Value<int>? amount,
      Value<BudgetAdjustReason>? reason,
      Value<DateTime>? createdAt}) {
    return BudgetAdjustmentsCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<DateTime>(month.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(
          $BudgetAdjustmentsTable.$converterreason.toSql(reason.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetAdjustmentsCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NetItemsTable extends NetItems with TableInfo<$NetItemsTable, NetItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  @override
  late final GeneratedColumnWithTypeConverter<NetItemKind, String> kind =
      GeneratedColumn<String>('kind', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<NetItemKind>($NetItemsTable.$converterkind);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 40),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
      'value', aliasedName, false,
      check: () => ComparableExpr(value).isBiggerOrEqualValue(0),
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _milligramsMeta =
      const VerificationMeta('milligrams');
  @override
  late final GeneratedColumn<int> milligrams = GeneratedColumn<int>(
      'milligrams', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _pricePerGramMeta =
      const VerificationMeta('pricePerGram');
  @override
  late final GeneratedColumn<int> pricePerGram = GeneratedColumn<int>(
      'price_per_gram', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, kind, name, value, milligrams, pricePerGram, updatedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'net_items';
  @override
  VerificationContext validateIntegrity(Insertable<NetItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('milligrams')) {
      context.handle(
          _milligramsMeta,
          milligrams.isAcceptableOrUnknown(
              data['milligrams']!, _milligramsMeta));
    }
    if (data.containsKey('price_per_gram')) {
      context.handle(
          _pricePerGramMeta,
          pricePerGram.isAcceptableOrUnknown(
              data['price_per_gram']!, _pricePerGramMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NetItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: $NetItemsTable.$converterkind.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}value'])!,
      milligrams: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}milligrams']),
      pricePerGram: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_per_gram']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NetItemsTable createAlias(String alias) {
    return $NetItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NetItemKind, String, String> $converterkind =
      const EnumNameConverter<NetItemKind>(NetItemKind.values);
}

class NetItem extends DataClass implements Insertable<NetItem> {
  final int id;
  final NetItemKind kind;
  final String name;
  final int value;

  /// Berat emas dalam miligram (10 g = 10000).
  final int? milligrams;
  final int? pricePerGram;

  /// Terakhir nilai/harga diperbarui (untuk pengingat > 30 hari).
  final DateTime updatedAt;
  final DateTime createdAt;
  const NetItem(
      {required this.id,
      required this.kind,
      required this.name,
      required this.value,
      this.milligrams,
      this.pricePerGram,
      required this.updatedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>($NetItemsTable.$converterkind.toSql(kind));
    }
    map['name'] = Variable<String>(name);
    map['value'] = Variable<int>(value);
    if (!nullToAbsent || milligrams != null) {
      map['milligrams'] = Variable<int>(milligrams);
    }
    if (!nullToAbsent || pricePerGram != null) {
      map['price_per_gram'] = Variable<int>(pricePerGram);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NetItemsCompanion toCompanion(bool nullToAbsent) {
    return NetItemsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      value: Value(value),
      milligrams: milligrams == null && nullToAbsent
          ? const Value.absent()
          : Value(milligrams),
      pricePerGram: pricePerGram == null && nullToAbsent
          ? const Value.absent()
          : Value(pricePerGram),
      updatedAt: Value(updatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory NetItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NetItem(
      id: serializer.fromJson<int>(json['id']),
      kind: $NetItemsTable.$converterkind
          .fromJson(serializer.fromJson<String>(json['kind'])),
      name: serializer.fromJson<String>(json['name']),
      value: serializer.fromJson<int>(json['value']),
      milligrams: serializer.fromJson<int?>(json['milligrams']),
      pricePerGram: serializer.fromJson<int?>(json['pricePerGram']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind':
          serializer.toJson<String>($NetItemsTable.$converterkind.toJson(kind)),
      'name': serializer.toJson<String>(name),
      'value': serializer.toJson<int>(value),
      'milligrams': serializer.toJson<int?>(milligrams),
      'pricePerGram': serializer.toJson<int?>(pricePerGram),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NetItem copyWith(
          {int? id,
          NetItemKind? kind,
          String? name,
          int? value,
          Value<int?> milligrams = const Value.absent(),
          Value<int?> pricePerGram = const Value.absent(),
          DateTime? updatedAt,
          DateTime? createdAt}) =>
      NetItem(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        name: name ?? this.name,
        value: value ?? this.value,
        milligrams: milligrams.present ? milligrams.value : this.milligrams,
        pricePerGram:
            pricePerGram.present ? pricePerGram.value : this.pricePerGram,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  NetItem copyWithCompanion(NetItemsCompanion data) {
    return NetItem(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      value: data.value.present ? data.value.value : this.value,
      milligrams:
          data.milligrams.present ? data.milligrams.value : this.milligrams,
      pricePerGram: data.pricePerGram.present
          ? data.pricePerGram.value
          : this.pricePerGram,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NetItem(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('milligrams: $milligrams, ')
          ..write('pricePerGram: $pricePerGram, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, kind, name, value, milligrams, pricePerGram, updatedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetItem &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.value == this.value &&
          other.milligrams == this.milligrams &&
          other.pricePerGram == this.pricePerGram &&
          other.updatedAt == this.updatedAt &&
          other.createdAt == this.createdAt);
}

class NetItemsCompanion extends UpdateCompanion<NetItem> {
  final Value<int> id;
  final Value<NetItemKind> kind;
  final Value<String> name;
  final Value<int> value;
  final Value<int?> milligrams;
  final Value<int?> pricePerGram;
  final Value<DateTime> updatedAt;
  final Value<DateTime> createdAt;
  const NetItemsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.value = const Value.absent(),
    this.milligrams = const Value.absent(),
    this.pricePerGram = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NetItemsCompanion.insert({
    this.id = const Value.absent(),
    required NetItemKind kind,
    required String name,
    this.value = const Value.absent(),
    this.milligrams = const Value.absent(),
    this.pricePerGram = const Value.absent(),
    required DateTime updatedAt,
    this.createdAt = const Value.absent(),
  })  : kind = Value(kind),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<NetItem> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<int>? value,
    Expression<int>? milligrams,
    Expression<int>? pricePerGram,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (value != null) 'value': value,
      if (milligrams != null) 'milligrams': milligrams,
      if (pricePerGram != null) 'price_per_gram': pricePerGram,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NetItemsCompanion copyWith(
      {Value<int>? id,
      Value<NetItemKind>? kind,
      Value<String>? name,
      Value<int>? value,
      Value<int?>? milligrams,
      Value<int?>? pricePerGram,
      Value<DateTime>? updatedAt,
      Value<DateTime>? createdAt}) {
    return NetItemsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      value: value ?? this.value,
      milligrams: milligrams ?? this.milligrams,
      pricePerGram: pricePerGram ?? this.pricePerGram,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] =
          Variable<String>($NetItemsTable.$converterkind.toSql(kind.value));
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (milligrams.present) {
      map['milligrams'] = Variable<int>(milligrams.value);
    }
    if (pricePerGram.present) {
      map['price_per_gram'] = Variable<int>(pricePerGram.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetItemsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('value: $value, ')
          ..write('milligrams: $milligrams, ')
          ..write('pricePerGram: $pricePerGram, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NetSnapshotsTable extends NetSnapshots
    with TableInfo<$NetSnapshotsTable, NetSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NetSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<DateTime> month = GeneratedColumn<DateTime>(
      'month', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _assetsMeta = const VerificationMeta('assets');
  @override
  late final GeneratedColumn<int> assets = GeneratedColumn<int>(
      'assets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _liabilitiesMeta =
      const VerificationMeta('liabilities');
  @override
  late final GeneratedColumn<int> liabilities = GeneratedColumn<int>(
      'liabilities', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [month, assets, liabilities, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'net_snapshots';
  @override
  VerificationContext validateIntegrity(Insertable<NetSnapshot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('assets')) {
      context.handle(_assetsMeta,
          assets.isAcceptableOrUnknown(data['assets']!, _assetsMeta));
    } else if (isInserting) {
      context.missing(_assetsMeta);
    }
    if (data.containsKey('liabilities')) {
      context.handle(
          _liabilitiesMeta,
          liabilities.isAcceptableOrUnknown(
              data['liabilities']!, _liabilitiesMeta));
    } else if (isInserting) {
      context.missing(_liabilitiesMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  NetSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NetSnapshot(
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}month'])!,
      assets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}assets'])!,
      liabilities: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}liabilities'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NetSnapshotsTable createAlias(String alias) {
    return $NetSnapshotsTable(attachedDatabase, alias);
  }
}

class NetSnapshot extends DataClass implements Insertable<NetSnapshot> {
  /// Tanggal 1 bulan itu.
  final DateTime month;
  final int assets;
  final int liabilities;
  final DateTime updatedAt;
  const NetSnapshot(
      {required this.month,
      required this.assets,
      required this.liabilities,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<DateTime>(month);
    map['assets'] = Variable<int>(assets);
    map['liabilities'] = Variable<int>(liabilities);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NetSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return NetSnapshotsCompanion(
      month: Value(month),
      assets: Value(assets),
      liabilities: Value(liabilities),
      updatedAt: Value(updatedAt),
    );
  }

  factory NetSnapshot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NetSnapshot(
      month: serializer.fromJson<DateTime>(json['month']),
      assets: serializer.fromJson<int>(json['assets']),
      liabilities: serializer.fromJson<int>(json['liabilities']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<DateTime>(month),
      'assets': serializer.toJson<int>(assets),
      'liabilities': serializer.toJson<int>(liabilities),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NetSnapshot copyWith(
          {DateTime? month,
          int? assets,
          int? liabilities,
          DateTime? updatedAt}) =>
      NetSnapshot(
        month: month ?? this.month,
        assets: assets ?? this.assets,
        liabilities: liabilities ?? this.liabilities,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  NetSnapshot copyWithCompanion(NetSnapshotsCompanion data) {
    return NetSnapshot(
      month: data.month.present ? data.month.value : this.month,
      assets: data.assets.present ? data.assets.value : this.assets,
      liabilities:
          data.liabilities.present ? data.liabilities.value : this.liabilities,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NetSnapshot(')
          ..write('month: $month, ')
          ..write('assets: $assets, ')
          ..write('liabilities: $liabilities, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(month, assets, liabilities, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetSnapshot &&
          other.month == this.month &&
          other.assets == this.assets &&
          other.liabilities == this.liabilities &&
          other.updatedAt == this.updatedAt);
}

class NetSnapshotsCompanion extends UpdateCompanion<NetSnapshot> {
  final Value<DateTime> month;
  final Value<int> assets;
  final Value<int> liabilities;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NetSnapshotsCompanion({
    this.month = const Value.absent(),
    this.assets = const Value.absent(),
    this.liabilities = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NetSnapshotsCompanion.insert({
    required DateTime month,
    required int assets,
    required int liabilities,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : month = Value(month),
        assets = Value(assets),
        liabilities = Value(liabilities),
        updatedAt = Value(updatedAt);
  static Insertable<NetSnapshot> custom({
    Expression<DateTime>? month,
    Expression<int>? assets,
    Expression<int>? liabilities,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (assets != null) 'assets': assets,
      if (liabilities != null) 'liabilities': liabilities,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NetSnapshotsCompanion copyWith(
      {Value<DateTime>? month,
      Value<int>? assets,
      Value<int>? liabilities,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return NetSnapshotsCompanion(
      month: month ?? this.month,
      assets: assets ?? this.assets,
      liabilities: liabilities ?? this.liabilities,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<DateTime>(month.value);
    }
    if (assets.present) {
      map['assets'] = Variable<int>(assets.value);
    }
    if (liabilities.present) {
      map['liabilities'] = Variable<int>(liabilities.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NetSnapshotsCompanion(')
          ..write('month: $month, ')
          ..write('assets: $assets, ')
          ..write('liabilities: $liabilities, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $RecurringTxsTable recurringTxs = $RecurringTxsTable(this);
  late final $SplitsTable splits = $SplitsTable(this);
  late final $DebtsTable debts = $DebtsTable(this);
  late final $DebtPaymentsTable debtPayments = $DebtPaymentsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $GoalDepositsTable goalDeposits = $GoalDepositsTable(this);
  late final $SplitMembersTable splitMembers = $SplitMembersTable(this);
  late final $SplitItemsTable splitItems = $SplitItemsTable(this);
  late final $BudgetAdjustmentsTable budgetAdjustments =
      $BudgetAdjustmentsTable(this);
  late final $NetItemsTable netItems = $NetItemsTable(this);
  late final $NetSnapshotsTable netSnapshots = $NetSnapshotsTable(this);
  late final Index txOccurredAt = Index('tx_occurred_at',
      'CREATE INDEX tx_occurred_at ON transactions (occurred_at)');
  late final Index txWallet =
      Index('tx_wallet', 'CREATE INDEX tx_wallet ON transactions (wallet_id)');
  late final Index txCategory = Index(
      'tx_category', 'CREATE INDEX tx_category ON transactions (category_id)');
  late final WalletsDao walletsDao = WalletsDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final TransactionsDao transactionsDao =
      TransactionsDao(this as AppDatabase);
  late final BudgetsDao budgetsDao = BudgetsDao(this as AppDatabase);
  late final BillsDao billsDao = BillsDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final RecurringDao recurringDao = RecurringDao(this as AppDatabase);
  late final DebtsDao debtsDao = DebtsDao(this as AppDatabase);
  late final GoalsDao goalsDao = GoalsDao(this as AppDatabase);
  late final SplitsDao splitsDao = SplitsDao(this as AppDatabase);
  late final NetWorthDao netWorthDao = NetWorthDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        wallets,
        categories,
        bills,
        recurringTxs,
        splits,
        debts,
        debtPayments,
        transactions,
        budgets,
        settings,
        goals,
        goalDeposits,
        splitMembers,
        splitItems,
        budgetAdjustments,
        netItems,
        netSnapshots,
        txOccurredAt,
        txWallet,
        txCategory
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bills', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('wallets',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bills', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('recurring_txs', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('splits', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('wallets',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('debts', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('splits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('debts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('debts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('debt_payments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('wallets',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('debt_payments', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('bills',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('recurring_txs',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('debts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('debt_payments',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('splits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('budgets', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('goals',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('goal_deposits', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('wallets',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('goal_deposits', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('splits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('split_members', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('debts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('split_members', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('splits',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('split_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('budget_adjustments', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$WalletsTableCreateCompanionBuilder = WalletsCompanion Function({
  Value<int> id,
  required String name,
  required WalletType type,
  Value<int> initialBalance,
  Value<String> icon,
  Value<int> color,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<DateTime> createdAt,
});
typedef $$WalletsTableUpdateCompanionBuilder = WalletsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<WalletType> type,
  Value<int> initialBalance,
  Value<String> icon,
  Value<int> color,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<DateTime> createdAt,
});

final class $$WalletsTableReferences
    extends BaseReferences<_$AppDatabase, $WalletsTable, Wallet> {
  $$WalletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BillsTable, List<Bill>> _billsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bills,
          aliasName: 'wallets__id__bills__wallet_id');

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTxsTable, List<RecurringTx>>
      _recurringSourcesTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recurringTxs,
              aliasName: 'wallets__id__recurring_txs__wallet_id');

  $$RecurringTxsTableProcessedTableManager get recurringSources {
    final manager = $$RecurringTxsTableTableManager($_db, $_db.recurringTxs)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringSourcesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTxsTable, List<RecurringTx>>
      _recurringTargetsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recurringTxs,
              aliasName: 'wallets__id__recurring_txs__to_wallet_id');

  $$RecurringTxsTableProcessedTableManager get recurringTargets {
    final manager = $$RecurringTxsTableTableManager($_db, $_db.recurringTxs)
        .filter((f) => f.toWalletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringTargetsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SplitsTable, List<Split>> _splitsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.splits,
          aliasName: 'wallets__id__splits__wallet_id');

  $$SplitsTableProcessedTableManager get splitsRefs {
    final manager = $$SplitsTableTableManager($_db, $_db.splits)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DebtsTable, List<Debt>> _debtsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.debts,
          aliasName: 'wallets__id__debts__wallet_id');

  $$DebtsTableProcessedTableManager get debtsRefs {
    final manager = $$DebtsTableTableManager($_db, $_db.debts)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DebtPaymentsTable, List<DebtPayment>>
      _debtPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.debtPayments,
              aliasName: 'wallets__id__debt_payments__wallet_id');

  $$DebtPaymentsTableProcessedTableManager get debtPaymentsRefs {
    final manager = $$DebtPaymentsTableTableManager($_db, $_db.debtPayments)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _sourceTransactionsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'wallets__id__transactions__wallet_id');

  $$TransactionsTableProcessedTableManager get sourceTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourceTransactionsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _incomingTransfersTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'wallets__id__transactions__to_wallet_id');

  $$TransactionsTableProcessedTableManager get incomingTransfers {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.toWalletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingTransfersTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GoalDepositsTable, List<GoalDeposit>>
      _goalDepositsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.goalDeposits,
              aliasName: 'wallets__id__goal_deposits__wallet_id');

  $$GoalDepositsTableProcessedTableManager get goalDepositsRefs {
    final manager = $$GoalDepositsTableTableManager($_db, $_db.goalDeposits)
        .filter((f) => f.walletId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalDepositsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<WalletType, WalletType, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> billsRefs(
      Expression<bool> Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurringSources(
      Expression<bool> Function($$RecurringTxsTableFilterComposer f) f) {
    final $$RecurringTxsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableFilterComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurringTargets(
      Expression<bool> Function($$RecurringTxsTableFilterComposer f) f) {
    final $$RecurringTxsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.toWalletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableFilterComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> splitsRefs(
      Expression<bool> Function($$SplitsTableFilterComposer f) f) {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableFilterComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> debtsRefs(
      Expression<bool> Function($$DebtsTableFilterComposer f) f) {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableFilterComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> debtPaymentsRefs(
      Expression<bool> Function($$DebtPaymentsTableFilterComposer f) f) {
    final $$DebtPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> sourceTransactions(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> incomingTransfers(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.toWalletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> goalDepositsRefs(
      Expression<bool> Function($$GoalDepositsTableFilterComposer f) f) {
    final $$GoalDepositsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goalDeposits,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalDepositsTableFilterComposer(
              $db: $db,
              $table: $db.goalDeposits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WalletType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get initialBalance => $composableBuilder(
      column: $table.initialBalance, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> billsRefs<T extends Object>(
      Expression<T> Function($$BillsTableAnnotationComposer a) f) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurringSources<T extends Object>(
      Expression<T> Function($$RecurringTxsTableAnnotationComposer a) f) {
    final $$RecurringTxsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableAnnotationComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurringTargets<T extends Object>(
      Expression<T> Function($$RecurringTxsTableAnnotationComposer a) f) {
    final $$RecurringTxsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.toWalletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableAnnotationComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> splitsRefs<T extends Object>(
      Expression<T> Function($$SplitsTableAnnotationComposer a) f) {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> debtsRefs<T extends Object>(
      Expression<T> Function($$DebtsTableAnnotationComposer a) f) {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableAnnotationComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> debtPaymentsRefs<T extends Object>(
      Expression<T> Function($$DebtPaymentsTableAnnotationComposer a) f) {
    final $$DebtPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> sourceTransactions<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> incomingTransfers<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.toWalletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> goalDepositsRefs<T extends Object>(
      Expression<T> Function($$GoalDepositsTableAnnotationComposer a) f) {
    final $$GoalDepositsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goalDeposits,
        getReferencedColumn: (t) => t.walletId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalDepositsTableAnnotationComposer(
              $db: $db,
              $table: $db.goalDeposits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WalletsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WalletsTable,
    Wallet,
    $$WalletsTableFilterComposer,
    $$WalletsTableOrderingComposer,
    $$WalletsTableAnnotationComposer,
    $$WalletsTableCreateCompanionBuilder,
    $$WalletsTableUpdateCompanionBuilder,
    (Wallet, $$WalletsTableReferences),
    Wallet,
    PrefetchHooks Function(
        {bool billsRefs,
        bool recurringSources,
        bool recurringTargets,
        bool splitsRefs,
        bool debtsRefs,
        bool debtPaymentsRefs,
        bool sourceTransactions,
        bool incomingTransfers,
        bool goalDepositsRefs})> {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<WalletType> type = const Value.absent(),
            Value<int> initialBalance = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WalletsCompanion(
            id: id,
            name: name,
            type: type,
            initialBalance: initialBalance,
            icon: icon,
            color: color,
            sortOrder: sortOrder,
            archived: archived,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required WalletType type,
            Value<int> initialBalance = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WalletsCompanion.insert(
            id: id,
            name: name,
            type: type,
            initialBalance: initialBalance,
            icon: icon,
            color: color,
            sortOrder: sortOrder,
            archived: archived,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WalletsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {billsRefs = false,
              recurringSources = false,
              recurringTargets = false,
              splitsRefs = false,
              debtsRefs = false,
              debtPaymentsRefs = false,
              sourceTransactions = false,
              incomingTransfers = false,
              goalDepositsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (billsRefs) db.bills,
                if (recurringSources) db.recurringTxs,
                if (recurringTargets) db.recurringTxs,
                if (splitsRefs) db.splits,
                if (debtsRefs) db.debts,
                if (debtPaymentsRefs) db.debtPayments,
                if (sourceTransactions) db.transactions,
                if (incomingTransfers) db.transactions,
                if (goalDepositsRefs) db.goalDeposits
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (billsRefs)
                    await $_getPrefetchedData<Wallet, $WalletsTable, Bill>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._billsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0).billsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items),
                  if (recurringSources)
                    await $_getPrefetchedData<Wallet, $WalletsTable,
                            RecurringTx>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._recurringSourcesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0)
                                .recurringSources,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items),
                  if (recurringTargets)
                    await $_getPrefetchedData<Wallet, $WalletsTable,
                            RecurringTx>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._recurringTargetsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0)
                                .recurringTargets,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.toWalletId == item.id),
                        typedResults: items),
                  if (splitsRefs)
                    await $_getPrefetchedData<Wallet, $WalletsTable, Split>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._splitsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0).splitsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items),
                  if (debtsRefs)
                    await $_getPrefetchedData<Wallet, $WalletsTable, Debt>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._debtsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0).debtsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items),
                  if (debtPaymentsRefs)
                    await $_getPrefetchedData<Wallet, $WalletsTable,
                            DebtPayment>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._debtPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0)
                                .debtPaymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items),
                  if (sourceTransactions)
                    await $_getPrefetchedData<Wallet, $WalletsTable, Txn>(
                        currentTable: table,
                        referencedTable: $$WalletsTableReferences
                            ._sourceTransactionsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0)
                                .sourceTransactions,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items),
                  if (incomingTransfers)
                    await $_getPrefetchedData<Wallet, $WalletsTable, Txn>(
                        currentTable: table,
                        referencedTable: $$WalletsTableReferences
                            ._incomingTransfersTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0)
                                .incomingTransfers,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.toWalletId == item.id),
                        typedResults: items),
                  if (goalDepositsRefs)
                    await $_getPrefetchedData<Wallet, $WalletsTable,
                            GoalDeposit>(
                        currentTable: table,
                        referencedTable:
                            $$WalletsTableReferences._goalDepositsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WalletsTableReferences(db, table, p0)
                                .goalDepositsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.walletId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WalletsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WalletsTable,
    Wallet,
    $$WalletsTableFilterComposer,
    $$WalletsTableOrderingComposer,
    $$WalletsTableAnnotationComposer,
    $$WalletsTableCreateCompanionBuilder,
    $$WalletsTableUpdateCompanionBuilder,
    (Wallet, $$WalletsTableReferences),
    Wallet,
    PrefetchHooks Function(
        {bool billsRefs,
        bool recurringSources,
        bool recurringTargets,
        bool splitsRefs,
        bool debtsRefs,
        bool debtPaymentsRefs,
        bool sourceTransactions,
        bool incomingTransfers,
        bool goalDepositsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required TxKind kind,
  Value<String> icon,
  Value<String> keywords,
  Value<int> color,
  Value<String> subs,
  Value<int> sortOrder,
  Value<bool> archived,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<TxKind> kind,
  Value<String> icon,
  Value<String> keywords,
  Value<int> color,
  Value<String> subs,
  Value<int> sortOrder,
  Value<bool> archived,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BillsTable, List<Bill>> _billsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bills,
          aliasName: 'categories__id__bills__category_id');

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RecurringTxsTable, List<RecurringTx>>
      _recurringTxsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.recurringTxs,
              aliasName: 'categories__id__recurring_txs__category_id');

  $$RecurringTxsTableProcessedTableManager get recurringTxsRefs {
    final manager = $$RecurringTxsTableTableManager($_db, $_db.recurringTxs)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_recurringTxsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SplitsTable, List<Split>> _splitsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.splits,
          aliasName: 'categories__id__splits__category_id');

  $$SplitsTableProcessedTableManager get splitsRefs {
    final manager = $$SplitsTableTableManager($_db, $_db.splits)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'categories__id__transactions__category_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgets,
          aliasName: 'categories__id__budgets__category_id');

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager($_db, $_db.budgets)
        .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetAdjustmentsTable, List<BudgetAdjustment>>
      _budgetAdjustmentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.budgetAdjustments,
              aliasName: 'categories__id__budget_adjustments__category_id');

  $$BudgetAdjustmentsTableProcessedTableManager get budgetAdjustmentsRefs {
    final manager =
        $$BudgetAdjustmentsTableTableManager($_db, $_db.budgetAdjustments)
            .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_budgetAdjustmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TxKind, TxKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keywords => $composableBuilder(
      column: $table.keywords, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subs => $composableBuilder(
      column: $table.subs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  Expression<bool> billsRefs(
      Expression<bool> Function($$BillsTableFilterComposer f) f) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> recurringTxsRefs(
      Expression<bool> Function($$RecurringTxsTableFilterComposer f) f) {
    final $$RecurringTxsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableFilterComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> splitsRefs(
      Expression<bool> Function($$SplitsTableFilterComposer f) f) {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableFilterComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> budgetsRefs(
      Expression<bool> Function($$BudgetsTableFilterComposer f) f) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableFilterComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> budgetAdjustmentsRefs(
      Expression<bool> Function($$BudgetAdjustmentsTableFilterComposer f) f) {
    final $$BudgetAdjustmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgetAdjustments,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetAdjustmentsTableFilterComposer(
              $db: $db,
              $table: $db.budgetAdjustments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keywords => $composableBuilder(
      column: $table.keywords, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subs => $composableBuilder(
      column: $table.subs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get subs =>
      $composableBuilder(column: $table.subs, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> billsRefs<T extends Object>(
      Expression<T> Function($$BillsTableAnnotationComposer a) f) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> recurringTxsRefs<T extends Object>(
      Expression<T> Function($$RecurringTxsTableAnnotationComposer a) f) {
    final $$RecurringTxsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableAnnotationComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> splitsRefs<T extends Object>(
      Expression<T> Function($$SplitsTableAnnotationComposer a) f) {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
      Expression<T> Function($$BudgetsTableAnnotationComposer a) f) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.budgets,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BudgetsTableAnnotationComposer(
              $db: $db,
              $table: $db.budgets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> budgetAdjustmentsRefs<T extends Object>(
      Expression<T> Function($$BudgetAdjustmentsTableAnnotationComposer a) f) {
    final $$BudgetAdjustmentsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.budgetAdjustments,
            getReferencedColumn: (t) => t.categoryId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$BudgetAdjustmentsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.budgetAdjustments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool billsRefs,
        bool recurringTxsRefs,
        bool splitsRefs,
        bool transactionsRefs,
        bool budgetsRefs,
        bool budgetAdjustmentsRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<TxKind> kind = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> keywords = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<String> subs = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> archived = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            kind: kind,
            icon: icon,
            keywords: keywords,
            color: color,
            subs: subs,
            sortOrder: sortOrder,
            archived: archived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required TxKind kind,
            Value<String> icon = const Value.absent(),
            Value<String> keywords = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<String> subs = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> archived = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            kind: kind,
            icon: icon,
            keywords: keywords,
            color: color,
            subs: subs,
            sortOrder: sortOrder,
            archived: archived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {billsRefs = false,
              recurringTxsRefs = false,
              splitsRefs = false,
              transactionsRefs = false,
              budgetsRefs = false,
              budgetAdjustmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (billsRefs) db.bills,
                if (recurringTxsRefs) db.recurringTxs,
                if (splitsRefs) db.splits,
                if (transactionsRefs) db.transactions,
                if (budgetsRefs) db.budgets,
                if (budgetAdjustmentsRefs) db.budgetAdjustments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (billsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Bill>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._billsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .billsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (recurringTxsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            RecurringTx>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._recurringTxsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .recurringTxsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (splitsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Split>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._splitsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .splitsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Txn>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (budgetsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            Budget>(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._budgetsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .budgetsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items),
                  if (budgetAdjustmentsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable,
                            BudgetAdjustment>(
                        currentTable: table,
                        referencedTable: $$CategoriesTableReferences
                            ._budgetAdjustmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .budgetAdjustmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function(
        {bool billsRefs,
        bool recurringTxsRefs,
        bool splitsRefs,
        bool transactionsRefs,
        bool budgetsRefs,
        bool budgetAdjustmentsRefs})>;
typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  Value<int> id,
  required String name,
  required int amount,
  Value<int?> categoryId,
  Value<int?> walletId,
  required DateTime nextDue,
  required BillRepeat repeat,
  required int anchorDay,
  Value<int> remindDaysBefore,
  Value<bool> active,
  Value<int?> installmentTotal,
  Value<int> installmentPaid,
  Value<DateTime> createdAt,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> amount,
  Value<int?> categoryId,
  Value<int?> walletId,
  Value<DateTime> nextDue,
  Value<BillRepeat> repeat,
  Value<int> anchorDay,
  Value<int> remindDaysBefore,
  Value<bool> active,
  Value<int?> installmentTotal,
  Value<int> installmentPaid,
  Value<DateTime> createdAt,
});

final class $$BillsTableReferences
    extends BaseReferences<_$AppDatabase, $BillsTable, Bill> {
  $$BillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('bills__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('bills__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<int>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'bills__id__transactions__bill_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.billId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextDue => $composableBuilder(
      column: $table.nextDue, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BillRepeat, BillRepeat, String> get repeat =>
      $composableBuilder(
          column: $table.repeat,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get anchorDay => $composableBuilder(
      column: $table.anchorDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindDaysBefore => $composableBuilder(
      column: $table.remindDaysBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get installmentTotal => $composableBuilder(
      column: $table.installmentTotal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get installmentPaid => $composableBuilder(
      column: $table.installmentPaid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.billId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextDue => $composableBuilder(
      column: $table.nextDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeat => $composableBuilder(
      column: $table.repeat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anchorDay => $composableBuilder(
      column: $table.anchorDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindDaysBefore => $composableBuilder(
      column: $table.remindDaysBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get installmentTotal => $composableBuilder(
      column: $table.installmentTotal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get installmentPaid => $composableBuilder(
      column: $table.installmentPaid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BillRepeat, String> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  GeneratedColumn<int> get anchorDay =>
      $composableBuilder(column: $table.anchorDay, builder: (column) => column);

  GeneratedColumn<int> get remindDaysBefore => $composableBuilder(
      column: $table.remindDaysBefore, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get installmentTotal => $composableBuilder(
      column: $table.installmentTotal, builder: (column) => column);

  GeneratedColumn<int> get installmentPaid => $composableBuilder(
      column: $table.installmentPaid, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.billId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BillsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BillsTable,
    Bill,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableAnnotationComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder,
    (Bill, $$BillsTableReferences),
    Bill,
    PrefetchHooks Function(
        {bool categoryId, bool walletId, bool transactionsRefs})> {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> walletId = const Value.absent(),
            Value<DateTime> nextDue = const Value.absent(),
            Value<BillRepeat> repeat = const Value.absent(),
            Value<int> anchorDay = const Value.absent(),
            Value<int> remindDaysBefore = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<int?> installmentTotal = const Value.absent(),
            Value<int> installmentPaid = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BillsCompanion(
            id: id,
            name: name,
            amount: amount,
            categoryId: categoryId,
            walletId: walletId,
            nextDue: nextDue,
            repeat: repeat,
            anchorDay: anchorDay,
            remindDaysBefore: remindDaysBefore,
            active: active,
            installmentTotal: installmentTotal,
            installmentPaid: installmentPaid,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int amount,
            Value<int?> categoryId = const Value.absent(),
            Value<int?> walletId = const Value.absent(),
            required DateTime nextDue,
            required BillRepeat repeat,
            required int anchorDay,
            Value<int> remindDaysBefore = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<int?> installmentTotal = const Value.absent(),
            Value<int> installmentPaid = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BillsCompanion.insert(
            id: id,
            name: name,
            amount: amount,
            categoryId: categoryId,
            walletId: walletId,
            nextDue: nextDue,
            repeat: repeat,
            anchorDay: anchorDay,
            remindDaysBefore: remindDaysBefore,
            active: active,
            installmentTotal: installmentTotal,
            installmentPaid: installmentPaid,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BillsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false,
              walletId = false,
              transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BillsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable: $$BillsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$BillsTableReferences._walletIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<Bill, $BillsTable, Txn>(
                        currentTable: table,
                        referencedTable:
                            $$BillsTableReferences._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BillsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.billId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BillsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BillsTable,
    Bill,
    $$BillsTableFilterComposer,
    $$BillsTableOrderingComposer,
    $$BillsTableAnnotationComposer,
    $$BillsTableCreateCompanionBuilder,
    $$BillsTableUpdateCompanionBuilder,
    (Bill, $$BillsTableReferences),
    Bill,
    PrefetchHooks Function(
        {bool categoryId, bool walletId, bool transactionsRefs})>;
typedef $$RecurringTxsTableCreateCompanionBuilder = RecurringTxsCompanion
    Function({
  Value<int> id,
  required TxKind kind,
  required int amount,
  required int walletId,
  Value<int?> toWalletId,
  Value<int?> categoryId,
  Value<String> note,
  required BillRepeat repeat,
  required int anchorDay,
  required DateTime nextRun,
  Value<bool> active,
  Value<DateTime> createdAt,
});
typedef $$RecurringTxsTableUpdateCompanionBuilder = RecurringTxsCompanion
    Function({
  Value<int> id,
  Value<TxKind> kind,
  Value<int> amount,
  Value<int> walletId,
  Value<int?> toWalletId,
  Value<int?> categoryId,
  Value<String> note,
  Value<BillRepeat> repeat,
  Value<int> anchorDay,
  Value<DateTime> nextRun,
  Value<bool> active,
  Value<DateTime> createdAt,
});

final class $$RecurringTxsTableReferences
    extends BaseReferences<_$AppDatabase, $RecurringTxsTable, RecurringTx> {
  $$RecurringTxsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('recurring_txs__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<int>('wallet_id')!;

    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WalletsTable _toWalletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('recurring_txs__to_wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get toWalletId {
    final $_column = $_itemColumn<int>('to_wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toWalletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('recurring_txs__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'recurring_txs__id__transactions__recurring_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.recurringId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RecurringTxsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTxsTable> {
  $$RecurringTxsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TxKind, TxKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BillRepeat, BillRepeat, String> get repeat =>
      $composableBuilder(
          column: $table.repeat,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get anchorDay => $composableBuilder(
      column: $table.anchorDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRun => $composableBuilder(
      column: $table.nextRun, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableFilterComposer get toWalletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toWalletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.recurringId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecurringTxsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTxsTable> {
  $$RecurringTxsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeat => $composableBuilder(
      column: $table.repeat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get anchorDay => $composableBuilder(
      column: $table.anchorDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRun => $composableBuilder(
      column: $table.nextRun, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get active => $composableBuilder(
      column: $table.active, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableOrderingComposer get toWalletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toWalletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RecurringTxsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTxsTable> {
  $$RecurringTxsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BillRepeat, String> get repeat =>
      $composableBuilder(column: $table.repeat, builder: (column) => column);

  GeneratedColumn<int> get anchorDay =>
      $composableBuilder(column: $table.anchorDay, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRun =>
      $composableBuilder(column: $table.nextRun, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableAnnotationComposer get toWalletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toWalletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.recurringId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RecurringTxsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringTxsTable,
    RecurringTx,
    $$RecurringTxsTableFilterComposer,
    $$RecurringTxsTableOrderingComposer,
    $$RecurringTxsTableAnnotationComposer,
    $$RecurringTxsTableCreateCompanionBuilder,
    $$RecurringTxsTableUpdateCompanionBuilder,
    (RecurringTx, $$RecurringTxsTableReferences),
    RecurringTx,
    PrefetchHooks Function(
        {bool walletId,
        bool toWalletId,
        bool categoryId,
        bool transactionsRefs})> {
  $$RecurringTxsTableTableManager(_$AppDatabase db, $RecurringTxsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTxsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringTxsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringTxsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<TxKind> kind = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int> walletId = const Value.absent(),
            Value<int?> toWalletId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<BillRepeat> repeat = const Value.absent(),
            Value<int> anchorDay = const Value.absent(),
            Value<DateTime> nextRun = const Value.absent(),
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurringTxsCompanion(
            id: id,
            kind: kind,
            amount: amount,
            walletId: walletId,
            toWalletId: toWalletId,
            categoryId: categoryId,
            note: note,
            repeat: repeat,
            anchorDay: anchorDay,
            nextRun: nextRun,
            active: active,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required TxKind kind,
            required int amount,
            required int walletId,
            Value<int?> toWalletId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            required BillRepeat repeat,
            required int anchorDay,
            required DateTime nextRun,
            Value<bool> active = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              RecurringTxsCompanion.insert(
            id: id,
            kind: kind,
            amount: amount,
            walletId: walletId,
            toWalletId: toWalletId,
            categoryId: categoryId,
            note: note,
            repeat: repeat,
            anchorDay: anchorDay,
            nextRun: nextRun,
            active: active,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$RecurringTxsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {walletId = false,
              toWalletId = false,
              categoryId = false,
              transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable:
                        $$RecurringTxsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$RecurringTxsTableReferences._walletIdTable(db).id,
                  ) as T;
                }
                if (toWalletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toWalletId,
                    referencedTable:
                        $$RecurringTxsTableReferences._toWalletIdTable(db),
                    referencedColumn:
                        $$RecurringTxsTableReferences._toWalletIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$RecurringTxsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$RecurringTxsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<RecurringTx, $RecurringTxsTable,
                            Txn>(
                        currentTable: table,
                        referencedTable: $$RecurringTxsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RecurringTxsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.recurringId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RecurringTxsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurringTxsTable,
    RecurringTx,
    $$RecurringTxsTableFilterComposer,
    $$RecurringTxsTableOrderingComposer,
    $$RecurringTxsTableAnnotationComposer,
    $$RecurringTxsTableCreateCompanionBuilder,
    $$RecurringTxsTableUpdateCompanionBuilder,
    (RecurringTx, $$RecurringTxsTableReferences),
    RecurringTx,
    PrefetchHooks Function(
        {bool walletId,
        bool toWalletId,
        bool categoryId,
        bool transactionsRefs})>;
typedef $$SplitsTableCreateCompanionBuilder = SplitsCompanion Function({
  Value<int> id,
  required String title,
  required SplitMode mode,
  required int total,
  required int walletId,
  Value<int?> categoryId,
  Value<int> taxPermille,
  Value<int> servicePermille,
  Value<int> extraFee,
  Value<int> discount,
  required DateTime occurredAt,
  Value<DateTime> createdAt,
});
typedef $$SplitsTableUpdateCompanionBuilder = SplitsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<SplitMode> mode,
  Value<int> total,
  Value<int> walletId,
  Value<int?> categoryId,
  Value<int> taxPermille,
  Value<int> servicePermille,
  Value<int> extraFee,
  Value<int> discount,
  Value<DateTime> occurredAt,
  Value<DateTime> createdAt,
});

final class $$SplitsTableReferences
    extends BaseReferences<_$AppDatabase, $SplitsTable, Split> {
  $$SplitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('splits__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<int>('wallet_id')!;

    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('splits__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DebtsTable, List<Debt>> _debtsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.debts,
          aliasName: 'splits__id__debts__split_id');

  $$DebtsTableProcessedTableManager get debtsRefs {
    final manager = $$DebtsTableTableManager($_db, $_db.debts)
        .filter((f) => f.splitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'splits__id__transactions__split_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.splitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SplitMembersTable, List<SplitMember>>
      _splitMembersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.splitMembers,
              aliasName: 'splits__id__split_members__split_id');

  $$SplitMembersTableProcessedTableManager get splitMembersRefs {
    final manager = $$SplitMembersTableTableManager($_db, $_db.splitMembers)
        .filter((f) => f.splitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SplitItemsTable, List<SplitItem>>
      _splitItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.splitItems,
              aliasName: 'splits__id__split_items__split_id');

  $$SplitItemsTableProcessedTableManager get splitItemsRefs {
    final manager = $$SplitItemsTableTableManager($_db, $_db.splitItems)
        .filter((f) => f.splitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SplitsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SplitMode, SplitMode, String> get mode =>
      $composableBuilder(
          column: $table.mode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taxPermille => $composableBuilder(
      column: $table.taxPermille, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get servicePermille => $composableBuilder(
      column: $table.servicePermille,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get extraFee => $composableBuilder(
      column: $table.extraFee, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> debtsRefs(
      Expression<bool> Function($$DebtsTableFilterComposer f) f) {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableFilterComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> splitMembersRefs(
      Expression<bool> Function($$SplitMembersTableFilterComposer f) f) {
    final $$SplitMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splitMembers,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitMembersTableFilterComposer(
              $db: $db,
              $table: $db.splitMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> splitItemsRefs(
      Expression<bool> Function($$SplitItemsTableFilterComposer f) f) {
    final $$SplitItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splitItems,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitItemsTableFilterComposer(
              $db: $db,
              $table: $db.splitItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SplitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taxPermille => $composableBuilder(
      column: $table.taxPermille, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get servicePermille => $composableBuilder(
      column: $table.servicePermille,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get extraFee => $composableBuilder(
      column: $table.extraFee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitsTable> {
  $$SplitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SplitMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get taxPermille => $composableBuilder(
      column: $table.taxPermille, builder: (column) => column);

  GeneratedColumn<int> get servicePermille => $composableBuilder(
      column: $table.servicePermille, builder: (column) => column);

  GeneratedColumn<int> get extraFee =>
      $composableBuilder(column: $table.extraFee, builder: (column) => column);

  GeneratedColumn<int> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> debtsRefs<T extends Object>(
      Expression<T> Function($$DebtsTableAnnotationComposer a) f) {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableAnnotationComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> splitMembersRefs<T extends Object>(
      Expression<T> Function($$SplitMembersTableAnnotationComposer a) f) {
    final $$SplitMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splitMembers,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.splitMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> splitItemsRefs<T extends Object>(
      Expression<T> Function($$SplitItemsTableAnnotationComposer a) f) {
    final $$SplitItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splitItems,
        getReferencedColumn: (t) => t.splitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.splitItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SplitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SplitsTable,
    Split,
    $$SplitsTableFilterComposer,
    $$SplitsTableOrderingComposer,
    $$SplitsTableAnnotationComposer,
    $$SplitsTableCreateCompanionBuilder,
    $$SplitsTableUpdateCompanionBuilder,
    (Split, $$SplitsTableReferences),
    Split,
    PrefetchHooks Function(
        {bool walletId,
        bool categoryId,
        bool debtsRefs,
        bool transactionsRefs,
        bool splitMembersRefs,
        bool splitItemsRefs})> {
  $$SplitsTableTableManager(_$AppDatabase db, $SplitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<SplitMode> mode = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<int> walletId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int> taxPermille = const Value.absent(),
            Value<int> servicePermille = const Value.absent(),
            Value<int> extraFee = const Value.absent(),
            Value<int> discount = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SplitsCompanion(
            id: id,
            title: title,
            mode: mode,
            total: total,
            walletId: walletId,
            categoryId: categoryId,
            taxPermille: taxPermille,
            servicePermille: servicePermille,
            extraFee: extraFee,
            discount: discount,
            occurredAt: occurredAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required SplitMode mode,
            required int total,
            required int walletId,
            Value<int?> categoryId = const Value.absent(),
            Value<int> taxPermille = const Value.absent(),
            Value<int> servicePermille = const Value.absent(),
            Value<int> extraFee = const Value.absent(),
            Value<int> discount = const Value.absent(),
            required DateTime occurredAt,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SplitsCompanion.insert(
            id: id,
            title: title,
            mode: mode,
            total: total,
            walletId: walletId,
            categoryId: categoryId,
            taxPermille: taxPermille,
            servicePermille: servicePermille,
            extraFee: extraFee,
            discount: discount,
            occurredAt: occurredAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SplitsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {walletId = false,
              categoryId = false,
              debtsRefs = false,
              transactionsRefs = false,
              splitMembersRefs = false,
              splitItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (debtsRefs) db.debts,
                if (transactionsRefs) db.transactions,
                if (splitMembersRefs) db.splitMembers,
                if (splitItemsRefs) db.splitItems
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable: $$SplitsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$SplitsTableReferences._walletIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$SplitsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$SplitsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (debtsRefs)
                    await $_getPrefetchedData<Split, $SplitsTable, Debt>(
                        currentTable: table,
                        referencedTable:
                            $$SplitsTableReferences._debtsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SplitsTableReferences(db, table, p0).debtsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.splitId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<Split, $SplitsTable, Txn>(
                        currentTable: table,
                        referencedTable:
                            $$SplitsTableReferences._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SplitsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.splitId == item.id),
                        typedResults: items),
                  if (splitMembersRefs)
                    await $_getPrefetchedData<Split, $SplitsTable, SplitMember>(
                        currentTable: table,
                        referencedTable:
                            $$SplitsTableReferences._splitMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SplitsTableReferences(db, table, p0)
                                .splitMembersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.splitId == item.id),
                        typedResults: items),
                  if (splitItemsRefs)
                    await $_getPrefetchedData<Split, $SplitsTable, SplitItem>(
                        currentTable: table,
                        referencedTable:
                            $$SplitsTableReferences._splitItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SplitsTableReferences(db, table, p0)
                                .splitItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.splitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SplitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SplitsTable,
    Split,
    $$SplitsTableFilterComposer,
    $$SplitsTableOrderingComposer,
    $$SplitsTableAnnotationComposer,
    $$SplitsTableCreateCompanionBuilder,
    $$SplitsTableUpdateCompanionBuilder,
    (Split, $$SplitsTableReferences),
    Split,
    PrefetchHooks Function(
        {bool walletId,
        bool categoryId,
        bool debtsRefs,
        bool transactionsRefs,
        bool splitMembersRefs,
        bool splitItemsRefs})>;
typedef $$DebtsTableCreateCompanionBuilder = DebtsCompanion Function({
  Value<int> id,
  required DebtDirection direction,
  required String name,
  required int amount,
  Value<int?> walletId,
  required DateTime occurredAt,
  Value<DateTime?> dueDate,
  Value<String> note,
  Value<int?> splitId,
  Value<DateTime> createdAt,
});
typedef $$DebtsTableUpdateCompanionBuilder = DebtsCompanion Function({
  Value<int> id,
  Value<DebtDirection> direction,
  Value<String> name,
  Value<int> amount,
  Value<int?> walletId,
  Value<DateTime> occurredAt,
  Value<DateTime?> dueDate,
  Value<String> note,
  Value<int?> splitId,
  Value<DateTime> createdAt,
});

final class $$DebtsTableReferences
    extends BaseReferences<_$AppDatabase, $DebtsTable, Debt> {
  $$DebtsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('debts__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<int>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SplitsTable _splitIdTable(_$AppDatabase db) =>
      db.splits.createAlias('debts__split_id__splits__id');

  $$SplitsTableProcessedTableManager? get splitId {
    final $_column = $_itemColumn<int>('split_id');
    if ($_column == null) return null;
    final manager = $$SplitsTableTableManager($_db, $_db.splits)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DebtPaymentsTable, List<DebtPayment>>
      _debtPaymentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.debtPayments,
              aliasName: 'debts__id__debt_payments__debt_id');

  $$DebtPaymentsTableProcessedTableManager get debtPaymentsRefs {
    final manager = $$DebtPaymentsTableTableManager($_db, $_db.debtPayments)
        .filter((f) => f.debtId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_debtPaymentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'debts__id__transactions__debt_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.debtId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SplitMembersTable, List<SplitMember>>
      _splitMembersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.splitMembers,
              aliasName: 'debts__id__split_members__debt_id');

  $$SplitMembersTableProcessedTableManager get splitMembersRefs {
    final manager = $$SplitMembersTableTableManager($_db, $_db.splitMembers)
        .filter((f) => f.debtId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DebtsTableFilterComposer extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DebtDirection, DebtDirection, String>
      get direction => $composableBuilder(
          column: $table.direction,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SplitsTableFilterComposer get splitId {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableFilterComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> debtPaymentsRefs(
      Expression<bool> Function($$DebtPaymentsTableFilterComposer f) f) {
    final $$DebtPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> splitMembersRefs(
      Expression<bool> Function($$SplitMembersTableFilterComposer f) f) {
    final $$SplitMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splitMembers,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitMembersTableFilterComposer(
              $db: $db,
              $table: $db.splitMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DebtsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SplitsTableOrderingComposer get splitId {
    final $$SplitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableOrderingComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DebtsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtsTable> {
  $$DebtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DebtDirection, String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SplitsTableAnnotationComposer get splitId {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> debtPaymentsRefs<T extends Object>(
      Expression<T> Function($$DebtPaymentsTableAnnotationComposer a) f) {
    final $$DebtPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> splitMembersRefs<T extends Object>(
      Expression<T> Function($$SplitMembersTableAnnotationComposer a) f) {
    final $$SplitMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.splitMembers,
        getReferencedColumn: (t) => t.debtId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.splitMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DebtsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DebtsTable,
    Debt,
    $$DebtsTableFilterComposer,
    $$DebtsTableOrderingComposer,
    $$DebtsTableAnnotationComposer,
    $$DebtsTableCreateCompanionBuilder,
    $$DebtsTableUpdateCompanionBuilder,
    (Debt, $$DebtsTableReferences),
    Debt,
    PrefetchHooks Function(
        {bool walletId,
        bool splitId,
        bool debtPaymentsRefs,
        bool transactionsRefs,
        bool splitMembersRefs})> {
  $$DebtsTableTableManager(_$AppDatabase db, $DebtsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DebtDirection> direction = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int?> walletId = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int?> splitId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DebtsCompanion(
            id: id,
            direction: direction,
            name: name,
            amount: amount,
            walletId: walletId,
            occurredAt: occurredAt,
            dueDate: dueDate,
            note: note,
            splitId: splitId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DebtDirection direction,
            required String name,
            required int amount,
            Value<int?> walletId = const Value.absent(),
            required DateTime occurredAt,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int?> splitId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DebtsCompanion.insert(
            id: id,
            direction: direction,
            name: name,
            amount: amount,
            walletId: walletId,
            occurredAt: occurredAt,
            dueDate: dueDate,
            note: note,
            splitId: splitId,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DebtsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {walletId = false,
              splitId = false,
              debtPaymentsRefs = false,
              transactionsRefs = false,
              splitMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (debtPaymentsRefs) db.debtPayments,
                if (transactionsRefs) db.transactions,
                if (splitMembersRefs) db.splitMembers
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable: $$DebtsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$DebtsTableReferences._walletIdTable(db).id,
                  ) as T;
                }
                if (splitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.splitId,
                    referencedTable: $$DebtsTableReferences._splitIdTable(db),
                    referencedColumn:
                        $$DebtsTableReferences._splitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (debtPaymentsRefs)
                    await $_getPrefetchedData<Debt, $DebtsTable, DebtPayment>(
                        currentTable: table,
                        referencedTable:
                            $$DebtsTableReferences._debtPaymentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DebtsTableReferences(db, table, p0)
                                .debtPaymentsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.debtId == item.id),
                        typedResults: items),
                  if (transactionsRefs)
                    await $_getPrefetchedData<Debt, $DebtsTable, Txn>(
                        currentTable: table,
                        referencedTable:
                            $$DebtsTableReferences._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DebtsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.debtId == item.id),
                        typedResults: items),
                  if (splitMembersRefs)
                    await $_getPrefetchedData<Debt, $DebtsTable, SplitMember>(
                        currentTable: table,
                        referencedTable:
                            $$DebtsTableReferences._splitMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DebtsTableReferences(db, table, p0)
                                .splitMembersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.debtId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DebtsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DebtsTable,
    Debt,
    $$DebtsTableFilterComposer,
    $$DebtsTableOrderingComposer,
    $$DebtsTableAnnotationComposer,
    $$DebtsTableCreateCompanionBuilder,
    $$DebtsTableUpdateCompanionBuilder,
    (Debt, $$DebtsTableReferences),
    Debt,
    PrefetchHooks Function(
        {bool walletId,
        bool splitId,
        bool debtPaymentsRefs,
        bool transactionsRefs,
        bool splitMembersRefs})>;
typedef $$DebtPaymentsTableCreateCompanionBuilder = DebtPaymentsCompanion
    Function({
  Value<int> id,
  required int debtId,
  required int amount,
  Value<int?> walletId,
  required DateTime paidAt,
  Value<DateTime> createdAt,
});
typedef $$DebtPaymentsTableUpdateCompanionBuilder = DebtPaymentsCompanion
    Function({
  Value<int> id,
  Value<int> debtId,
  Value<int> amount,
  Value<int?> walletId,
  Value<DateTime> paidAt,
  Value<DateTime> createdAt,
});

final class $$DebtPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $DebtPaymentsTable, DebtPayment> {
  $$DebtPaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DebtsTable _debtIdTable(_$AppDatabase db) =>
      db.debts.createAlias('debt_payments__debt_id__debts__id');

  $$DebtsTableProcessedTableManager get debtId {
    final $_column = $_itemColumn<int>('debt_id')!;

    final manager = $$DebtsTableTableManager($_db, $_db.debts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('debt_payments__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<int>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$TransactionsTable, List<Txn>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'debt_payments__id__transactions__debt_payment_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.debtPaymentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DebtPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $DebtPaymentsTable> {
  $$DebtPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$DebtsTableFilterComposer get debtId {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableFilterComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.debtPaymentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DebtPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtPaymentsTable> {
  $$DebtPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
      column: $table.paidAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$DebtsTableOrderingComposer get debtId {
    final $$DebtsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableOrderingComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DebtPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtPaymentsTable> {
  $$DebtPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DebtsTableAnnotationComposer get debtId {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableAnnotationComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.debtPaymentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DebtPaymentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DebtPaymentsTable,
    DebtPayment,
    $$DebtPaymentsTableFilterComposer,
    $$DebtPaymentsTableOrderingComposer,
    $$DebtPaymentsTableAnnotationComposer,
    $$DebtPaymentsTableCreateCompanionBuilder,
    $$DebtPaymentsTableUpdateCompanionBuilder,
    (DebtPayment, $$DebtPaymentsTableReferences),
    DebtPayment,
    PrefetchHooks Function(
        {bool debtId, bool walletId, bool transactionsRefs})> {
  $$DebtPaymentsTableTableManager(_$AppDatabase db, $DebtPaymentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> debtId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int?> walletId = const Value.absent(),
            Value<DateTime> paidAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DebtPaymentsCompanion(
            id: id,
            debtId: debtId,
            amount: amount,
            walletId: walletId,
            paidAt: paidAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int debtId,
            required int amount,
            Value<int?> walletId = const Value.absent(),
            required DateTime paidAt,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DebtPaymentsCompanion.insert(
            id: id,
            debtId: debtId,
            amount: amount,
            walletId: walletId,
            paidAt: paidAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DebtPaymentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {debtId = false, walletId = false, transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (debtId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.debtId,
                    referencedTable:
                        $$DebtPaymentsTableReferences._debtIdTable(db),
                    referencedColumn:
                        $$DebtPaymentsTableReferences._debtIdTable(db).id,
                  ) as T;
                }
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable:
                        $$DebtPaymentsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$DebtPaymentsTableReferences._walletIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<DebtPayment, $DebtPaymentsTable,
                            Txn>(
                        currentTable: table,
                        referencedTable: $$DebtPaymentsTableReferences
                            ._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DebtPaymentsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.debtPaymentId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DebtPaymentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DebtPaymentsTable,
    DebtPayment,
    $$DebtPaymentsTableFilterComposer,
    $$DebtPaymentsTableOrderingComposer,
    $$DebtPaymentsTableAnnotationComposer,
    $$DebtPaymentsTableCreateCompanionBuilder,
    $$DebtPaymentsTableUpdateCompanionBuilder,
    (DebtPayment, $$DebtPaymentsTableReferences),
    DebtPayment,
    PrefetchHooks Function(
        {bool debtId, bool walletId, bool transactionsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required TxKind kind,
  required int amount,
  required int walletId,
  Value<int?> toWalletId,
  Value<int?> categoryId,
  Value<String> note,
  Value<String> sub,
  Value<int?> billId,
  Value<DateTime?> billDue,
  Value<int?> recurringId,
  Value<int?> debtId,
  Value<int?> debtPaymentId,
  Value<int?> splitId,
  required DateTime occurredAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<TxKind> kind,
  Value<int> amount,
  Value<int> walletId,
  Value<int?> toWalletId,
  Value<int?> categoryId,
  Value<String> note,
  Value<String> sub,
  Value<int?> billId,
  Value<DateTime?> billDue,
  Value<int?> recurringId,
  Value<int?> debtId,
  Value<int?> debtPaymentId,
  Value<int?> splitId,
  Value<DateTime> occurredAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Txn> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('transactions__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<int>('wallet_id')!;

    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WalletsTable _toWalletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('transactions__to_wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get toWalletId {
    final $_column = $_itemColumn<int>('to_wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toWalletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('transactions__bill_id__bills__id');

  $$BillsTableProcessedTableManager? get billId {
    final $_column = $_itemColumn<int>('bill_id');
    if ($_column == null) return null;
    final manager = $$BillsTableTableManager($_db, $_db.bills)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $RecurringTxsTable _recurringIdTable(_$AppDatabase db) =>
      db.recurringTxs
          .createAlias('transactions__recurring_id__recurring_txs__id');

  $$RecurringTxsTableProcessedTableManager? get recurringId {
    final $_column = $_itemColumn<int>('recurring_id');
    if ($_column == null) return null;
    final manager = $$RecurringTxsTableTableManager($_db, $_db.recurringTxs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DebtsTable _debtIdTable(_$AppDatabase db) =>
      db.debts.createAlias('transactions__debt_id__debts__id');

  $$DebtsTableProcessedTableManager? get debtId {
    final $_column = $_itemColumn<int>('debt_id');
    if ($_column == null) return null;
    final manager = $$DebtsTableTableManager($_db, $_db.debts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DebtPaymentsTable _debtPaymentIdTable(_$AppDatabase db) =>
      db.debtPayments
          .createAlias('transactions__debt_payment_id__debt_payments__id');

  $$DebtPaymentsTableProcessedTableManager? get debtPaymentId {
    final $_column = $_itemColumn<int>('debt_payment_id');
    if ($_column == null) return null;
    final manager = $$DebtPaymentsTableTableManager($_db, $_db.debtPayments)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtPaymentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SplitsTable _splitIdTable(_$AppDatabase db) =>
      db.splits.createAlias('transactions__split_id__splits__id');

  $$SplitsTableProcessedTableManager? get splitId {
    final $_column = $_itemColumn<int>('split_id');
    if ($_column == null) return null;
    final manager = $$SplitsTableTableManager($_db, $_db.splits)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TxKind, TxKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sub => $composableBuilder(
      column: $table.sub, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get billDue => $composableBuilder(
      column: $table.billDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableFilterComposer get toWalletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toWalletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableFilterComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecurringTxsTableFilterComposer get recurringId {
    final $$RecurringTxsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recurringId,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableFilterComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtsTableFilterComposer get debtId {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableFilterComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtPaymentsTableFilterComposer get debtPaymentId {
    final $$DebtPaymentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtPaymentId,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableFilterComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SplitsTableFilterComposer get splitId {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableFilterComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sub => $composableBuilder(
      column: $table.sub, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get billDue => $composableBuilder(
      column: $table.billDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableOrderingComposer get toWalletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toWalletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableOrderingComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecurringTxsTableOrderingComposer get recurringId {
    final $$RecurringTxsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recurringId,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableOrderingComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtsTableOrderingComposer get debtId {
    final $$DebtsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableOrderingComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtPaymentsTableOrderingComposer get debtPaymentId {
    final $$DebtPaymentsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtPaymentId,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableOrderingComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SplitsTableOrderingComposer get splitId {
    final $$SplitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableOrderingComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TxKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get sub =>
      $composableBuilder(column: $table.sub, builder: (column) => column);

  GeneratedColumn<DateTime> get billDue =>
      $composableBuilder(column: $table.billDue, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableAnnotationComposer get toWalletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.toWalletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.billId,
        referencedTable: $db.bills,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BillsTableAnnotationComposer(
              $db: $db,
              $table: $db.bills,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$RecurringTxsTableAnnotationComposer get recurringId {
    final $$RecurringTxsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.recurringId,
        referencedTable: $db.recurringTxs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RecurringTxsTableAnnotationComposer(
              $db: $db,
              $table: $db.recurringTxs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtsTableAnnotationComposer get debtId {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableAnnotationComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtPaymentsTableAnnotationComposer get debtPaymentId {
    final $$DebtPaymentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtPaymentId,
        referencedTable: $db.debtPayments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtPaymentsTableAnnotationComposer(
              $db: $db,
              $table: $db.debtPayments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SplitsTableAnnotationComposer get splitId {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Txn,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Txn, $$TransactionsTableReferences),
    Txn,
    PrefetchHooks Function(
        {bool walletId,
        bool toWalletId,
        bool categoryId,
        bool billId,
        bool recurringId,
        bool debtId,
        bool debtPaymentId,
        bool splitId})> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<TxKind> kind = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int> walletId = const Value.absent(),
            Value<int?> toWalletId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> sub = const Value.absent(),
            Value<int?> billId = const Value.absent(),
            Value<DateTime?> billDue = const Value.absent(),
            Value<int?> recurringId = const Value.absent(),
            Value<int?> debtId = const Value.absent(),
            Value<int?> debtPaymentId = const Value.absent(),
            Value<int?> splitId = const Value.absent(),
            Value<DateTime> occurredAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            kind: kind,
            amount: amount,
            walletId: walletId,
            toWalletId: toWalletId,
            categoryId: categoryId,
            note: note,
            sub: sub,
            billId: billId,
            billDue: billDue,
            recurringId: recurringId,
            debtId: debtId,
            debtPaymentId: debtPaymentId,
            splitId: splitId,
            occurredAt: occurredAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required TxKind kind,
            required int amount,
            required int walletId,
            Value<int?> toWalletId = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> sub = const Value.absent(),
            Value<int?> billId = const Value.absent(),
            Value<DateTime?> billDue = const Value.absent(),
            Value<int?> recurringId = const Value.absent(),
            Value<int?> debtId = const Value.absent(),
            Value<int?> debtPaymentId = const Value.absent(),
            Value<int?> splitId = const Value.absent(),
            required DateTime occurredAt,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            kind: kind,
            amount: amount,
            walletId: walletId,
            toWalletId: toWalletId,
            categoryId: categoryId,
            note: note,
            sub: sub,
            billId: billId,
            billDue: billDue,
            recurringId: recurringId,
            debtId: debtId,
            debtPaymentId: debtPaymentId,
            splitId: splitId,
            occurredAt: occurredAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {walletId = false,
              toWalletId = false,
              categoryId = false,
              billId = false,
              recurringId = false,
              debtId = false,
              debtPaymentId = false,
              splitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable:
                        $$TransactionsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._walletIdTable(db).id,
                  ) as T;
                }
                if (toWalletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.toWalletId,
                    referencedTable:
                        $$TransactionsTableReferences._toWalletIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._toWalletIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$TransactionsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }
                if (billId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.billId,
                    referencedTable:
                        $$TransactionsTableReferences._billIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._billIdTable(db).id,
                  ) as T;
                }
                if (recurringId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.recurringId,
                    referencedTable:
                        $$TransactionsTableReferences._recurringIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._recurringIdTable(db).id,
                  ) as T;
                }
                if (debtId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.debtId,
                    referencedTable:
                        $$TransactionsTableReferences._debtIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._debtIdTable(db).id,
                  ) as T;
                }
                if (debtPaymentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.debtPaymentId,
                    referencedTable:
                        $$TransactionsTableReferences._debtPaymentIdTable(db),
                    referencedColumn: $$TransactionsTableReferences
                        ._debtPaymentIdTable(db)
                        .id,
                  ) as T;
                }
                if (splitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.splitId,
                    referencedTable:
                        $$TransactionsTableReferences._splitIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._splitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    Txn,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Txn, $$TransactionsTableReferences),
    Txn,
    PrefetchHooks Function(
        {bool walletId,
        bool toWalletId,
        bool categoryId,
        bool billId,
        bool recurringId,
        bool debtId,
        bool debtPaymentId,
        bool splitId})>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  required int limitAmount,
  Value<DateTime> fromMonth,
  Value<DateTime> createdAt,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int?> categoryId,
  Value<int> limitAmount,
  Value<DateTime> fromMonth,
  Value<DateTime> createdAt,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get limitAmount => $composableBuilder(
      column: $table.limitAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fromMonth => $composableBuilder(
      column: $table.fromMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get limitAmount => $composableBuilder(
      column: $table.limitAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fromMonth => $composableBuilder(
      column: $table.fromMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get limitAmount => $composableBuilder(
      column: $table.limitAmount, builder: (column) => column);

  GeneratedColumn<DateTime> get fromMonth =>
      $composableBuilder(column: $table.fromMonth, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, $$BudgetsTableReferences),
    Budget,
    PrefetchHooks Function({bool categoryId})> {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int> limitAmount = const Value.absent(),
            Value<DateTime> fromMonth = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BudgetsCompanion(
            id: id,
            categoryId: categoryId,
            limitAmount: limitAmount,
            fromMonth: fromMonth,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            required int limitAmount,
            Value<DateTime> fromMonth = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            id: id,
            categoryId: categoryId,
            limitAmount: limitAmount,
            fromMonth: fromMonth,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BudgetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BudgetsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$BudgetsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, $$BudgetsTableReferences),
    Budget,
    PrefetchHooks Function({bool categoryId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> emoji,
  required int target,
  Value<DateTime?> dueDate,
  Value<String> note,
  Value<DateTime?> achievedAt,
  Value<bool> archived,
  Value<bool> remind,
  Value<int> remindWeekday,
  Value<int> remindHour,
  Value<DateTime> createdAt,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> emoji,
  Value<int> target,
  Value<DateTime?> dueDate,
  Value<String> note,
  Value<DateTime?> achievedAt,
  Value<bool> archived,
  Value<bool> remind,
  Value<int> remindWeekday,
  Value<int> remindHour,
  Value<DateTime> createdAt,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GoalDepositsTable, List<GoalDeposit>>
      _goalDepositsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.goalDeposits,
              aliasName: 'goals__id__goal_deposits__goal_id');

  $$GoalDepositsTableProcessedTableManager get goalDepositsRefs {
    final manager = $$GoalDepositsTableTableManager($_db, $_db.goalDeposits)
        .filter((f) => f.goalId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalDepositsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get achievedAt => $composableBuilder(
      column: $table.achievedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get remind => $composableBuilder(
      column: $table.remind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindWeekday => $composableBuilder(
      column: $table.remindWeekday, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindHour => $composableBuilder(
      column: $table.remindHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> goalDepositsRefs(
      Expression<bool> Function($$GoalDepositsTableFilterComposer f) f) {
    final $$GoalDepositsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goalDeposits,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalDepositsTableFilterComposer(
              $db: $db,
              $table: $db.goalDeposits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get target => $composableBuilder(
      column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get achievedAt => $composableBuilder(
      column: $table.achievedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get remind => $composableBuilder(
      column: $table.remind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindWeekday => $composableBuilder(
      column: $table.remindWeekday,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindHour => $composableBuilder(
      column: $table.remindHour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get target =>
      $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get achievedAt => $composableBuilder(
      column: $table.achievedAt, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get remind =>
      $composableBuilder(column: $table.remind, builder: (column) => column);

  GeneratedColumn<int> get remindWeekday => $composableBuilder(
      column: $table.remindWeekday, builder: (column) => column);

  GeneratedColumn<int> get remindHour => $composableBuilder(
      column: $table.remindHour, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> goalDepositsRefs<T extends Object>(
      Expression<T> Function($$GoalDepositsTableAnnotationComposer a) f) {
    final $$GoalDepositsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goalDeposits,
        getReferencedColumn: (t) => t.goalId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalDepositsTableAnnotationComposer(
              $db: $db,
              $table: $db.goalDeposits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool goalDepositsRefs})> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<int> target = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime?> achievedAt = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> remind = const Value.absent(),
            Value<int> remindWeekday = const Value.absent(),
            Value<int> remindHour = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            name: name,
            emoji: emoji,
            target: target,
            dueDate: dueDate,
            note: note,
            achievedAt: achievedAt,
            archived: archived,
            remind: remind,
            remindWeekday: remindWeekday,
            remindHour: remindHour,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String> emoji = const Value.absent(),
            required int target,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime?> achievedAt = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> remind = const Value.absent(),
            Value<int> remindWeekday = const Value.absent(),
            Value<int> remindHour = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GoalsCompanion.insert(
            id: id,
            name: name,
            emoji: emoji,
            target: target,
            dueDate: dueDate,
            note: note,
            achievedAt: achievedAt,
            archived: archived,
            remind: remind,
            remindWeekday: remindWeekday,
            remindHour: remindHour,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({goalDepositsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (goalDepositsRefs) db.goalDeposits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (goalDepositsRefs)
                    await $_getPrefetchedData<Goal, $GoalsTable, GoalDeposit>(
                        currentTable: table,
                        referencedTable:
                            $$GoalsTableReferences._goalDepositsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$GoalsTableReferences(db, table, p0)
                                .goalDepositsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.goalId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool goalDepositsRefs})>;
typedef $$GoalDepositsTableCreateCompanionBuilder = GoalDepositsCompanion
    Function({
  Value<int> id,
  required int goalId,
  required int amount,
  Value<int?> walletId,
  required DateTime at,
  Value<DateTime> createdAt,
});
typedef $$GoalDepositsTableUpdateCompanionBuilder = GoalDepositsCompanion
    Function({
  Value<int> id,
  Value<int> goalId,
  Value<int> amount,
  Value<int?> walletId,
  Value<DateTime> at,
  Value<DateTime> createdAt,
});

final class $$GoalDepositsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalDepositsTable, GoalDeposit> {
  $$GoalDepositsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('goal_deposits__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<int>('goal_id')!;

    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias('goal_deposits__wallet_id__wallets__id');

  $$WalletsTableProcessedTableManager? get walletId {
    final $_column = $_itemColumn<int>('wallet_id');
    if ($_column == null) return null;
    final manager = $$WalletsTableTableManager($_db, $_db.wallets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalDepositsTableFilterComposer
    extends Composer<_$AppDatabase, $GoalDepositsTable> {
  $$GoalDepositsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableFilterComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalDepositsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalDepositsTable> {
  $$GoalDepositsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(
      column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableOrderingComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableOrderingComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalDepositsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalDepositsTable> {
  $$GoalDepositsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.goalId,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.walletId,
        referencedTable: $db.wallets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WalletsTableAnnotationComposer(
              $db: $db,
              $table: $db.wallets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalDepositsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalDepositsTable,
    GoalDeposit,
    $$GoalDepositsTableFilterComposer,
    $$GoalDepositsTableOrderingComposer,
    $$GoalDepositsTableAnnotationComposer,
    $$GoalDepositsTableCreateCompanionBuilder,
    $$GoalDepositsTableUpdateCompanionBuilder,
    (GoalDeposit, $$GoalDepositsTableReferences),
    GoalDeposit,
    PrefetchHooks Function({bool goalId, bool walletId})> {
  $$GoalDepositsTableTableManager(_$AppDatabase db, $GoalDepositsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalDepositsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalDepositsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalDepositsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> goalId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<int?> walletId = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GoalDepositsCompanion(
            id: id,
            goalId: goalId,
            amount: amount,
            walletId: walletId,
            at: at,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int goalId,
            required int amount,
            Value<int?> walletId = const Value.absent(),
            required DateTime at,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GoalDepositsCompanion.insert(
            id: id,
            goalId: goalId,
            amount: amount,
            walletId: walletId,
            at: at,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GoalDepositsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({goalId = false, walletId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (goalId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.goalId,
                    referencedTable:
                        $$GoalDepositsTableReferences._goalIdTable(db),
                    referencedColumn:
                        $$GoalDepositsTableReferences._goalIdTable(db).id,
                  ) as T;
                }
                if (walletId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.walletId,
                    referencedTable:
                        $$GoalDepositsTableReferences._walletIdTable(db),
                    referencedColumn:
                        $$GoalDepositsTableReferences._walletIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GoalDepositsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalDepositsTable,
    GoalDeposit,
    $$GoalDepositsTableFilterComposer,
    $$GoalDepositsTableOrderingComposer,
    $$GoalDepositsTableAnnotationComposer,
    $$GoalDepositsTableCreateCompanionBuilder,
    $$GoalDepositsTableUpdateCompanionBuilder,
    (GoalDeposit, $$GoalDepositsTableReferences),
    GoalDeposit,
    PrefetchHooks Function({bool goalId, bool walletId})>;
typedef $$SplitMembersTableCreateCompanionBuilder = SplitMembersCompanion
    Function({
  Value<int> id,
  required int splitId,
  required String name,
  Value<bool> isMe,
  Value<bool> payer,
  required int share,
  required int position,
  Value<int?> debtId,
});
typedef $$SplitMembersTableUpdateCompanionBuilder = SplitMembersCompanion
    Function({
  Value<int> id,
  Value<int> splitId,
  Value<String> name,
  Value<bool> isMe,
  Value<bool> payer,
  Value<int> share,
  Value<int> position,
  Value<int?> debtId,
});

final class $$SplitMembersTableReferences
    extends BaseReferences<_$AppDatabase, $SplitMembersTable, SplitMember> {
  $$SplitMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SplitsTable _splitIdTable(_$AppDatabase db) =>
      db.splits.createAlias('split_members__split_id__splits__id');

  $$SplitsTableProcessedTableManager get splitId {
    final $_column = $_itemColumn<int>('split_id')!;

    final manager = $$SplitsTableTableManager($_db, $_db.splits)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $DebtsTable _debtIdTable(_$AppDatabase db) =>
      db.debts.createAlias('split_members__debt_id__debts__id');

  $$DebtsTableProcessedTableManager? get debtId {
    final $_column = $_itemColumn<int>('debt_id');
    if ($_column == null) return null;
    final manager = $$DebtsTableTableManager($_db, $_db.debts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SplitMembersTableFilterComposer
    extends Composer<_$AppDatabase, $SplitMembersTable> {
  $$SplitMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMe => $composableBuilder(
      column: $table.isMe, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get payer => $composableBuilder(
      column: $table.payer, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get share => $composableBuilder(
      column: $table.share, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$SplitsTableFilterComposer get splitId {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableFilterComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtsTableFilterComposer get debtId {
    final $$DebtsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableFilterComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitMembersTable> {
  $$SplitMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMe => $composableBuilder(
      column: $table.isMe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get payer => $composableBuilder(
      column: $table.payer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get share => $composableBuilder(
      column: $table.share, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$SplitsTableOrderingComposer get splitId {
    final $$SplitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableOrderingComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtsTableOrderingComposer get debtId {
    final $$DebtsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableOrderingComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitMembersTable> {
  $$SplitMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);

  GeneratedColumn<bool> get payer =>
      $composableBuilder(column: $table.payer, builder: (column) => column);

  GeneratedColumn<int> get share =>
      $composableBuilder(column: $table.share, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SplitsTableAnnotationComposer get splitId {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$DebtsTableAnnotationComposer get debtId {
    final $$DebtsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.debtId,
        referencedTable: $db.debts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DebtsTableAnnotationComposer(
              $db: $db,
              $table: $db.debts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitMembersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SplitMembersTable,
    SplitMember,
    $$SplitMembersTableFilterComposer,
    $$SplitMembersTableOrderingComposer,
    $$SplitMembersTableAnnotationComposer,
    $$SplitMembersTableCreateCompanionBuilder,
    $$SplitMembersTableUpdateCompanionBuilder,
    (SplitMember, $$SplitMembersTableReferences),
    SplitMember,
    PrefetchHooks Function({bool splitId, bool debtId})> {
  $$SplitMembersTableTableManager(_$AppDatabase db, $SplitMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> splitId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<bool> isMe = const Value.absent(),
            Value<bool> payer = const Value.absent(),
            Value<int> share = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int?> debtId = const Value.absent(),
          }) =>
              SplitMembersCompanion(
            id: id,
            splitId: splitId,
            name: name,
            isMe: isMe,
            payer: payer,
            share: share,
            position: position,
            debtId: debtId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int splitId,
            required String name,
            Value<bool> isMe = const Value.absent(),
            Value<bool> payer = const Value.absent(),
            required int share,
            required int position,
            Value<int?> debtId = const Value.absent(),
          }) =>
              SplitMembersCompanion.insert(
            id: id,
            splitId: splitId,
            name: name,
            isMe: isMe,
            payer: payer,
            share: share,
            position: position,
            debtId: debtId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SplitMembersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({splitId = false, debtId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (splitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.splitId,
                    referencedTable:
                        $$SplitMembersTableReferences._splitIdTable(db),
                    referencedColumn:
                        $$SplitMembersTableReferences._splitIdTable(db).id,
                  ) as T;
                }
                if (debtId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.debtId,
                    referencedTable:
                        $$SplitMembersTableReferences._debtIdTable(db),
                    referencedColumn:
                        $$SplitMembersTableReferences._debtIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SplitMembersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SplitMembersTable,
    SplitMember,
    $$SplitMembersTableFilterComposer,
    $$SplitMembersTableOrderingComposer,
    $$SplitMembersTableAnnotationComposer,
    $$SplitMembersTableCreateCompanionBuilder,
    $$SplitMembersTableUpdateCompanionBuilder,
    (SplitMember, $$SplitMembersTableReferences),
    SplitMember,
    PrefetchHooks Function({bool splitId, bool debtId})>;
typedef $$SplitItemsTableCreateCompanionBuilder = SplitItemsCompanion Function({
  Value<int> id,
  required int splitId,
  required String name,
  required int price,
  required String who,
  required int position,
});
typedef $$SplitItemsTableUpdateCompanionBuilder = SplitItemsCompanion Function({
  Value<int> id,
  Value<int> splitId,
  Value<String> name,
  Value<int> price,
  Value<String> who,
  Value<int> position,
});

final class $$SplitItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SplitItemsTable, SplitItem> {
  $$SplitItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SplitsTable _splitIdTable(_$AppDatabase db) =>
      db.splits.createAlias('split_items__split_id__splits__id');

  $$SplitsTableProcessedTableManager get splitId {
    final $_column = $_itemColumn<int>('split_id')!;

    final manager = $$SplitsTableTableManager($_db, $_db.splits)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_splitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SplitItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitItemsTable> {
  $$SplitItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get who => $composableBuilder(
      column: $table.who, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$SplitsTableFilterComposer get splitId {
    final $$SplitsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableFilterComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitItemsTable> {
  $$SplitItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get who => $composableBuilder(
      column: $table.who, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$SplitsTableOrderingComposer get splitId {
    final $$SplitsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableOrderingComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitItemsTable> {
  $$SplitItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get who =>
      $composableBuilder(column: $table.who, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SplitsTableAnnotationComposer get splitId {
    final $$SplitsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.splitId,
        referencedTable: $db.splits,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SplitsTableAnnotationComposer(
              $db: $db,
              $table: $db.splits,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SplitItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SplitItemsTable,
    SplitItem,
    $$SplitItemsTableFilterComposer,
    $$SplitItemsTableOrderingComposer,
    $$SplitItemsTableAnnotationComposer,
    $$SplitItemsTableCreateCompanionBuilder,
    $$SplitItemsTableUpdateCompanionBuilder,
    (SplitItem, $$SplitItemsTableReferences),
    SplitItem,
    PrefetchHooks Function({bool splitId})> {
  $$SplitItemsTableTableManager(_$AppDatabase db, $SplitItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> splitId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> price = const Value.absent(),
            Value<String> who = const Value.absent(),
            Value<int> position = const Value.absent(),
          }) =>
              SplitItemsCompanion(
            id: id,
            splitId: splitId,
            name: name,
            price: price,
            who: who,
            position: position,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int splitId,
            required String name,
            required int price,
            required String who,
            required int position,
          }) =>
              SplitItemsCompanion.insert(
            id: id,
            splitId: splitId,
            name: name,
            price: price,
            who: who,
            position: position,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SplitItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({splitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (splitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.splitId,
                    referencedTable:
                        $$SplitItemsTableReferences._splitIdTable(db),
                    referencedColumn:
                        $$SplitItemsTableReferences._splitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SplitItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SplitItemsTable,
    SplitItem,
    $$SplitItemsTableFilterComposer,
    $$SplitItemsTableOrderingComposer,
    $$SplitItemsTableAnnotationComposer,
    $$SplitItemsTableCreateCompanionBuilder,
    $$SplitItemsTableUpdateCompanionBuilder,
    (SplitItem, $$SplitItemsTableReferences),
    SplitItem,
    PrefetchHooks Function({bool splitId})>;
typedef $$BudgetAdjustmentsTableCreateCompanionBuilder
    = BudgetAdjustmentsCompanion Function({
  Value<int> id,
  required DateTime month,
  Value<int?> categoryId,
  required int amount,
  required BudgetAdjustReason reason,
  Value<DateTime> createdAt,
});
typedef $$BudgetAdjustmentsTableUpdateCompanionBuilder
    = BudgetAdjustmentsCompanion Function({
  Value<int> id,
  Value<DateTime> month,
  Value<int?> categoryId,
  Value<int> amount,
  Value<BudgetAdjustReason> reason,
  Value<DateTime> createdAt,
});

final class $$BudgetAdjustmentsTableReferences extends BaseReferences<
    _$AppDatabase, $BudgetAdjustmentsTable, BudgetAdjustment> {
  $$BudgetAdjustmentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias('budget_adjustments__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetAdjustmentsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetAdjustmentsTable> {
  $$BudgetAdjustmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BudgetAdjustReason, BudgetAdjustReason, String>
      get reason => $composableBuilder(
          column: $table.reason,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetAdjustmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetAdjustmentsTable> {
  $$BudgetAdjustmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetAdjustmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetAdjustmentsTable> {
  $$BudgetAdjustmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BudgetAdjustReason, String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BudgetAdjustmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BudgetAdjustmentsTable,
    BudgetAdjustment,
    $$BudgetAdjustmentsTableFilterComposer,
    $$BudgetAdjustmentsTableOrderingComposer,
    $$BudgetAdjustmentsTableAnnotationComposer,
    $$BudgetAdjustmentsTableCreateCompanionBuilder,
    $$BudgetAdjustmentsTableUpdateCompanionBuilder,
    (BudgetAdjustment, $$BudgetAdjustmentsTableReferences),
    BudgetAdjustment,
    PrefetchHooks Function({bool categoryId})> {
  $$BudgetAdjustmentsTableTableManager(
      _$AppDatabase db, $BudgetAdjustmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetAdjustmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetAdjustmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetAdjustmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> month = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int> amount = const Value.absent(),
            Value<BudgetAdjustReason> reason = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BudgetAdjustmentsCompanion(
            id: id,
            month: month,
            categoryId: categoryId,
            amount: amount,
            reason: reason,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime month,
            Value<int?> categoryId = const Value.absent(),
            required int amount,
            required BudgetAdjustReason reason,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BudgetAdjustmentsCompanion.insert(
            id: id,
            month: month,
            categoryId: categoryId,
            amount: amount,
            reason: reason,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BudgetAdjustmentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$BudgetAdjustmentsTableReferences._categoryIdTable(db),
                    referencedColumn: $$BudgetAdjustmentsTableReferences
                        ._categoryIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BudgetAdjustmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BudgetAdjustmentsTable,
    BudgetAdjustment,
    $$BudgetAdjustmentsTableFilterComposer,
    $$BudgetAdjustmentsTableOrderingComposer,
    $$BudgetAdjustmentsTableAnnotationComposer,
    $$BudgetAdjustmentsTableCreateCompanionBuilder,
    $$BudgetAdjustmentsTableUpdateCompanionBuilder,
    (BudgetAdjustment, $$BudgetAdjustmentsTableReferences),
    BudgetAdjustment,
    PrefetchHooks Function({bool categoryId})>;
typedef $$NetItemsTableCreateCompanionBuilder = NetItemsCompanion Function({
  Value<int> id,
  required NetItemKind kind,
  required String name,
  Value<int> value,
  Value<int?> milligrams,
  Value<int?> pricePerGram,
  required DateTime updatedAt,
  Value<DateTime> createdAt,
});
typedef $$NetItemsTableUpdateCompanionBuilder = NetItemsCompanion Function({
  Value<int> id,
  Value<NetItemKind> kind,
  Value<String> name,
  Value<int> value,
  Value<int?> milligrams,
  Value<int?> pricePerGram,
  Value<DateTime> updatedAt,
  Value<DateTime> createdAt,
});

class $$NetItemsTableFilterComposer
    extends Composer<_$AppDatabase, $NetItemsTable> {
  $$NetItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<NetItemKind, NetItemKind, String> get kind =>
      $composableBuilder(
          column: $table.kind,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get milligrams => $composableBuilder(
      column: $table.milligrams, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pricePerGram => $composableBuilder(
      column: $table.pricePerGram, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$NetItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $NetItemsTable> {
  $$NetItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get milligrams => $composableBuilder(
      column: $table.milligrams, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pricePerGram => $composableBuilder(
      column: $table.pricePerGram,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NetItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NetItemsTable> {
  $$NetItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NetItemKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get milligrams => $composableBuilder(
      column: $table.milligrams, builder: (column) => column);

  GeneratedColumn<int> get pricePerGram => $composableBuilder(
      column: $table.pricePerGram, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NetItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NetItemsTable,
    NetItem,
    $$NetItemsTableFilterComposer,
    $$NetItemsTableOrderingComposer,
    $$NetItemsTableAnnotationComposer,
    $$NetItemsTableCreateCompanionBuilder,
    $$NetItemsTableUpdateCompanionBuilder,
    (NetItem, BaseReferences<_$AppDatabase, $NetItemsTable, NetItem>),
    NetItem,
    PrefetchHooks Function()> {
  $$NetItemsTableTableManager(_$AppDatabase db, $NetItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NetItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NetItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NetItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<NetItemKind> kind = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> value = const Value.absent(),
            Value<int?> milligrams = const Value.absent(),
            Value<int?> pricePerGram = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NetItemsCompanion(
            id: id,
            kind: kind,
            name: name,
            value: value,
            milligrams: milligrams,
            pricePerGram: pricePerGram,
            updatedAt: updatedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required NetItemKind kind,
            required String name,
            Value<int> value = const Value.absent(),
            Value<int?> milligrams = const Value.absent(),
            Value<int?> pricePerGram = const Value.absent(),
            required DateTime updatedAt,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NetItemsCompanion.insert(
            id: id,
            kind: kind,
            name: name,
            value: value,
            milligrams: milligrams,
            pricePerGram: pricePerGram,
            updatedAt: updatedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NetItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NetItemsTable,
    NetItem,
    $$NetItemsTableFilterComposer,
    $$NetItemsTableOrderingComposer,
    $$NetItemsTableAnnotationComposer,
    $$NetItemsTableCreateCompanionBuilder,
    $$NetItemsTableUpdateCompanionBuilder,
    (NetItem, BaseReferences<_$AppDatabase, $NetItemsTable, NetItem>),
    NetItem,
    PrefetchHooks Function()>;
typedef $$NetSnapshotsTableCreateCompanionBuilder = NetSnapshotsCompanion
    Function({
  required DateTime month,
  required int assets,
  required int liabilities,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$NetSnapshotsTableUpdateCompanionBuilder = NetSnapshotsCompanion
    Function({
  Value<DateTime> month,
  Value<int> assets,
  Value<int> liabilities,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$NetSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $NetSnapshotsTable> {
  $$NetSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get assets => $composableBuilder(
      column: $table.assets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get liabilities => $composableBuilder(
      column: $table.liabilities, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NetSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $NetSnapshotsTable> {
  $$NetSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get assets => $composableBuilder(
      column: $table.assets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get liabilities => $composableBuilder(
      column: $table.liabilities, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NetSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NetSnapshotsTable> {
  $$NetSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get assets =>
      $composableBuilder(column: $table.assets, builder: (column) => column);

  GeneratedColumn<int> get liabilities => $composableBuilder(
      column: $table.liabilities, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NetSnapshotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NetSnapshotsTable,
    NetSnapshot,
    $$NetSnapshotsTableFilterComposer,
    $$NetSnapshotsTableOrderingComposer,
    $$NetSnapshotsTableAnnotationComposer,
    $$NetSnapshotsTableCreateCompanionBuilder,
    $$NetSnapshotsTableUpdateCompanionBuilder,
    (
      NetSnapshot,
      BaseReferences<_$AppDatabase, $NetSnapshotsTable, NetSnapshot>
    ),
    NetSnapshot,
    PrefetchHooks Function()> {
  $$NetSnapshotsTableTableManager(_$AppDatabase db, $NetSnapshotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NetSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NetSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NetSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> month = const Value.absent(),
            Value<int> assets = const Value.absent(),
            Value<int> liabilities = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NetSnapshotsCompanion(
            month: month,
            assets: assets,
            liabilities: liabilities,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required DateTime month,
            required int assets,
            required int liabilities,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              NetSnapshotsCompanion.insert(
            month: month,
            assets: assets,
            liabilities: liabilities,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NetSnapshotsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NetSnapshotsTable,
    NetSnapshot,
    $$NetSnapshotsTableFilterComposer,
    $$NetSnapshotsTableOrderingComposer,
    $$NetSnapshotsTableAnnotationComposer,
    $$NetSnapshotsTableCreateCompanionBuilder,
    $$NetSnapshotsTableUpdateCompanionBuilder,
    (
      NetSnapshot,
      BaseReferences<_$AppDatabase, $NetSnapshotsTable, NetSnapshot>
    ),
    NetSnapshot,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$RecurringTxsTableTableManager get recurringTxs =>
      $$RecurringTxsTableTableManager(_db, _db.recurringTxs);
  $$SplitsTableTableManager get splits =>
      $$SplitsTableTableManager(_db, _db.splits);
  $$DebtsTableTableManager get debts =>
      $$DebtsTableTableManager(_db, _db.debts);
  $$DebtPaymentsTableTableManager get debtPayments =>
      $$DebtPaymentsTableTableManager(_db, _db.debtPayments);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$GoalDepositsTableTableManager get goalDeposits =>
      $$GoalDepositsTableTableManager(_db, _db.goalDeposits);
  $$SplitMembersTableTableManager get splitMembers =>
      $$SplitMembersTableTableManager(_db, _db.splitMembers);
  $$SplitItemsTableTableManager get splitItems =>
      $$SplitItemsTableTableManager(_db, _db.splitItems);
  $$BudgetAdjustmentsTableTableManager get budgetAdjustments =>
      $$BudgetAdjustmentsTableTableManager(_db, _db.budgetAdjustments);
  $$NetItemsTableTableManager get netItems =>
      $$NetItemsTableTableManager(_db, _db.netItems);
  $$NetSnapshotsTableTableManager get netSnapshots =>
      $$NetSnapshotsTableTableManager(_db, _db.netSnapshots);
}
