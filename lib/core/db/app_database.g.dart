// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bankName,
    last4,
    accountType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final String? bankName;
  final String? last4;
  final String accountType;
  final DateTime createdAt;
  const Account({
    required this.id,
    required this.name,
    this.bankName,
    this.last4,
    required this.accountType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    map['account_type'] = Variable<String>(accountType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      accountType: Value(accountType),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      last4: serializer.fromJson<String?>(json['last4']),
      accountType: serializer.fromJson<String>(json['accountType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bankName': serializer.toJson<String?>(bankName),
      'last4': serializer.toJson<String?>(last4),
      'accountType': serializer.toJson<String>(accountType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith({
    String? id,
    String? name,
    Value<String?> bankName = const Value.absent(),
    Value<String?> last4 = const Value.absent(),
    String? accountType,
    DateTime? createdAt,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    bankName: bankName.present ? bankName.value : this.bankName,
    last4: last4.present ? last4.value : this.last4,
    accountType: accountType ?? this.accountType,
    createdAt: createdAt ?? this.createdAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      last4: data.last4.present ? data.last4.value : this.last4,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('last4: $last4, ')
          ..write('accountType: $accountType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, bankName, last4, accountType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.bankName == this.bankName &&
          other.last4 == this.last4 &&
          other.accountType == this.accountType &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> bankName;
  final Value<String?> last4;
  final Value<String> accountType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bankName = const Value.absent(),
    this.last4 = const Value.absent(),
    this.accountType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    this.bankName = const Value.absent(),
    this.last4 = const Value.absent(),
    required String accountType,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       accountType = Value(accountType);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bankName,
    Expression<String>? last4,
    Expression<String>? accountType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bankName != null) 'bank_name': bankName,
      if (last4 != null) 'last4': last4,
      if (accountType != null) 'account_type': accountType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? bankName,
    Value<String?>? last4,
    Value<String>? accountType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      last4: last4 ?? this.last4,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('last4: $last4, ')
          ..write('accountType: $accountType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
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
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon, parentId, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String? icon;
  final String? parentId;
  final bool isDefault;
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.parentId,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      isDefault: Value(isDefault),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'parentId': serializer.toJson<String?>(parentId),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    bool? isDefault,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    parentId: parentId.present ? parentId.value : this.parentId,
    isDefault: isDefault ?? this.isDefault,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('parentId: $parentId, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, parentId, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.parentId == this.parentId &&
          other.isDefault == this.isDefault);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> parentId;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? parentId,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (parentId != null) 'parent_id': parentId,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? icon,
    Value<String?>? parentId,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      parentId: parentId ?? this.parentId,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('parentId: $parentId, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringGroupsTable extends RecurringGroups
    with TableInfo<$RecurringGroupsTable, RecurringGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _merchantPatternMeta = const VerificationMeta(
    'merchantPattern',
  );
  @override
  late final GeneratedColumn<String> merchantPattern = GeneratedColumn<String>(
    'merchant_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedAmountMinorMeta =
      const VerificationMeta('expectedAmountMinor');
  @override
  late final GeneratedColumn<int> expectedAmountMinor = GeneratedColumn<int>(
    'expected_amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextExpectedDateMeta = const VerificationMeta(
    'nextExpectedDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextExpectedDate =
      GeneratedColumn<DateTime>(
        'next_expected_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastConfirmedAtMeta = const VerificationMeta(
    'lastConfirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastConfirmedAt =
      GeneratedColumn<DateTime>(
        'last_confirmed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    merchantPattern,
    expectedAmountMinor,
    intervalDays,
    nextExpectedDate,
    lastConfirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('merchant_pattern')) {
      context.handle(
        _merchantPatternMeta,
        merchantPattern.isAcceptableOrUnknown(
          data['merchant_pattern']!,
          _merchantPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_merchantPatternMeta);
    }
    if (data.containsKey('expected_amount_minor')) {
      context.handle(
        _expectedAmountMinorMeta,
        expectedAmountMinor.isAcceptableOrUnknown(
          data['expected_amount_minor']!,
          _expectedAmountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedAmountMinorMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('next_expected_date')) {
      context.handle(
        _nextExpectedDateMeta,
        nextExpectedDate.isAcceptableOrUnknown(
          data['next_expected_date']!,
          _nextExpectedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextExpectedDateMeta);
    }
    if (data.containsKey('last_confirmed_at')) {
      context.handle(
        _lastConfirmedAtMeta,
        lastConfirmedAt.isAcceptableOrUnknown(
          data['last_confirmed_at']!,
          _lastConfirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      merchantPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_pattern'],
      )!,
      expectedAmountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_amount_minor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      nextExpectedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_expected_date'],
      )!,
      lastConfirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_confirmed_at'],
      ),
    );
  }

  @override
  $RecurringGroupsTable createAlias(String alias) {
    return $RecurringGroupsTable(attachedDatabase, alias);
  }
}

class RecurringGroup extends DataClass implements Insertable<RecurringGroup> {
  final String id;
  final String merchantPattern;
  final int expectedAmountMinor;
  final int intervalDays;
  final DateTime nextExpectedDate;
  final DateTime? lastConfirmedAt;
  const RecurringGroup({
    required this.id,
    required this.merchantPattern,
    required this.expectedAmountMinor,
    required this.intervalDays,
    required this.nextExpectedDate,
    this.lastConfirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['merchant_pattern'] = Variable<String>(merchantPattern);
    map['expected_amount_minor'] = Variable<int>(expectedAmountMinor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['next_expected_date'] = Variable<DateTime>(nextExpectedDate);
    if (!nullToAbsent || lastConfirmedAt != null) {
      map['last_confirmed_at'] = Variable<DateTime>(lastConfirmedAt);
    }
    return map;
  }

  RecurringGroupsCompanion toCompanion(bool nullToAbsent) {
    return RecurringGroupsCompanion(
      id: Value(id),
      merchantPattern: Value(merchantPattern),
      expectedAmountMinor: Value(expectedAmountMinor),
      intervalDays: Value(intervalDays),
      nextExpectedDate: Value(nextExpectedDate),
      lastConfirmedAt: lastConfirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConfirmedAt),
    );
  }

  factory RecurringGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringGroup(
      id: serializer.fromJson<String>(json['id']),
      merchantPattern: serializer.fromJson<String>(json['merchantPattern']),
      expectedAmountMinor: serializer.fromJson<int>(
        json['expectedAmountMinor'],
      ),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      nextExpectedDate: serializer.fromJson<DateTime>(json['nextExpectedDate']),
      lastConfirmedAt: serializer.fromJson<DateTime?>(json['lastConfirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'merchantPattern': serializer.toJson<String>(merchantPattern),
      'expectedAmountMinor': serializer.toJson<int>(expectedAmountMinor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'nextExpectedDate': serializer.toJson<DateTime>(nextExpectedDate),
      'lastConfirmedAt': serializer.toJson<DateTime?>(lastConfirmedAt),
    };
  }

  RecurringGroup copyWith({
    String? id,
    String? merchantPattern,
    int? expectedAmountMinor,
    int? intervalDays,
    DateTime? nextExpectedDate,
    Value<DateTime?> lastConfirmedAt = const Value.absent(),
  }) => RecurringGroup(
    id: id ?? this.id,
    merchantPattern: merchantPattern ?? this.merchantPattern,
    expectedAmountMinor: expectedAmountMinor ?? this.expectedAmountMinor,
    intervalDays: intervalDays ?? this.intervalDays,
    nextExpectedDate: nextExpectedDate ?? this.nextExpectedDate,
    lastConfirmedAt: lastConfirmedAt.present
        ? lastConfirmedAt.value
        : this.lastConfirmedAt,
  );
  RecurringGroup copyWithCompanion(RecurringGroupsCompanion data) {
    return RecurringGroup(
      id: data.id.present ? data.id.value : this.id,
      merchantPattern: data.merchantPattern.present
          ? data.merchantPattern.value
          : this.merchantPattern,
      expectedAmountMinor: data.expectedAmountMinor.present
          ? data.expectedAmountMinor.value
          : this.expectedAmountMinor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      nextExpectedDate: data.nextExpectedDate.present
          ? data.nextExpectedDate.value
          : this.nextExpectedDate,
      lastConfirmedAt: data.lastConfirmedAt.present
          ? data.lastConfirmedAt.value
          : this.lastConfirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringGroup(')
          ..write('id: $id, ')
          ..write('merchantPattern: $merchantPattern, ')
          ..write('expectedAmountMinor: $expectedAmountMinor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('nextExpectedDate: $nextExpectedDate, ')
          ..write('lastConfirmedAt: $lastConfirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    merchantPattern,
    expectedAmountMinor,
    intervalDays,
    nextExpectedDate,
    lastConfirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringGroup &&
          other.id == this.id &&
          other.merchantPattern == this.merchantPattern &&
          other.expectedAmountMinor == this.expectedAmountMinor &&
          other.intervalDays == this.intervalDays &&
          other.nextExpectedDate == this.nextExpectedDate &&
          other.lastConfirmedAt == this.lastConfirmedAt);
}

class RecurringGroupsCompanion extends UpdateCompanion<RecurringGroup> {
  final Value<String> id;
  final Value<String> merchantPattern;
  final Value<int> expectedAmountMinor;
  final Value<int> intervalDays;
  final Value<DateTime> nextExpectedDate;
  final Value<DateTime?> lastConfirmedAt;
  final Value<int> rowid;
  const RecurringGroupsCompanion({
    this.id = const Value.absent(),
    this.merchantPattern = const Value.absent(),
    this.expectedAmountMinor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.nextExpectedDate = const Value.absent(),
    this.lastConfirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringGroupsCompanion.insert({
    required String id,
    required String merchantPattern,
    required int expectedAmountMinor,
    required int intervalDays,
    required DateTime nextExpectedDate,
    this.lastConfirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       merchantPattern = Value(merchantPattern),
       expectedAmountMinor = Value(expectedAmountMinor),
       intervalDays = Value(intervalDays),
       nextExpectedDate = Value(nextExpectedDate);
  static Insertable<RecurringGroup> custom({
    Expression<String>? id,
    Expression<String>? merchantPattern,
    Expression<int>? expectedAmountMinor,
    Expression<int>? intervalDays,
    Expression<DateTime>? nextExpectedDate,
    Expression<DateTime>? lastConfirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (merchantPattern != null) 'merchant_pattern': merchantPattern,
      if (expectedAmountMinor != null)
        'expected_amount_minor': expectedAmountMinor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (nextExpectedDate != null) 'next_expected_date': nextExpectedDate,
      if (lastConfirmedAt != null) 'last_confirmed_at': lastConfirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? merchantPattern,
    Value<int>? expectedAmountMinor,
    Value<int>? intervalDays,
    Value<DateTime>? nextExpectedDate,
    Value<DateTime?>? lastConfirmedAt,
    Value<int>? rowid,
  }) {
    return RecurringGroupsCompanion(
      id: id ?? this.id,
      merchantPattern: merchantPattern ?? this.merchantPattern,
      expectedAmountMinor: expectedAmountMinor ?? this.expectedAmountMinor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextExpectedDate: nextExpectedDate ?? this.nextExpectedDate,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (merchantPattern.present) {
      map['merchant_pattern'] = Variable<String>(merchantPattern.value);
    }
    if (expectedAmountMinor.present) {
      map['expected_amount_minor'] = Variable<int>(expectedAmountMinor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (nextExpectedDate.present) {
      map['next_expected_date'] = Variable<DateTime>(nextExpectedDate.value);
    }
    if (lastConfirmedAt.present) {
      map['last_confirmed_at'] = Variable<DateTime>(lastConfirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringGroupsCompanion(')
          ..write('id: $id, ')
          ..write('merchantPattern: $merchantPattern, ')
          ..write('expectedAmountMinor: $expectedAmountMinor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('nextExpectedDate: $nextExpectedDate, ')
          ..write('lastConfirmedAt: $lastConfirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextEncryptedMeta = const VerificationMeta(
    'rawTextEncrypted',
  );
  @override
  late final GeneratedColumn<String> rawTextEncrypted = GeneratedColumn<String>(
    'raw_text_encrypted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurringGroupIdMeta = const VerificationMeta(
    'recurringGroupId',
  );
  @override
  late final GeneratedColumn<String> recurringGroupId = GeneratedColumn<String>(
    'recurring_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_groups (id)',
    ),
  );
  static const VerificationMeta _isInternationalMeta = const VerificationMeta(
    'isInternational',
  );
  @override
  late final GeneratedColumn<bool> isInternational = GeneratedColumn<bool>(
    'is_international',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_international" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isFlaggedUnusualMeta = const VerificationMeta(
    'isFlaggedUnusual',
  );
  @override
  late final GeneratedColumn<bool> isFlaggedUnusual = GeneratedColumn<bool>(
    'is_flagged_unusual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_flagged_unusual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _userEditedMeta = const VerificationMeta(
    'userEdited',
  );
  @override
  late final GeneratedColumn<bool> userEdited = GeneratedColumn<bool>(
    'user_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("user_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _rawMerchantMeta = const VerificationMeta(
    'rawMerchant',
  );
  @override
  late final GeneratedColumn<String> rawMerchant = GeneratedColumn<String>(
    'raw_merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('normal'),
  );
  static const VerificationMeta _kindLockedMeta = const VerificationMeta(
    'kindLocked',
  );
  @override
  late final GeneratedColumn<bool> kindLocked = GeneratedColumn<bool>(
    'kind_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kind_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _transferGroupIdMeta = const VerificationMeta(
    'transferGroupId',
  );
  @override
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
    'transfer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundOfIdMeta = const VerificationMeta(
    'refundOfId',
  );
  @override
  late final GeneratedColumn<String> refundOfId = GeneratedColumn<String>(
    'refund_of_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundHintMeta = const VerificationMeta(
    'refundHint',
  );
  @override
  late final GeneratedColumn<bool> refundHint = GeneratedColumn<bool>(
    'refund_hint',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("refund_hint" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _alsoInSourceMeta = const VerificationMeta(
    'alsoInSource',
  );
  @override
  late final GeneratedColumn<String> alsoInSource = GeneratedColumn<String>(
    'also_in_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceHashMeta = const VerificationMeta(
    'sourceHash',
  );
  @override
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
    'source_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    amountMinor,
    currency,
    merchant,
    rawTextEncrypted,
    source,
    categoryId,
    date,
    type,
    isRecurring,
    recurringGroupId,
    isInternational,
    isFlaggedUnusual,
    isDeleted,
    userEdited,
    createdAt,
    rawMerchant,
    kind,
    kindLocked,
    transferGroupId,
    refundOfId,
    refundHint,
    alsoInSource,
    sourceHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    } else if (isInserting) {
      context.missing(_merchantMeta);
    }
    if (data.containsKey('raw_text_encrypted')) {
      context.handle(
        _rawTextEncryptedMeta,
        rawTextEncrypted.isAcceptableOrUnknown(
          data['raw_text_encrypted']!,
          _rawTextEncryptedMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurring_group_id')) {
      context.handle(
        _recurringGroupIdMeta,
        recurringGroupId.isAcceptableOrUnknown(
          data['recurring_group_id']!,
          _recurringGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('is_international')) {
      context.handle(
        _isInternationalMeta,
        isInternational.isAcceptableOrUnknown(
          data['is_international']!,
          _isInternationalMeta,
        ),
      );
    }
    if (data.containsKey('is_flagged_unusual')) {
      context.handle(
        _isFlaggedUnusualMeta,
        isFlaggedUnusual.isAcceptableOrUnknown(
          data['is_flagged_unusual']!,
          _isFlaggedUnusualMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('user_edited')) {
      context.handle(
        _userEditedMeta,
        userEdited.isAcceptableOrUnknown(data['user_edited']!, _userEditedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('raw_merchant')) {
      context.handle(
        _rawMerchantMeta,
        rawMerchant.isAcceptableOrUnknown(
          data['raw_merchant']!,
          _rawMerchantMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('kind_locked')) {
      context.handle(
        _kindLockedMeta,
        kindLocked.isAcceptableOrUnknown(data['kind_locked']!, _kindLockedMeta),
      );
    }
    if (data.containsKey('transfer_group_id')) {
      context.handle(
        _transferGroupIdMeta,
        transferGroupId.isAcceptableOrUnknown(
          data['transfer_group_id']!,
          _transferGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('refund_of_id')) {
      context.handle(
        _refundOfIdMeta,
        refundOfId.isAcceptableOrUnknown(
          data['refund_of_id']!,
          _refundOfIdMeta,
        ),
      );
    }
    if (data.containsKey('refund_hint')) {
      context.handle(
        _refundHintMeta,
        refundHint.isAcceptableOrUnknown(data['refund_hint']!, _refundHintMeta),
      );
    }
    if (data.containsKey('also_in_source')) {
      context.handle(
        _alsoInSourceMeta,
        alsoInSource.isAcceptableOrUnknown(
          data['also_in_source']!,
          _alsoInSourceMeta,
        ),
      );
    }
    if (data.containsKey('source_hash')) {
      context.handle(
        _sourceHashMeta,
        sourceHash.isAcceptableOrUnknown(data['source_hash']!, _sourceHashMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      )!,
      rawTextEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text_encrypted'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurringGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_group_id'],
      ),
      isInternational: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_international'],
      )!,
      isFlaggedUnusual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_flagged_unusual'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      userEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}user_edited'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      rawMerchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_merchant'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      kindLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kind_locked'],
      )!,
      transferGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_group_id'],
      ),
      refundOfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_of_id'],
      ),
      refundHint: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}refund_hint'],
      )!,
      alsoInSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}also_in_source'],
      ),
      sourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_hash'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String? accountId;
  final int amountMinor;
  final String currency;
  final String merchant;

  /// AES-256-GCM encrypted original SMS/email text, base64-encoded.
  final String? rawTextEncrypted;
  final String source;
  final String? categoryId;
  final DateTime date;
  final String type;
  final bool isRecurring;
  final String? recurringGroupId;
  final bool isInternational;
  final bool isFlaggedUnusual;
  final bool isDeleted;
  final bool userEdited;
  final DateTime createdAt;

  /// The merchant text exactly as the bank sent it, kept next to the
  /// cleaned-up [merchant] so aliases can be learned and re-applied.
  final String? rawMerchant;

  /// normal | transfer (between the user's own accounts — not spending or
  /// income) | refund (a credit that reverses an earlier debit).
  final String kind;

  /// True once the user set [kind] by hand, so auto-detection never
  /// overrides their decision.
  final bool kindLocked;

  /// Shared by the two halves of a detected transfer.
  final String? transferGroupId;

  /// For [kind] == refund: the debit this credit reverses.
  final String? refundOfId;

  /// The original message talked about a refund/reversal. That wording
  /// isn't in [merchant], so it's kept here for the refund matcher.
  final bool refundHint;

  /// Other channels that reported this same transaction and were merged into
  /// it (comma-separated, e.g. "email") — each channel can be merged into a
  /// transaction only once, so two real payments are never collapsed.
  final String? alsoInSource;

  /// SHA-512 of source + original message text + timestamp; identical
  /// re-scans of the same message produce the same hash.
  final String? sourceHash;
  const Transaction({
    required this.id,
    this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.merchant,
    this.rawTextEncrypted,
    required this.source,
    this.categoryId,
    required this.date,
    required this.type,
    required this.isRecurring,
    this.recurringGroupId,
    required this.isInternational,
    required this.isFlaggedUnusual,
    required this.isDeleted,
    required this.userEdited,
    required this.createdAt,
    this.rawMerchant,
    required this.kind,
    required this.kindLocked,
    this.transferGroupId,
    this.refundOfId,
    required this.refundHint,
    this.alsoInSource,
    this.sourceHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['merchant'] = Variable<String>(merchant);
    if (!nullToAbsent || rawTextEncrypted != null) {
      map['raw_text_encrypted'] = Variable<String>(rawTextEncrypted);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['date'] = Variable<DateTime>(date);
    map['type'] = Variable<String>(type);
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurringGroupId != null) {
      map['recurring_group_id'] = Variable<String>(recurringGroupId);
    }
    map['is_international'] = Variable<bool>(isInternational);
    map['is_flagged_unusual'] = Variable<bool>(isFlaggedUnusual);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['user_edited'] = Variable<bool>(userEdited);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || rawMerchant != null) {
      map['raw_merchant'] = Variable<String>(rawMerchant);
    }
    map['kind'] = Variable<String>(kind);
    map['kind_locked'] = Variable<bool>(kindLocked);
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    if (!nullToAbsent || refundOfId != null) {
      map['refund_of_id'] = Variable<String>(refundOfId);
    }
    map['refund_hint'] = Variable<bool>(refundHint);
    if (!nullToAbsent || alsoInSource != null) {
      map['also_in_source'] = Variable<String>(alsoInSource);
    }
    if (!nullToAbsent || sourceHash != null) {
      map['source_hash'] = Variable<String>(sourceHash);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      merchant: Value(merchant),
      rawTextEncrypted: rawTextEncrypted == null && nullToAbsent
          ? const Value.absent()
          : Value(rawTextEncrypted),
      source: Value(source),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      date: Value(date),
      type: Value(type),
      isRecurring: Value(isRecurring),
      recurringGroupId: recurringGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringGroupId),
      isInternational: Value(isInternational),
      isFlaggedUnusual: Value(isFlaggedUnusual),
      isDeleted: Value(isDeleted),
      userEdited: Value(userEdited),
      createdAt: Value(createdAt),
      rawMerchant: rawMerchant == null && nullToAbsent
          ? const Value.absent()
          : Value(rawMerchant),
      kind: Value(kind),
      kindLocked: Value(kindLocked),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
      refundOfId: refundOfId == null && nullToAbsent
          ? const Value.absent()
          : Value(refundOfId),
      refundHint: Value(refundHint),
      alsoInSource: alsoInSource == null && nullToAbsent
          ? const Value.absent()
          : Value(alsoInSource),
      sourceHash: sourceHash == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceHash),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      merchant: serializer.fromJson<String>(json['merchant']),
      rawTextEncrypted: serializer.fromJson<String?>(json['rawTextEncrypted']),
      source: serializer.fromJson<String>(json['source']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurringGroupId: serializer.fromJson<String?>(json['recurringGroupId']),
      isInternational: serializer.fromJson<bool>(json['isInternational']),
      isFlaggedUnusual: serializer.fromJson<bool>(json['isFlaggedUnusual']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      userEdited: serializer.fromJson<bool>(json['userEdited']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      rawMerchant: serializer.fromJson<String?>(json['rawMerchant']),
      kind: serializer.fromJson<String>(json['kind']),
      kindLocked: serializer.fromJson<bool>(json['kindLocked']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
      refundOfId: serializer.fromJson<String?>(json['refundOfId']),
      refundHint: serializer.fromJson<bool>(json['refundHint']),
      alsoInSource: serializer.fromJson<String?>(json['alsoInSource']),
      sourceHash: serializer.fromJson<String?>(json['sourceHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String?>(accountId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'merchant': serializer.toJson<String>(merchant),
      'rawTextEncrypted': serializer.toJson<String?>(rawTextEncrypted),
      'source': serializer.toJson<String>(source),
      'categoryId': serializer.toJson<String?>(categoryId),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(type),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurringGroupId': serializer.toJson<String?>(recurringGroupId),
      'isInternational': serializer.toJson<bool>(isInternational),
      'isFlaggedUnusual': serializer.toJson<bool>(isFlaggedUnusual),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'userEdited': serializer.toJson<bool>(userEdited),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'rawMerchant': serializer.toJson<String?>(rawMerchant),
      'kind': serializer.toJson<String>(kind),
      'kindLocked': serializer.toJson<bool>(kindLocked),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
      'refundOfId': serializer.toJson<String?>(refundOfId),
      'refundHint': serializer.toJson<bool>(refundHint),
      'alsoInSource': serializer.toJson<String?>(alsoInSource),
      'sourceHash': serializer.toJson<String?>(sourceHash),
    };
  }

  Transaction copyWith({
    String? id,
    Value<String?> accountId = const Value.absent(),
    int? amountMinor,
    String? currency,
    String? merchant,
    Value<String?> rawTextEncrypted = const Value.absent(),
    String? source,
    Value<String?> categoryId = const Value.absent(),
    DateTime? date,
    String? type,
    bool? isRecurring,
    Value<String?> recurringGroupId = const Value.absent(),
    bool? isInternational,
    bool? isFlaggedUnusual,
    bool? isDeleted,
    bool? userEdited,
    DateTime? createdAt,
    Value<String?> rawMerchant = const Value.absent(),
    String? kind,
    bool? kindLocked,
    Value<String?> transferGroupId = const Value.absent(),
    Value<String?> refundOfId = const Value.absent(),
    bool? refundHint,
    Value<String?> alsoInSource = const Value.absent(),
    Value<String?> sourceHash = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    accountId: accountId.present ? accountId.value : this.accountId,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency ?? this.currency,
    merchant: merchant ?? this.merchant,
    rawTextEncrypted: rawTextEncrypted.present
        ? rawTextEncrypted.value
        : this.rawTextEncrypted,
    source: source ?? this.source,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    date: date ?? this.date,
    type: type ?? this.type,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringGroupId: recurringGroupId.present
        ? recurringGroupId.value
        : this.recurringGroupId,
    isInternational: isInternational ?? this.isInternational,
    isFlaggedUnusual: isFlaggedUnusual ?? this.isFlaggedUnusual,
    isDeleted: isDeleted ?? this.isDeleted,
    userEdited: userEdited ?? this.userEdited,
    createdAt: createdAt ?? this.createdAt,
    rawMerchant: rawMerchant.present ? rawMerchant.value : this.rawMerchant,
    kind: kind ?? this.kind,
    kindLocked: kindLocked ?? this.kindLocked,
    transferGroupId: transferGroupId.present
        ? transferGroupId.value
        : this.transferGroupId,
    refundOfId: refundOfId.present ? refundOfId.value : this.refundOfId,
    refundHint: refundHint ?? this.refundHint,
    alsoInSource: alsoInSource.present ? alsoInSource.value : this.alsoInSource,
    sourceHash: sourceHash.present ? sourceHash.value : this.sourceHash,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      rawTextEncrypted: data.rawTextEncrypted.present
          ? data.rawTextEncrypted.value
          : this.rawTextEncrypted,
      source: data.source.present ? data.source.value : this.source,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurringGroupId: data.recurringGroupId.present
          ? data.recurringGroupId.value
          : this.recurringGroupId,
      isInternational: data.isInternational.present
          ? data.isInternational.value
          : this.isInternational,
      isFlaggedUnusual: data.isFlaggedUnusual.present
          ? data.isFlaggedUnusual.value
          : this.isFlaggedUnusual,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      userEdited: data.userEdited.present
          ? data.userEdited.value
          : this.userEdited,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rawMerchant: data.rawMerchant.present
          ? data.rawMerchant.value
          : this.rawMerchant,
      kind: data.kind.present ? data.kind.value : this.kind,
      kindLocked: data.kindLocked.present
          ? data.kindLocked.value
          : this.kindLocked,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
      refundOfId: data.refundOfId.present
          ? data.refundOfId.value
          : this.refundOfId,
      refundHint: data.refundHint.present
          ? data.refundHint.value
          : this.refundHint,
      alsoInSource: data.alsoInSource.present
          ? data.alsoInSource.value
          : this.alsoInSource,
      sourceHash: data.sourceHash.present
          ? data.sourceHash.value
          : this.sourceHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('merchant: $merchant, ')
          ..write('rawTextEncrypted: $rawTextEncrypted, ')
          ..write('source: $source, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringGroupId: $recurringGroupId, ')
          ..write('isInternational: $isInternational, ')
          ..write('isFlaggedUnusual: $isFlaggedUnusual, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('userEdited: $userEdited, ')
          ..write('createdAt: $createdAt, ')
          ..write('rawMerchant: $rawMerchant, ')
          ..write('kind: $kind, ')
          ..write('kindLocked: $kindLocked, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('refundOfId: $refundOfId, ')
          ..write('refundHint: $refundHint, ')
          ..write('alsoInSource: $alsoInSource, ')
          ..write('sourceHash: $sourceHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    amountMinor,
    currency,
    merchant,
    rawTextEncrypted,
    source,
    categoryId,
    date,
    type,
    isRecurring,
    recurringGroupId,
    isInternational,
    isFlaggedUnusual,
    isDeleted,
    userEdited,
    createdAt,
    rawMerchant,
    kind,
    kindLocked,
    transferGroupId,
    refundOfId,
    refundHint,
    alsoInSource,
    sourceHash,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.merchant == this.merchant &&
          other.rawTextEncrypted == this.rawTextEncrypted &&
          other.source == this.source &&
          other.categoryId == this.categoryId &&
          other.date == this.date &&
          other.type == this.type &&
          other.isRecurring == this.isRecurring &&
          other.recurringGroupId == this.recurringGroupId &&
          other.isInternational == this.isInternational &&
          other.isFlaggedUnusual == this.isFlaggedUnusual &&
          other.isDeleted == this.isDeleted &&
          other.userEdited == this.userEdited &&
          other.createdAt == this.createdAt &&
          other.rawMerchant == this.rawMerchant &&
          other.kind == this.kind &&
          other.kindLocked == this.kindLocked &&
          other.transferGroupId == this.transferGroupId &&
          other.refundOfId == this.refundOfId &&
          other.refundHint == this.refundHint &&
          other.alsoInSource == this.alsoInSource &&
          other.sourceHash == this.sourceHash);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String?> accountId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<String> merchant;
  final Value<String?> rawTextEncrypted;
  final Value<String> source;
  final Value<String?> categoryId;
  final Value<DateTime> date;
  final Value<String> type;
  final Value<bool> isRecurring;
  final Value<String?> recurringGroupId;
  final Value<bool> isInternational;
  final Value<bool> isFlaggedUnusual;
  final Value<bool> isDeleted;
  final Value<bool> userEdited;
  final Value<DateTime> createdAt;
  final Value<String?> rawMerchant;
  final Value<String> kind;
  final Value<bool> kindLocked;
  final Value<String?> transferGroupId;
  final Value<String?> refundOfId;
  final Value<bool> refundHint;
  final Value<String?> alsoInSource;
  final Value<String?> sourceHash;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.merchant = const Value.absent(),
    this.rawTextEncrypted = const Value.absent(),
    this.source = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringGroupId = const Value.absent(),
    this.isInternational = const Value.absent(),
    this.isFlaggedUnusual = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rawMerchant = const Value.absent(),
    this.kind = const Value.absent(),
    this.kindLocked = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.refundOfId = const Value.absent(),
    this.refundHint = const Value.absent(),
    this.alsoInSource = const Value.absent(),
    this.sourceHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    this.accountId = const Value.absent(),
    required int amountMinor,
    this.currency = const Value.absent(),
    required String merchant,
    this.rawTextEncrypted = const Value.absent(),
    required String source,
    this.categoryId = const Value.absent(),
    required DateTime date,
    required String type,
    this.isRecurring = const Value.absent(),
    this.recurringGroupId = const Value.absent(),
    this.isInternational = const Value.absent(),
    this.isFlaggedUnusual = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.userEdited = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rawMerchant = const Value.absent(),
    this.kind = const Value.absent(),
    this.kindLocked = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.refundOfId = const Value.absent(),
    this.refundHint = const Value.absent(),
    this.alsoInSource = const Value.absent(),
    this.sourceHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountMinor = Value(amountMinor),
       merchant = Value(merchant),
       source = Value(source),
       date = Value(date),
       type = Value(type);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<String>? merchant,
    Expression<String>? rawTextEncrypted,
    Expression<String>? source,
    Expression<String>? categoryId,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<bool>? isRecurring,
    Expression<String>? recurringGroupId,
    Expression<bool>? isInternational,
    Expression<bool>? isFlaggedUnusual,
    Expression<bool>? isDeleted,
    Expression<bool>? userEdited,
    Expression<DateTime>? createdAt,
    Expression<String>? rawMerchant,
    Expression<String>? kind,
    Expression<bool>? kindLocked,
    Expression<String>? transferGroupId,
    Expression<String>? refundOfId,
    Expression<bool>? refundHint,
    Expression<String>? alsoInSource,
    Expression<String>? sourceHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (merchant != null) 'merchant': merchant,
      if (rawTextEncrypted != null) 'raw_text_encrypted': rawTextEncrypted,
      if (source != null) 'source': source,
      if (categoryId != null) 'category_id': categoryId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurringGroupId != null) 'recurring_group_id': recurringGroupId,
      if (isInternational != null) 'is_international': isInternational,
      if (isFlaggedUnusual != null) 'is_flagged_unusual': isFlaggedUnusual,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (userEdited != null) 'user_edited': userEdited,
      if (createdAt != null) 'created_at': createdAt,
      if (rawMerchant != null) 'raw_merchant': rawMerchant,
      if (kind != null) 'kind': kind,
      if (kindLocked != null) 'kind_locked': kindLocked,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (refundOfId != null) 'refund_of_id': refundOfId,
      if (refundHint != null) 'refund_hint': refundHint,
      if (alsoInSource != null) 'also_in_source': alsoInSource,
      if (sourceHash != null) 'source_hash': sourceHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? accountId,
    Value<int>? amountMinor,
    Value<String>? currency,
    Value<String>? merchant,
    Value<String?>? rawTextEncrypted,
    Value<String>? source,
    Value<String?>? categoryId,
    Value<DateTime>? date,
    Value<String>? type,
    Value<bool>? isRecurring,
    Value<String?>? recurringGroupId,
    Value<bool>? isInternational,
    Value<bool>? isFlaggedUnusual,
    Value<bool>? isDeleted,
    Value<bool>? userEdited,
    Value<DateTime>? createdAt,
    Value<String?>? rawMerchant,
    Value<String>? kind,
    Value<bool>? kindLocked,
    Value<String?>? transferGroupId,
    Value<String?>? refundOfId,
    Value<bool>? refundHint,
    Value<String?>? alsoInSource,
    Value<String?>? sourceHash,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      rawTextEncrypted: rawTextEncrypted ?? this.rawTextEncrypted,
      source: source ?? this.source,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      type: type ?? this.type,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringGroupId: recurringGroupId ?? this.recurringGroupId,
      isInternational: isInternational ?? this.isInternational,
      isFlaggedUnusual: isFlaggedUnusual ?? this.isFlaggedUnusual,
      isDeleted: isDeleted ?? this.isDeleted,
      userEdited: userEdited ?? this.userEdited,
      createdAt: createdAt ?? this.createdAt,
      rawMerchant: rawMerchant ?? this.rawMerchant,
      kind: kind ?? this.kind,
      kindLocked: kindLocked ?? this.kindLocked,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      refundOfId: refundOfId ?? this.refundOfId,
      refundHint: refundHint ?? this.refundHint,
      alsoInSource: alsoInSource ?? this.alsoInSource,
      sourceHash: sourceHash ?? this.sourceHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (rawTextEncrypted.present) {
      map['raw_text_encrypted'] = Variable<String>(rawTextEncrypted.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurringGroupId.present) {
      map['recurring_group_id'] = Variable<String>(recurringGroupId.value);
    }
    if (isInternational.present) {
      map['is_international'] = Variable<bool>(isInternational.value);
    }
    if (isFlaggedUnusual.present) {
      map['is_flagged_unusual'] = Variable<bool>(isFlaggedUnusual.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (userEdited.present) {
      map['user_edited'] = Variable<bool>(userEdited.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rawMerchant.present) {
      map['raw_merchant'] = Variable<String>(rawMerchant.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (kindLocked.present) {
      map['kind_locked'] = Variable<bool>(kindLocked.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (refundOfId.present) {
      map['refund_of_id'] = Variable<String>(refundOfId.value);
    }
    if (refundHint.present) {
      map['refund_hint'] = Variable<bool>(refundHint.value);
    }
    if (alsoInSource.present) {
      map['also_in_source'] = Variable<String>(alsoInSource.value);
    }
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('merchant: $merchant, ')
          ..write('rawTextEncrypted: $rawTextEncrypted, ')
          ..write('source: $source, ')
          ..write('categoryId: $categoryId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringGroupId: $recurringGroupId, ')
          ..write('isInternational: $isInternational, ')
          ..write('isFlaggedUnusual: $isFlaggedUnusual, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('userEdited: $userEdited, ')
          ..write('createdAt: $createdAt, ')
          ..write('rawMerchant: $rawMerchant, ')
          ..write('kind: $kind, ')
          ..write('kindLocked: $kindLocked, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('refundOfId: $refundOfId, ')
          ..write('refundHint: $refundHint, ')
          ..write('alsoInSource: $alsoInSource, ')
          ..write('sourceHash: $sourceHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RulesTable extends Rules with TableInfo<$RulesTable, Rule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pattern,
    categoryId,
    priority,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<Rule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Rule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $RulesTable createAlias(String alias) {
    return $RulesTable(attachedDatabase, alias);
  }
}

class Rule extends DataClass implements Insertable<Rule> {
  final String id;
  final String pattern;
  final String categoryId;
  final int priority;
  final String source;
  const Rule({
    required this.id,
    required this.pattern,
    required this.categoryId,
    required this.priority,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pattern'] = Variable<String>(pattern);
    map['category_id'] = Variable<String>(categoryId);
    map['priority'] = Variable<int>(priority);
    map['source'] = Variable<String>(source);
    return map;
  }

  RulesCompanion toCompanion(bool nullToAbsent) {
    return RulesCompanion(
      id: Value(id),
      pattern: Value(pattern),
      categoryId: Value(categoryId),
      priority: Value(priority),
      source: Value(source),
    );
  }

  factory Rule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rule(
      id: serializer.fromJson<String>(json['id']),
      pattern: serializer.fromJson<String>(json['pattern']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      priority: serializer.fromJson<int>(json['priority']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pattern': serializer.toJson<String>(pattern),
      'categoryId': serializer.toJson<String>(categoryId),
      'priority': serializer.toJson<int>(priority),
      'source': serializer.toJson<String>(source),
    };
  }

  Rule copyWith({
    String? id,
    String? pattern,
    String? categoryId,
    int? priority,
    String? source,
  }) => Rule(
    id: id ?? this.id,
    pattern: pattern ?? this.pattern,
    categoryId: categoryId ?? this.categoryId,
    priority: priority ?? this.priority,
    source: source ?? this.source,
  );
  Rule copyWithCompanion(RulesCompanion data) {
    return Rule(
      id: data.id.present ? data.id.value : this.id,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      priority: data.priority.present ? data.priority.value : this.priority,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rule(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pattern, categoryId, priority, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rule &&
          other.id == this.id &&
          other.pattern == this.pattern &&
          other.categoryId == this.categoryId &&
          other.priority == this.priority &&
          other.source == this.source);
}

class RulesCompanion extends UpdateCompanion<Rule> {
  final Value<String> id;
  final Value<String> pattern;
  final Value<String> categoryId;
  final Value<int> priority;
  final Value<String> source;
  final Value<int> rowid;
  const RulesCompanion({
    this.id = const Value.absent(),
    this.pattern = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.priority = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RulesCompanion.insert({
    required String id,
    required String pattern,
    required String categoryId,
    this.priority = const Value.absent(),
    required String source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pattern = Value(pattern),
       categoryId = Value(categoryId),
       source = Value(source);
  static Insertable<Rule> custom({
    Expression<String>? id,
    Expression<String>? pattern,
    Expression<String>? categoryId,
    Expression<int>? priority,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pattern != null) 'pattern': pattern,
      if (categoryId != null) 'category_id': categoryId,
      if (priority != null) 'priority': priority,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RulesCompanion copyWith({
    Value<String>? id,
    Value<String>? pattern,
    Value<String>? categoryId,
    Value<int>? priority,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return RulesCompanion(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RulesCompanion(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsTable extends Alerts with TableInfo<$AlertsTable, Alert> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id)',
    ),
  );
  static const VerificationMeta _alertTypeMeta = const VerificationMeta(
    'alertType',
  );
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
    'alert_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _dismissedMeta = const VerificationMeta(
    'dismissed',
  );
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dismissed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    alertType,
    message,
    createdAt,
    dismissed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alert> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('alert_type')) {
      context.handle(
        _alertTypeMeta,
        alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('dismissed')) {
      context.handle(
        _dismissedMeta,
        dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Alert map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alert(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      alertType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_type'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      dismissed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dismissed'],
      )!,
    );
  }

  @override
  $AlertsTable createAlias(String alias) {
    return $AlertsTable(attachedDatabase, alias);
  }
}

class Alert extends DataClass implements Insertable<Alert> {
  final String id;
  final String? transactionId;
  final String alertType;
  final String message;
  final DateTime createdAt;
  final bool dismissed;
  const Alert({
    required this.id,
    this.transactionId,
    required this.alertType,
    required this.message,
    required this.createdAt,
    required this.dismissed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    map['alert_type'] = Variable<String>(alertType);
    map['message'] = Variable<String>(message);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['dismissed'] = Variable<bool>(dismissed);
    return map;
  }

  AlertsCompanion toCompanion(bool nullToAbsent) {
    return AlertsCompanion(
      id: Value(id),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      alertType: Value(alertType),
      message: Value(message),
      createdAt: Value(createdAt),
      dismissed: Value(dismissed),
    );
  }

  factory Alert.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alert(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      alertType: serializer.fromJson<String>(json['alertType']),
      message: serializer.fromJson<String>(json['message']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String?>(transactionId),
      'alertType': serializer.toJson<String>(alertType),
      'message': serializer.toJson<String>(message),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'dismissed': serializer.toJson<bool>(dismissed),
    };
  }

  Alert copyWith({
    String? id,
    Value<String?> transactionId = const Value.absent(),
    String? alertType,
    String? message,
    DateTime? createdAt,
    bool? dismissed,
  }) => Alert(
    id: id ?? this.id,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    alertType: alertType ?? this.alertType,
    message: message ?? this.message,
    createdAt: createdAt ?? this.createdAt,
    dismissed: dismissed ?? this.dismissed,
  );
  Alert copyWithCompanion(AlertsCompanion data) {
    return Alert(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      message: data.message.present ? data.message.value : this.message,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alert(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('alertType: $alertType, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, transactionId, alertType, message, createdAt, dismissed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alert &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.alertType == this.alertType &&
          other.message == this.message &&
          other.createdAt == this.createdAt &&
          other.dismissed == this.dismissed);
}

class AlertsCompanion extends UpdateCompanion<Alert> {
  final Value<String> id;
  final Value<String?> transactionId;
  final Value<String> alertType;
  final Value<String> message;
  final Value<DateTime> createdAt;
  final Value<bool> dismissed;
  final Value<int> rowid;
  const AlertsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.alertType = const Value.absent(),
    this.message = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsCompanion.insert({
    required String id,
    this.transactionId = const Value.absent(),
    required String alertType,
    required String message,
    this.createdAt = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       alertType = Value(alertType),
       message = Value(message);
  static Insertable<Alert> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? alertType,
    Expression<String>? message,
    Expression<DateTime>? createdAt,
    Expression<bool>? dismissed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (alertType != null) 'alert_type': alertType,
      if (message != null) 'message': message,
      if (createdAt != null) 'created_at': createdAt,
      if (dismissed != null) 'dismissed': dismissed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsCompanion copyWith({
    Value<String>? id,
    Value<String?>? transactionId,
    Value<String>? alertType,
    Value<String>? message,
    Value<DateTime>? createdAt,
    Value<bool>? dismissed,
    Value<int>? rowid,
  }) {
    return AlertsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      dismissed: dismissed ?? this.dismissed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('alertType: $alertType, ')
          ..write('message: $message, ')
          ..write('createdAt: $createdAt, ')
          ..write('dismissed: $dismissed, ')
          ..write('rowid: $rowid')
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
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _monthlyLimitMinorMeta = const VerificationMeta(
    'monthlyLimitMinor',
  );
  @override
  late final GeneratedColumn<int> monthlyLimitMinor = GeneratedColumn<int>(
    'monthly_limit_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromMonthKeyMeta = const VerificationMeta(
    'fromMonthKey',
  );
  @override
  late final GeneratedColumn<String> fromMonthKey = GeneratedColumn<String>(
    'from_month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0000-00'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    monthlyLimitMinor,
    fromMonthKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('monthly_limit_minor')) {
      context.handle(
        _monthlyLimitMinorMeta,
        monthlyLimitMinor.isAcceptableOrUnknown(
          data['monthly_limit_minor']!,
          _monthlyLimitMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_monthlyLimitMinorMeta);
    }
    if (data.containsKey('from_month_key')) {
      context.handle(
        _fromMonthKeyMeta,
        fromMonthKey.isAcceptableOrUnknown(
          data['from_month_key']!,
          _fromMonthKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      monthlyLimitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monthly_limit_minor'],
      )!,
      fromMonthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_month_key'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String categoryId;
  final int monthlyLimitMinor;

  /// The first month ("2026-10") this limit applies to. A category can have
  /// several rows; a month uses the latest one that has started, so changing
  /// a budget "from October on" never rewrites September. Budgets that
  /// existed before this column keep "0000-00": they apply to every month.
  final String fromMonthKey;
  const Budget({
    required this.id,
    required this.categoryId,
    required this.monthlyLimitMinor,
    required this.fromMonthKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['monthly_limit_minor'] = Variable<int>(monthlyLimitMinor);
    map['from_month_key'] = Variable<String>(fromMonthKey);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      monthlyLimitMinor: Value(monthlyLimitMinor),
      fromMonthKey: Value(fromMonthKey),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      monthlyLimitMinor: serializer.fromJson<int>(json['monthlyLimitMinor']),
      fromMonthKey: serializer.fromJson<String>(json['fromMonthKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'monthlyLimitMinor': serializer.toJson<int>(monthlyLimitMinor),
      'fromMonthKey': serializer.toJson<String>(fromMonthKey),
    };
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    int? monthlyLimitMinor,
    String? fromMonthKey,
  }) => Budget(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    monthlyLimitMinor: monthlyLimitMinor ?? this.monthlyLimitMinor,
    fromMonthKey: fromMonthKey ?? this.fromMonthKey,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      monthlyLimitMinor: data.monthlyLimitMinor.present
          ? data.monthlyLimitMinor.value
          : this.monthlyLimitMinor,
      fromMonthKey: data.fromMonthKey.present
          ? data.fromMonthKey.value
          : this.fromMonthKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthlyLimitMinor: $monthlyLimitMinor, ')
          ..write('fromMonthKey: $fromMonthKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, monthlyLimitMinor, fromMonthKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.monthlyLimitMinor == this.monthlyLimitMinor &&
          other.fromMonthKey == this.fromMonthKey);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<int> monthlyLimitMinor;
  final Value<String> fromMonthKey;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.monthlyLimitMinor = const Value.absent(),
    this.fromMonthKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String categoryId,
    required int monthlyLimitMinor,
    this.fromMonthKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       monthlyLimitMinor = Value(monthlyLimitMinor);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<int>? monthlyLimitMinor,
    Expression<String>? fromMonthKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (monthlyLimitMinor != null) 'monthly_limit_minor': monthlyLimitMinor,
      if (fromMonthKey != null) 'from_month_key': fromMonthKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<int>? monthlyLimitMinor,
    Value<String>? fromMonthKey,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthlyLimitMinor: monthlyLimitMinor ?? this.monthlyLimitMinor,
      fromMonthKey: fromMonthKey ?? this.fromMonthKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (monthlyLimitMinor.present) {
      map['monthly_limit_minor'] = Variable<int>(monthlyLimitMinor.value);
    }
    if (fromMonthKey.present) {
      map['from_month_key'] = Variable<String>(fromMonthKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthlyLimitMinor: $monthlyLimitMinor, ')
          ..write('fromMonthKey: $fromMonthKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingValueMeta = const VerificationMeta(
    'settingValue',
  );
  @override
  late final GeneratedColumn<String> settingValue = GeneratedColumn<String>(
    'setting_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, settingValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('setting_value')) {
      context.handle(
        _settingValueMeta,
        settingValue.isAcceptableOrUnknown(
          data['setting_value']!,
          _settingValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      settingValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String settingKey;
  final String settingValue;
  const AppSetting({required this.settingKey, required this.settingValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['setting_value'] = Variable<String>(settingValue);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingKey: Value(settingKey),
      settingValue: Value(settingValue),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      settingValue: serializer.fromJson<String>(json['settingValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'settingValue': serializer.toJson<String>(settingValue),
    };
  }

  AppSetting copyWith({String? settingKey, String? settingValue}) => AppSetting(
    settingKey: settingKey ?? this.settingKey,
    settingValue: settingValue ?? this.settingValue,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      settingValue: data.settingValue.present
          ? data.settingValue.value
          : this.settingValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, settingValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingKey == this.settingKey &&
          other.settingValue == this.settingValue);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> settingKey;
  final Value<String> settingValue;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingKey = const Value.absent(),
    this.settingValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingKey,
    required String settingValue,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       settingValue = Value(settingValue);
  static Insertable<AppSetting> custom({
    Expression<String>? settingKey,
    Expression<String>? settingValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (settingValue != null) 'setting_value': settingValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? settingValue,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (settingValue.present) {
      map['setting_value'] = Variable<String>(settingValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('settingValue: $settingValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OwnIdentifiersTable extends OwnIdentifiers
    with TableInfo<$OwnIdentifiersTable, OwnIdentifier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OwnIdentifiersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'own_identifiers';
  @override
  VerificationContext validateIntegrity(
    Insertable<OwnIdentifier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OwnIdentifier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OwnIdentifier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $OwnIdentifiersTable createAlias(String alias) {
    return $OwnIdentifiersTable(attachedDatabase, alias);
  }
}

class OwnIdentifier extends DataClass implements Insertable<OwnIdentifier> {
  final String id;
  final String value;
  const OwnIdentifier({required this.id, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['value'] = Variable<String>(value);
    return map;
  }

  OwnIdentifiersCompanion toCompanion(bool nullToAbsent) {
    return OwnIdentifiersCompanion(id: Value(id), value: Value(value));
  }

  factory OwnIdentifier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OwnIdentifier(
      id: serializer.fromJson<String>(json['id']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'value': serializer.toJson<String>(value),
    };
  }

  OwnIdentifier copyWith({String? id, String? value}) =>
      OwnIdentifier(id: id ?? this.id, value: value ?? this.value);
  OwnIdentifier copyWithCompanion(OwnIdentifiersCompanion data) {
    return OwnIdentifier(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OwnIdentifier(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnIdentifier &&
          other.id == this.id &&
          other.value == this.value);
}

class OwnIdentifiersCompanion extends UpdateCompanion<OwnIdentifier> {
  final Value<String> id;
  final Value<String> value;
  final Value<int> rowid;
  const OwnIdentifiersCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OwnIdentifiersCompanion.insert({
    required String id,
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       value = Value(value);
  static Insertable<OwnIdentifier> custom({
    Expression<String>? id,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OwnIdentifiersCompanion copyWith({
    Value<String>? id,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return OwnIdentifiersCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
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
    return (StringBuffer('OwnIdentifiersCompanion(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MerchantAliasesTable extends MerchantAliases
    with TableInfo<$MerchantAliasesTable, MerchantAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MerchantAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patternMeta = const VerificationMeta(
    'pattern',
  );
  @override
  late final GeneratedColumn<String> pattern = GeneratedColumn<String>(
    'pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, pattern, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'merchant_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<MerchantAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pattern')) {
      context.handle(
        _patternMeta,
        pattern.isAcceptableOrUnknown(data['pattern']!, _patternMeta),
      );
    } else if (isInserting) {
      context.missing(_patternMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MerchantAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MerchantAliase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
    );
  }

  @override
  $MerchantAliasesTable createAlias(String alias) {
    return $MerchantAliasesTable(attachedDatabase, alias);
  }
}

class MerchantAliase extends DataClass implements Insertable<MerchantAliase> {
  final String id;
  final String pattern;
  final String displayName;
  const MerchantAliase({
    required this.id,
    required this.pattern,
    required this.displayName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pattern'] = Variable<String>(pattern);
    map['display_name'] = Variable<String>(displayName);
    return map;
  }

  MerchantAliasesCompanion toCompanion(bool nullToAbsent) {
    return MerchantAliasesCompanion(
      id: Value(id),
      pattern: Value(pattern),
      displayName: Value(displayName),
    );
  }

  factory MerchantAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MerchantAliase(
      id: serializer.fromJson<String>(json['id']),
      pattern: serializer.fromJson<String>(json['pattern']),
      displayName: serializer.fromJson<String>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pattern': serializer.toJson<String>(pattern),
      'displayName': serializer.toJson<String>(displayName),
    };
  }

  MerchantAliase copyWith({String? id, String? pattern, String? displayName}) =>
      MerchantAliase(
        id: id ?? this.id,
        pattern: pattern ?? this.pattern,
        displayName: displayName ?? this.displayName,
      );
  MerchantAliase copyWithCompanion(MerchantAliasesCompanion data) {
    return MerchantAliase(
      id: data.id.present ? data.id.value : this.id,
      pattern: data.pattern.present ? data.pattern.value : this.pattern,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MerchantAliase(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pattern, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MerchantAliase &&
          other.id == this.id &&
          other.pattern == this.pattern &&
          other.displayName == this.displayName);
}

class MerchantAliasesCompanion extends UpdateCompanion<MerchantAliase> {
  final Value<String> id;
  final Value<String> pattern;
  final Value<String> displayName;
  final Value<int> rowid;
  const MerchantAliasesCompanion({
    this.id = const Value.absent(),
    this.pattern = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MerchantAliasesCompanion.insert({
    required String id,
    required String pattern,
    required String displayName,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pattern = Value(pattern),
       displayName = Value(displayName);
  static Insertable<MerchantAliase> custom({
    Expression<String>? id,
    Expression<String>? pattern,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pattern != null) 'pattern': pattern,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MerchantAliasesCompanion copyWith({
    Value<String>? id,
    Value<String>? pattern,
    Value<String>? displayName,
    Value<int>? rowid,
  }) {
    return MerchantAliasesCompanion(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pattern.present) {
      map['pattern'] = Variable<String>(pattern.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MerchantAliasesCompanion(')
          ..write('id: $id, ')
          ..write('pattern: $pattern, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitSharesTable extends SplitShares
    with TableInfo<$SplitSharesTable, SplitShare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id)',
    ),
  );
  static const VerificationMeta _personNameMeta = const VerificationMeta(
    'personName',
  );
  @override
  late final GeneratedColumn<String> personName = GeneratedColumn<String>(
    'person_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareMinorMeta = const VerificationMeta(
    'shareMinor',
  );
  @override
  late final GeneratedColumn<int> shareMinor = GeneratedColumn<int>(
    'share_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settledMeta = const VerificationMeta(
    'settled',
  );
  @override
  late final GeneratedColumn<bool> settled = GeneratedColumn<bool>(
    'settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    personName,
    shareMinor,
    settled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_shares';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitShare> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('person_name')) {
      context.handle(
        _personNameMeta,
        personName.isAcceptableOrUnknown(data['person_name']!, _personNameMeta),
      );
    } else if (isInserting) {
      context.missing(_personNameMeta);
    }
    if (data.containsKey('share_minor')) {
      context.handle(
        _shareMinorMeta,
        shareMinor.isAcceptableOrUnknown(data['share_minor']!, _shareMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_shareMinorMeta);
    }
    if (data.containsKey('settled')) {
      context.handle(
        _settledMeta,
        settled.isAcceptableOrUnknown(data['settled']!, _settledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitShare map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitShare(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      personName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_name'],
      )!,
      shareMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}share_minor'],
      )!,
      settled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}settled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SplitSharesTable createAlias(String alias) {
    return $SplitSharesTable(attachedDatabase, alias);
  }
}

class SplitShare extends DataClass implements Insertable<SplitShare> {
  final String id;
  final String transactionId;
  final String personName;
  final int shareMinor;
  final bool settled;
  final DateTime createdAt;
  const SplitShare({
    required this.id,
    required this.transactionId,
    required this.personName,
    required this.shareMinor,
    required this.settled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['person_name'] = Variable<String>(personName);
    map['share_minor'] = Variable<int>(shareMinor);
    map['settled'] = Variable<bool>(settled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SplitSharesCompanion toCompanion(bool nullToAbsent) {
    return SplitSharesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      personName: Value(personName),
      shareMinor: Value(shareMinor),
      settled: Value(settled),
      createdAt: Value(createdAt),
    );
  }

  factory SplitShare.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitShare(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      personName: serializer.fromJson<String>(json['personName']),
      shareMinor: serializer.fromJson<int>(json['shareMinor']),
      settled: serializer.fromJson<bool>(json['settled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'personName': serializer.toJson<String>(personName),
      'shareMinor': serializer.toJson<int>(shareMinor),
      'settled': serializer.toJson<bool>(settled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SplitShare copyWith({
    String? id,
    String? transactionId,
    String? personName,
    int? shareMinor,
    bool? settled,
    DateTime? createdAt,
  }) => SplitShare(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    personName: personName ?? this.personName,
    shareMinor: shareMinor ?? this.shareMinor,
    settled: settled ?? this.settled,
    createdAt: createdAt ?? this.createdAt,
  );
  SplitShare copyWithCompanion(SplitSharesCompanion data) {
    return SplitShare(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      personName: data.personName.present
          ? data.personName.value
          : this.personName,
      shareMinor: data.shareMinor.present
          ? data.shareMinor.value
          : this.shareMinor,
      settled: data.settled.present ? data.settled.value : this.settled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitShare(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('personName: $personName, ')
          ..write('shareMinor: $shareMinor, ')
          ..write('settled: $settled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    personName,
    shareMinor,
    settled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitShare &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.personName == this.personName &&
          other.shareMinor == this.shareMinor &&
          other.settled == this.settled &&
          other.createdAt == this.createdAt);
}

class SplitSharesCompanion extends UpdateCompanion<SplitShare> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String> personName;
  final Value<int> shareMinor;
  final Value<bool> settled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SplitSharesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.personName = const Value.absent(),
    this.shareMinor = const Value.absent(),
    this.settled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitSharesCompanion.insert({
    required String id,
    required String transactionId,
    required String personName,
    required int shareMinor,
    this.settled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       personName = Value(personName),
       shareMinor = Value(shareMinor);
  static Insertable<SplitShare> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? personName,
    Expression<int>? shareMinor,
    Expression<bool>? settled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (personName != null) 'person_name': personName,
      if (shareMinor != null) 'share_minor': shareMinor,
      if (settled != null) 'settled': settled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitSharesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String>? personName,
    Value<int>? shareMinor,
    Value<bool>? settled,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SplitSharesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      personName: personName ?? this.personName,
      shareMinor: shareMinor ?? this.shareMinor,
      settled: settled ?? this.settled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (personName.present) {
      map['person_name'] = Variable<String>(personName.value);
    }
    if (shareMinor.present) {
      map['share_minor'] = Variable<int>(shareMinor.value);
    }
    if (settled.present) {
      map['settled'] = Variable<bool>(settled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitSharesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('personName: $personName, ')
          ..write('shareMinor: $shareMinor, ')
          ..write('settled: $settled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UnparsedMessagesTable extends UnparsedMessages
    with TableInfo<$UnparsedMessagesTable, UnparsedMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnparsedMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderCodeMeta = const VerificationMeta(
    'senderCode',
  );
  @override
  late final GeneratedColumn<String> senderCode = GeneratedColumn<String>(
    'sender_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextEncryptedMeta = const VerificationMeta(
    'rawTextEncrypted',
  );
  @override
  late final GeneratedColumn<String> rawTextEncrypted = GeneratedColumn<String>(
    'raw_text_encrypted',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedMeta = const VerificationMeta(
    'resolved',
  );
  @override
  late final GeneratedColumn<bool> resolved = GeneratedColumn<bool>(
    'resolved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("resolved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    source,
    senderCode,
    rawTextEncrypted,
    hash,
    receivedAt,
    resolved,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'unparsed_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<UnparsedMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('sender_code')) {
      context.handle(
        _senderCodeMeta,
        senderCode.isAcceptableOrUnknown(data['sender_code']!, _senderCodeMeta),
      );
    }
    if (data.containsKey('raw_text_encrypted')) {
      context.handle(
        _rawTextEncryptedMeta,
        rawTextEncrypted.isAcceptableOrUnknown(
          data['raw_text_encrypted']!,
          _rawTextEncryptedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawTextEncryptedMeta);
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('resolved')) {
      context.handle(
        _resolvedMeta,
        resolved.isAcceptableOrUnknown(data['resolved']!, _resolvedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnparsedMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnparsedMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      senderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_code'],
      ),
      rawTextEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text_encrypted'],
      )!,
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      resolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}resolved'],
      )!,
    );
  }

  @override
  $UnparsedMessagesTable createAlias(String alias) {
    return $UnparsedMessagesTable(attachedDatabase, alias);
  }
}

class UnparsedMessage extends DataClass implements Insertable<UnparsedMessage> {
  final String id;
  final String source;
  final String? senderCode;
  final String rawTextEncrypted;
  final String hash;
  final DateTime receivedAt;
  final bool resolved;
  const UnparsedMessage({
    required this.id,
    required this.source,
    this.senderCode,
    required this.rawTextEncrypted,
    required this.hash,
    required this.receivedAt,
    required this.resolved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || senderCode != null) {
      map['sender_code'] = Variable<String>(senderCode);
    }
    map['raw_text_encrypted'] = Variable<String>(rawTextEncrypted);
    map['hash'] = Variable<String>(hash);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['resolved'] = Variable<bool>(resolved);
    return map;
  }

  UnparsedMessagesCompanion toCompanion(bool nullToAbsent) {
    return UnparsedMessagesCompanion(
      id: Value(id),
      source: Value(source),
      senderCode: senderCode == null && nullToAbsent
          ? const Value.absent()
          : Value(senderCode),
      rawTextEncrypted: Value(rawTextEncrypted),
      hash: Value(hash),
      receivedAt: Value(receivedAt),
      resolved: Value(resolved),
    );
  }

  factory UnparsedMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnparsedMessage(
      id: serializer.fromJson<String>(json['id']),
      source: serializer.fromJson<String>(json['source']),
      senderCode: serializer.fromJson<String?>(json['senderCode']),
      rawTextEncrypted: serializer.fromJson<String>(json['rawTextEncrypted']),
      hash: serializer.fromJson<String>(json['hash']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      resolved: serializer.fromJson<bool>(json['resolved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'source': serializer.toJson<String>(source),
      'senderCode': serializer.toJson<String?>(senderCode),
      'rawTextEncrypted': serializer.toJson<String>(rawTextEncrypted),
      'hash': serializer.toJson<String>(hash),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'resolved': serializer.toJson<bool>(resolved),
    };
  }

  UnparsedMessage copyWith({
    String? id,
    String? source,
    Value<String?> senderCode = const Value.absent(),
    String? rawTextEncrypted,
    String? hash,
    DateTime? receivedAt,
    bool? resolved,
  }) => UnparsedMessage(
    id: id ?? this.id,
    source: source ?? this.source,
    senderCode: senderCode.present ? senderCode.value : this.senderCode,
    rawTextEncrypted: rawTextEncrypted ?? this.rawTextEncrypted,
    hash: hash ?? this.hash,
    receivedAt: receivedAt ?? this.receivedAt,
    resolved: resolved ?? this.resolved,
  );
  UnparsedMessage copyWithCompanion(UnparsedMessagesCompanion data) {
    return UnparsedMessage(
      id: data.id.present ? data.id.value : this.id,
      source: data.source.present ? data.source.value : this.source,
      senderCode: data.senderCode.present
          ? data.senderCode.value
          : this.senderCode,
      rawTextEncrypted: data.rawTextEncrypted.present
          ? data.rawTextEncrypted.value
          : this.rawTextEncrypted,
      hash: data.hash.present ? data.hash.value : this.hash,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      resolved: data.resolved.present ? data.resolved.value : this.resolved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnparsedMessage(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('senderCode: $senderCode, ')
          ..write('rawTextEncrypted: $rawTextEncrypted, ')
          ..write('hash: $hash, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('resolved: $resolved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    source,
    senderCode,
    rawTextEncrypted,
    hash,
    receivedAt,
    resolved,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnparsedMessage &&
          other.id == this.id &&
          other.source == this.source &&
          other.senderCode == this.senderCode &&
          other.rawTextEncrypted == this.rawTextEncrypted &&
          other.hash == this.hash &&
          other.receivedAt == this.receivedAt &&
          other.resolved == this.resolved);
}

class UnparsedMessagesCompanion extends UpdateCompanion<UnparsedMessage> {
  final Value<String> id;
  final Value<String> source;
  final Value<String?> senderCode;
  final Value<String> rawTextEncrypted;
  final Value<String> hash;
  final Value<DateTime> receivedAt;
  final Value<bool> resolved;
  final Value<int> rowid;
  const UnparsedMessagesCompanion({
    this.id = const Value.absent(),
    this.source = const Value.absent(),
    this.senderCode = const Value.absent(),
    this.rawTextEncrypted = const Value.absent(),
    this.hash = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.resolved = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UnparsedMessagesCompanion.insert({
    required String id,
    required String source,
    this.senderCode = const Value.absent(),
    required String rawTextEncrypted,
    required String hash,
    required DateTime receivedAt,
    this.resolved = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       rawTextEncrypted = Value(rawTextEncrypted),
       hash = Value(hash),
       receivedAt = Value(receivedAt);
  static Insertable<UnparsedMessage> custom({
    Expression<String>? id,
    Expression<String>? source,
    Expression<String>? senderCode,
    Expression<String>? rawTextEncrypted,
    Expression<String>? hash,
    Expression<DateTime>? receivedAt,
    Expression<bool>? resolved,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (source != null) 'source': source,
      if (senderCode != null) 'sender_code': senderCode,
      if (rawTextEncrypted != null) 'raw_text_encrypted': rawTextEncrypted,
      if (hash != null) 'hash': hash,
      if (receivedAt != null) 'received_at': receivedAt,
      if (resolved != null) 'resolved': resolved,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UnparsedMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? source,
    Value<String?>? senderCode,
    Value<String>? rawTextEncrypted,
    Value<String>? hash,
    Value<DateTime>? receivedAt,
    Value<bool>? resolved,
    Value<int>? rowid,
  }) {
    return UnparsedMessagesCompanion(
      id: id ?? this.id,
      source: source ?? this.source,
      senderCode: senderCode ?? this.senderCode,
      rawTextEncrypted: rawTextEncrypted ?? this.rawTextEncrypted,
      hash: hash ?? this.hash,
      receivedAt: receivedAt ?? this.receivedAt,
      resolved: resolved ?? this.resolved,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (senderCode.present) {
      map['sender_code'] = Variable<String>(senderCode.value);
    }
    if (rawTextEncrypted.present) {
      map['raw_text_encrypted'] = Variable<String>(rawTextEncrypted.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (resolved.present) {
      map['resolved'] = Variable<bool>(resolved.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnparsedMessagesCompanion(')
          ..write('id: $id, ')
          ..write('source: $source, ')
          ..write('senderCode: $senderCode, ')
          ..write('rawTextEncrypted: $rawTextEncrypted, ')
          ..write('hash: $hash, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('resolved: $resolved, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LendingEntriesTable extends LendingEntries
    with TableInfo<$LendingEntriesTable, LendingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LendingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    person,
    direction,
    amountMinor,
    date,
    dueDate,
    note,
    isSettled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lending_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LendingEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    } else if (isInserting) {
      context.missing(_personMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LendingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LendingEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LendingEntriesTable createAlias(String alias) {
    return $LendingEntriesTable(attachedDatabase, alias);
  }
}

class LendingEntry extends DataClass implements Insertable<LendingEntry> {
  final String id;
  final String person;

  /// lent (they owe the user) | borrowed (the user owes them).
  final String direction;
  final int amountMinor;
  final DateTime date;
  final DateTime? dueDate;
  final String? note;
  final bool isSettled;
  final DateTime createdAt;
  const LendingEntry({
    required this.id,
    required this.person,
    required this.direction,
    required this.amountMinor,
    required this.date,
    this.dueDate,
    this.note,
    required this.isSettled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['person'] = Variable<String>(person);
    map['direction'] = Variable<String>(direction);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_settled'] = Variable<bool>(isSettled);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LendingEntriesCompanion toCompanion(bool nullToAbsent) {
    return LendingEntriesCompanion(
      id: Value(id),
      person: Value(person),
      direction: Value(direction),
      amountMinor: Value(amountMinor),
      date: Value(date),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isSettled: Value(isSettled),
      createdAt: Value(createdAt),
    );
  }

  factory LendingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LendingEntry(
      id: serializer.fromJson<String>(json['id']),
      person: serializer.fromJson<String>(json['person']),
      direction: serializer.fromJson<String>(json['direction']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      date: serializer.fromJson<DateTime>(json['date']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      note: serializer.fromJson<String?>(json['note']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'person': serializer.toJson<String>(person),
      'direction': serializer.toJson<String>(direction),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'date': serializer.toJson<DateTime>(date),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'note': serializer.toJson<String?>(note),
      'isSettled': serializer.toJson<bool>(isSettled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LendingEntry copyWith({
    String? id,
    String? person,
    String? direction,
    int? amountMinor,
    DateTime? date,
    Value<DateTime?> dueDate = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? isSettled,
    DateTime? createdAt,
  }) => LendingEntry(
    id: id ?? this.id,
    person: person ?? this.person,
    direction: direction ?? this.direction,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    note: note.present ? note.value : this.note,
    isSettled: isSettled ?? this.isSettled,
    createdAt: createdAt ?? this.createdAt,
  );
  LendingEntry copyWithCompanion(LendingEntriesCompanion data) {
    return LendingEntry(
      id: data.id.present ? data.id.value : this.id,
      person: data.person.present ? data.person.value : this.person,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      date: data.date.present ? data.date.value : this.date,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      note: data.note.present ? data.note.value : this.note,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LendingEntry(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('direction: $direction, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('isSettled: $isSettled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    person,
    direction,
    amountMinor,
    date,
    dueDate,
    note,
    isSettled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LendingEntry &&
          other.id == this.id &&
          other.person == this.person &&
          other.direction == this.direction &&
          other.amountMinor == this.amountMinor &&
          other.date == this.date &&
          other.dueDate == this.dueDate &&
          other.note == this.note &&
          other.isSettled == this.isSettled &&
          other.createdAt == this.createdAt);
}

class LendingEntriesCompanion extends UpdateCompanion<LendingEntry> {
  final Value<String> id;
  final Value<String> person;
  final Value<String> direction;
  final Value<int> amountMinor;
  final Value<DateTime> date;
  final Value<DateTime?> dueDate;
  final Value<String?> note;
  final Value<bool> isSettled;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LendingEntriesCompanion({
    this.id = const Value.absent(),
    this.person = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.date = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LendingEntriesCompanion.insert({
    required String id,
    required String person,
    required String direction,
    required int amountMinor,
    required DateTime date,
    this.dueDate = const Value.absent(),
    this.note = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       person = Value(person),
       direction = Value(direction),
       amountMinor = Value(amountMinor),
       date = Value(date);
  static Insertable<LendingEntry> custom({
    Expression<String>? id,
    Expression<String>? person,
    Expression<String>? direction,
    Expression<int>? amountMinor,
    Expression<DateTime>? date,
    Expression<DateTime>? dueDate,
    Expression<String>? note,
    Expression<bool>? isSettled,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (person != null) 'person': person,
      if (direction != null) 'direction': direction,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (date != null) 'date': date,
      if (dueDate != null) 'due_date': dueDate,
      if (note != null) 'note': note,
      if (isSettled != null) 'is_settled': isSettled,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LendingEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? person,
    Value<String>? direction,
    Value<int>? amountMinor,
    Value<DateTime>? date,
    Value<DateTime?>? dueDate,
    Value<String?>? note,
    Value<bool>? isSettled,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LendingEntriesCompanion(
      id: id ?? this.id,
      person: person ?? this.person,
      direction: direction ?? this.direction,
      amountMinor: amountMinor ?? this.amountMinor,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      isSettled: isSettled ?? this.isSettled,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LendingEntriesCompanion(')
          ..write('id: $id, ')
          ..write('person: $person, ')
          ..write('direction: $direction, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('dueDate: $dueDate, ')
          ..write('note: $note, ')
          ..write('isSettled: $isSettled, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LendingPaymentsTable extends LendingPayments
    with TableInfo<$LendingPaymentsTable, LendingPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LendingPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lending_entries (id)',
    ),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, entryId, amountMinor, date, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lending_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LendingPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LendingPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LendingPayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $LendingPaymentsTable createAlias(String alias) {
    return $LendingPaymentsTable(attachedDatabase, alias);
  }
}

class LendingPayment extends DataClass implements Insertable<LendingPayment> {
  final String id;
  final String entryId;
  final int amountMinor;
  final DateTime date;
  final String? note;
  const LendingPayment({
    required this.id,
    required this.entryId,
    required this.amountMinor,
    required this.date,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LendingPaymentsCompanion toCompanion(bool nullToAbsent) {
    return LendingPaymentsCompanion(
      id: Value(id),
      entryId: Value(entryId),
      amountMinor: Value(amountMinor),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory LendingPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LendingPayment(
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String?>(note),
    };
  }

  LendingPayment copyWith({
    String? id,
    String? entryId,
    int? amountMinor,
    DateTime? date,
    Value<String?> note = const Value.absent(),
  }) => LendingPayment(
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
  );
  LendingPayment copyWithCompanion(LendingPaymentsCompanion data) {
    return LendingPayment(
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LendingPayment(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entryId, amountMinor, date, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LendingPayment &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.amountMinor == this.amountMinor &&
          other.date == this.date &&
          other.note == this.note);
}

class LendingPaymentsCompanion extends UpdateCompanion<LendingPayment> {
  final Value<String> id;
  final Value<String> entryId;
  final Value<int> amountMinor;
  final Value<DateTime> date;
  final Value<String?> note;
  final Value<int> rowid;
  const LendingPaymentsCompanion({
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LendingPaymentsCompanion.insert({
    required String id,
    required String entryId,
    required int amountMinor,
    required DateTime date,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryId = Value(entryId),
       amountMinor = Value(amountMinor),
       date = Value(date);
  static Insertable<LendingPayment> custom({
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<int>? amountMinor,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LendingPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? entryId,
    Value<int>? amountMinor,
    Value<DateTime>? date,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return LendingPaymentsCompanion(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      amountMinor: amountMinor ?? this.amountMinor,
      date: date ?? this.date,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LendingPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParserTemplatesTable extends ParserTemplates
    with TableInfo<$ParserTemplatesTable, ParserTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParserTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderCodeMeta = const VerificationMeta(
    'senderCode',
  );
  @override
  late final GeneratedColumn<String> senderCode = GeneratedColumn<String>(
    'sender_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _patternEncryptedMeta = const VerificationMeta(
    'patternEncrypted',
  );
  @override
  late final GeneratedColumn<String> patternEncrypted = GeneratedColumn<String>(
    'pattern_encrypted',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hitsMeta = const VerificationMeta('hits');
  @override
  late final GeneratedColumn<int> hits = GeneratedColumn<int>(
    'hits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    senderCode,
    patternEncrypted,
    type,
    hits,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parser_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParserTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sender_code')) {
      context.handle(
        _senderCodeMeta,
        senderCode.isAcceptableOrUnknown(data['sender_code']!, _senderCodeMeta),
      );
    }
    if (data.containsKey('pattern_encrypted')) {
      context.handle(
        _patternEncryptedMeta,
        patternEncrypted.isAcceptableOrUnknown(
          data['pattern_encrypted']!,
          _patternEncryptedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patternEncryptedMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('hits')) {
      context.handle(
        _hitsMeta,
        hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParserTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParserTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      senderCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_code'],
      ),
      patternEncrypted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pattern_encrypted'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      hits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ParserTemplatesTable createAlias(String alias) {
    return $ParserTemplatesTable(attachedDatabase, alias);
  }
}

class ParserTemplate extends DataClass implements Insertable<ParserTemplate> {
  final String id;
  final String? senderCode;
  final String patternEncrypted;

  /// debit | credit
  final String type;

  /// How many later messages this template has handled.
  final int hits;
  final DateTime createdAt;
  const ParserTemplate({
    required this.id,
    this.senderCode,
    required this.patternEncrypted,
    required this.type,
    required this.hits,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || senderCode != null) {
      map['sender_code'] = Variable<String>(senderCode);
    }
    map['pattern_encrypted'] = Variable<String>(patternEncrypted);
    map['type'] = Variable<String>(type);
    map['hits'] = Variable<int>(hits);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ParserTemplatesCompanion toCompanion(bool nullToAbsent) {
    return ParserTemplatesCompanion(
      id: Value(id),
      senderCode: senderCode == null && nullToAbsent
          ? const Value.absent()
          : Value(senderCode),
      patternEncrypted: Value(patternEncrypted),
      type: Value(type),
      hits: Value(hits),
      createdAt: Value(createdAt),
    );
  }

  factory ParserTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParserTemplate(
      id: serializer.fromJson<String>(json['id']),
      senderCode: serializer.fromJson<String?>(json['senderCode']),
      patternEncrypted: serializer.fromJson<String>(json['patternEncrypted']),
      type: serializer.fromJson<String>(json['type']),
      hits: serializer.fromJson<int>(json['hits']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'senderCode': serializer.toJson<String?>(senderCode),
      'patternEncrypted': serializer.toJson<String>(patternEncrypted),
      'type': serializer.toJson<String>(type),
      'hits': serializer.toJson<int>(hits),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ParserTemplate copyWith({
    String? id,
    Value<String?> senderCode = const Value.absent(),
    String? patternEncrypted,
    String? type,
    int? hits,
    DateTime? createdAt,
  }) => ParserTemplate(
    id: id ?? this.id,
    senderCode: senderCode.present ? senderCode.value : this.senderCode,
    patternEncrypted: patternEncrypted ?? this.patternEncrypted,
    type: type ?? this.type,
    hits: hits ?? this.hits,
    createdAt: createdAt ?? this.createdAt,
  );
  ParserTemplate copyWithCompanion(ParserTemplatesCompanion data) {
    return ParserTemplate(
      id: data.id.present ? data.id.value : this.id,
      senderCode: data.senderCode.present
          ? data.senderCode.value
          : this.senderCode,
      patternEncrypted: data.patternEncrypted.present
          ? data.patternEncrypted.value
          : this.patternEncrypted,
      type: data.type.present ? data.type.value : this.type,
      hits: data.hits.present ? data.hits.value : this.hits,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParserTemplate(')
          ..write('id: $id, ')
          ..write('senderCode: $senderCode, ')
          ..write('patternEncrypted: $patternEncrypted, ')
          ..write('type: $type, ')
          ..write('hits: $hits, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, senderCode, patternEncrypted, type, hits, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParserTemplate &&
          other.id == this.id &&
          other.senderCode == this.senderCode &&
          other.patternEncrypted == this.patternEncrypted &&
          other.type == this.type &&
          other.hits == this.hits &&
          other.createdAt == this.createdAt);
}

class ParserTemplatesCompanion extends UpdateCompanion<ParserTemplate> {
  final Value<String> id;
  final Value<String?> senderCode;
  final Value<String> patternEncrypted;
  final Value<String> type;
  final Value<int> hits;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ParserTemplatesCompanion({
    this.id = const Value.absent(),
    this.senderCode = const Value.absent(),
    this.patternEncrypted = const Value.absent(),
    this.type = const Value.absent(),
    this.hits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParserTemplatesCompanion.insert({
    required String id,
    this.senderCode = const Value.absent(),
    required String patternEncrypted,
    required String type,
    this.hits = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patternEncrypted = Value(patternEncrypted),
       type = Value(type);
  static Insertable<ParserTemplate> custom({
    Expression<String>? id,
    Expression<String>? senderCode,
    Expression<String>? patternEncrypted,
    Expression<String>? type,
    Expression<int>? hits,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (senderCode != null) 'sender_code': senderCode,
      if (patternEncrypted != null) 'pattern_encrypted': patternEncrypted,
      if (type != null) 'type': type,
      if (hits != null) 'hits': hits,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParserTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String?>? senderCode,
    Value<String>? patternEncrypted,
    Value<String>? type,
    Value<int>? hits,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ParserTemplatesCompanion(
      id: id ?? this.id,
      senderCode: senderCode ?? this.senderCode,
      patternEncrypted: patternEncrypted ?? this.patternEncrypted,
      type: type ?? this.type,
      hits: hits ?? this.hits,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (senderCode.present) {
      map['sender_code'] = Variable<String>(senderCode.value);
    }
    if (patternEncrypted.present) {
      map['pattern_encrypted'] = Variable<String>(patternEncrypted.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (hits.present) {
      map['hits'] = Variable<int>(hits.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParserTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('senderCode: $senderCode, ')
          ..write('patternEncrypted: $patternEncrypted, ')
          ..write('type: $type, ')
          ..write('hits: $hits, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetOverridesTable extends BudgetOverrides
    with TableInfo<$BudgetOverridesTable, BudgetOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitMinorMeta = const VerificationMeta(
    'limitMinor',
  );
  @override
  late final GeneratedColumn<int> limitMinor = GeneratedColumn<int>(
    'limit_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, categoryId, monthKey, limitMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('limit_minor')) {
      context.handle(
        _limitMinorMeta,
        limitMinor.isAcceptableOrUnknown(data['limit_minor']!, _limitMinorMeta),
      );
    } else if (isInserting) {
      context.missing(_limitMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetOverride(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      limitMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_minor'],
      )!,
    );
  }

  @override
  $BudgetOverridesTable createAlias(String alias) {
    return $BudgetOverridesTable(attachedDatabase, alias);
  }
}

class BudgetOverride extends DataClass implements Insertable<BudgetOverride> {
  final String id;
  final String categoryId;

  /// "2026-10".
  final String monthKey;
  final int limitMinor;
  const BudgetOverride({
    required this.id,
    required this.categoryId,
    required this.monthKey,
    required this.limitMinor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['month_key'] = Variable<String>(monthKey);
    map['limit_minor'] = Variable<int>(limitMinor);
    return map;
  }

  BudgetOverridesCompanion toCompanion(bool nullToAbsent) {
    return BudgetOverridesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      monthKey: Value(monthKey),
      limitMinor: Value(limitMinor),
    );
  }

  factory BudgetOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetOverride(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      limitMinor: serializer.fromJson<int>(json['limitMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'monthKey': serializer.toJson<String>(monthKey),
      'limitMinor': serializer.toJson<int>(limitMinor),
    };
  }

  BudgetOverride copyWith({
    String? id,
    String? categoryId,
    String? monthKey,
    int? limitMinor,
  }) => BudgetOverride(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    monthKey: monthKey ?? this.monthKey,
    limitMinor: limitMinor ?? this.limitMinor,
  );
  BudgetOverride copyWithCompanion(BudgetOverridesCompanion data) {
    return BudgetOverride(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      limitMinor: data.limitMinor.present
          ? data.limitMinor.value
          : this.limitMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetOverride(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthKey: $monthKey, ')
          ..write('limitMinor: $limitMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, monthKey, limitMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetOverride &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.monthKey == this.monthKey &&
          other.limitMinor == this.limitMinor);
}

class BudgetOverridesCompanion extends UpdateCompanion<BudgetOverride> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> monthKey;
  final Value<int> limitMinor;
  final Value<int> rowid;
  const BudgetOverridesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.limitMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetOverridesCompanion.insert({
    required String id,
    required String categoryId,
    required String monthKey,
    required int limitMinor,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       monthKey = Value(monthKey),
       limitMinor = Value(limitMinor);
  static Insertable<BudgetOverride> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? monthKey,
    Expression<int>? limitMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (monthKey != null) 'month_key': monthKey,
      if (limitMinor != null) 'limit_minor': limitMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetOverridesCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? monthKey,
    Value<int>? limitMinor,
    Value<int>? rowid,
  }) {
    return BudgetOverridesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      monthKey: monthKey ?? this.monthKey,
      limitMinor: limitMinor ?? this.limitMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (limitMinor.present) {
      map['limit_minor'] = Variable<int>(limitMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetOverridesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('monthKey: $monthKey, ')
          ..write('limitMinor: $limitMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RecurringGroupsTable recurringGroups = $RecurringGroupsTable(
    this,
  );
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $RulesTable rules = $RulesTable(this);
  late final $AlertsTable alerts = $AlertsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $OwnIdentifiersTable ownIdentifiers = $OwnIdentifiersTable(this);
  late final $MerchantAliasesTable merchantAliases = $MerchantAliasesTable(
    this,
  );
  late final $SplitSharesTable splitShares = $SplitSharesTable(this);
  late final $UnparsedMessagesTable unparsedMessages = $UnparsedMessagesTable(
    this,
  );
  late final $LendingEntriesTable lendingEntries = $LendingEntriesTable(this);
  late final $LendingPaymentsTable lendingPayments = $LendingPaymentsTable(
    this,
  );
  late final $ParserTemplatesTable parserTemplates = $ParserTemplatesTable(
    this,
  );
  late final $BudgetOverridesTable budgetOverrides = $BudgetOverridesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    recurringGroups,
    transactions,
    rules,
    alerts,
    budgets,
    appSettings,
    ownIdentifiers,
    merchantAliases,
    splitShares,
    unparsedMessages,
    lendingEntries,
    lendingPayments,
    parserTemplates,
    budgetOverrides,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String name,
  Value<String?> bankName,
  Value<String?> last4,
  required String accountType,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> bankName,
  Value<String?> last4,
  Value<String> accountType,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__id__transactions__account_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                bankName: bankName,
                last4: last4,
                accountType: accountType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> bankName = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                required String accountType,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                bankName: bankName,
                last4: last4,
                accountType: accountType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      Account,
                      $AccountsTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String?> icon,
  Value<String?> parentId,
  Value<bool> isDefault,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> icon,
  Value<String?> parentId,
  Value<bool> isDefault,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias('categories__parent_id__categories__id');

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RulesTable, List<Rule>> _rulesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rules,
    aliasName: 'categories__id__rules__category_id',
  );

  $$RulesTableProcessedTableManager get rulesRefs {
    final manager = $$RulesTableTableManager(
      $_db,
      $_db.rules,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetOverridesTable, List<BudgetOverride>>
  _budgetOverridesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.budgetOverrides,
    aliasName: 'categories__id__budget_overrides__category_id',
  );

  $$BudgetOverridesTableProcessedTableManager get budgetOverridesRefs {
    final manager = $$BudgetOverridesTableTableManager(
      $_db,
      $_db.budgetOverrides,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _budgetOverridesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rulesRefs(
    Expression<bool> Function($$RulesTableFilterComposer f) f,
  ) {
    final $$RulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RulesTableFilterComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetOverridesRefs(
    Expression<bool> Function($$BudgetOverridesTableFilterComposer f) f,
  ) {
    final $$BudgetOverridesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetOverrides,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetOverridesTableFilterComposer(
            $db: $db,
            $table: $db.budgetOverrides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rulesRefs<T extends Object>(
    Expression<T> Function($$RulesTableAnnotationComposer a) f,
  ) {
    final $$RulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rules,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RulesTableAnnotationComposer(
            $db: $db,
            $table: $db.rules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetOverridesRefs<T extends Object>(
    Expression<T> Function($$BudgetOverridesTableAnnotationComposer a) f,
  ) {
    final $$BudgetOverridesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetOverrides,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetOverridesTableAnnotationComposer(
            $db: $db,
            $table: $db.budgetOverrides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function({
            bool parentId,
            bool transactionsRefs,
            bool rulesRefs,
            bool budgetsRefs,
            bool budgetOverridesRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                icon: icon,
                parentId: parentId,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                parentId: parentId,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                transactionsRefs = false,
                rulesRefs = false,
                budgetsRefs = false,
                budgetOverridesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (rulesRefs) db.rules,
                    if (budgetsRefs) db.budgets,
                    if (budgetOverridesRefs) db.budgetOverrides,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$CategoriesTableReferences
                                ._parentIdTable(db),
                            referencedColumn: $$CategoriesTableReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rulesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Rule
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._rulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).rulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetOverridesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          BudgetOverride
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetOverridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetOverridesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function({
        bool parentId,
        bool transactionsRefs,
        bool rulesRefs,
        bool budgetsRefs,
        bool budgetOverridesRefs,
      })
    >;
typedef $$RecurringGroupsTableCreateCompanionBuilder =
    RecurringGroupsCompanion Function({
      required String id,
      required String merchantPattern,
      required int expectedAmountMinor,
      required int intervalDays,
      required DateTime nextExpectedDate,
      Value<DateTime?> lastConfirmedAt,
      Value<int> rowid,
    });
typedef $$RecurringGroupsTableUpdateCompanionBuilder =
    RecurringGroupsCompanion Function({
      Value<String> id,
      Value<String> merchantPattern,
      Value<int> expectedAmountMinor,
      Value<int> intervalDays,
      Value<DateTime> nextExpectedDate,
      Value<DateTime?> lastConfirmedAt,
      Value<int> rowid,
    });

final class $$RecurringGroupsTableReferences
    extends
        BaseReferences<_$AppDatabase, $RecurringGroupsTable, RecurringGroup> {
  $$RecurringGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'recurring_groups__id__transactions__recurring_group_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.recurringGroupId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringGroupsTable> {
  $$RecurringGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantPattern => $composableBuilder(
    column: $table.merchantPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedAmountMinor => $composableBuilder(
    column: $table.expectedAmountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextExpectedDate => $composableBuilder(
    column: $table.nextExpectedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastConfirmedAt => $composableBuilder(
    column: $table.lastConfirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.recurringGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringGroupsTable> {
  $$RecurringGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantPattern => $composableBuilder(
    column: $table.merchantPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedAmountMinor => $composableBuilder(
    column: $table.expectedAmountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextExpectedDate => $composableBuilder(
    column: $table.nextExpectedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastConfirmedAt => $composableBuilder(
    column: $table.lastConfirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringGroupsTable> {
  $$RecurringGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get merchantPattern => $composableBuilder(
    column: $table.merchantPattern,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expectedAmountMinor => $composableBuilder(
    column: $table.expectedAmountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextExpectedDate => $composableBuilder(
    column: $table.nextExpectedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastConfirmedAt => $composableBuilder(
    column: $table.lastConfirmedAt,
    builder: (column) => column,
  );

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.recurringGroupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringGroupsTable,
          RecurringGroup,
          $$RecurringGroupsTableFilterComposer,
          $$RecurringGroupsTableOrderingComposer,
          $$RecurringGroupsTableAnnotationComposer,
          $$RecurringGroupsTableCreateCompanionBuilder,
          $$RecurringGroupsTableUpdateCompanionBuilder,
          (RecurringGroup, $$RecurringGroupsTableReferences),
          RecurringGroup,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$RecurringGroupsTableTableManager(
    _$AppDatabase db,
    $RecurringGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> merchantPattern = const Value.absent(),
                Value<int> expectedAmountMinor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<DateTime> nextExpectedDate = const Value.absent(),
                Value<DateTime?> lastConfirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringGroupsCompanion(
                id: id,
                merchantPattern: merchantPattern,
                expectedAmountMinor: expectedAmountMinor,
                intervalDays: intervalDays,
                nextExpectedDate: nextExpectedDate,
                lastConfirmedAt: lastConfirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String merchantPattern,
                required int expectedAmountMinor,
                required int intervalDays,
                required DateTime nextExpectedDate,
                Value<DateTime?> lastConfirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringGroupsCompanion.insert(
                id: id,
                merchantPattern: merchantPattern,
                expectedAmountMinor: expectedAmountMinor,
                intervalDays: intervalDays,
                nextExpectedDate: nextExpectedDate,
                lastConfirmedAt: lastConfirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringGroupsTable, RecurringGroup>(table),
                  $$RecurringGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      RecurringGroup,
                      $RecurringGroupsTable,
                      Transaction
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringGroupsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.recurringGroupId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecurringGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringGroupsTable,
      RecurringGroup,
      $$RecurringGroupsTableFilterComposer,
      $$RecurringGroupsTableOrderingComposer,
      $$RecurringGroupsTableAnnotationComposer,
      $$RecurringGroupsTableCreateCompanionBuilder,
      $$RecurringGroupsTableUpdateCompanionBuilder,
      (RecurringGroup, $$RecurringGroupsTableReferences),
      RecurringGroup,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      Value<String?> accountId,
      required int amountMinor,
      Value<String> currency,
      required String merchant,
      Value<String?> rawTextEncrypted,
      required String source,
      Value<String?> categoryId,
      required DateTime date,
      required String type,
      Value<bool> isRecurring,
      Value<String?> recurringGroupId,
      Value<bool> isInternational,
      Value<bool> isFlaggedUnusual,
      Value<bool> isDeleted,
      Value<bool> userEdited,
      Value<DateTime> createdAt,
      Value<String?> rawMerchant,
      Value<String> kind,
      Value<bool> kindLocked,
      Value<String?> transferGroupId,
      Value<String?> refundOfId,
      Value<bool> refundHint,
      Value<String?> alsoInSource,
      Value<String?> sourceHash,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String?> accountId,
      Value<int> amountMinor,
      Value<String> currency,
      Value<String> merchant,
      Value<String?> rawTextEncrypted,
      Value<String> source,
      Value<String?> categoryId,
      Value<DateTime> date,
      Value<String> type,
      Value<bool> isRecurring,
      Value<String?> recurringGroupId,
      Value<bool> isInternational,
      Value<bool> isFlaggedUnusual,
      Value<bool> isDeleted,
      Value<bool> userEdited,
      Value<DateTime> createdAt,
      Value<String?> rawMerchant,
      Value<String> kind,
      Value<bool> kindLocked,
      Value<String?> transferGroupId,
      Value<String?> refundOfId,
      Value<bool> refundHint,
      Value<String?> alsoInSource,
      Value<String?> sourceHash,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecurringGroupsTable _recurringGroupIdTable(_$AppDatabase db) => db
      .recurringGroups
      .createAlias('transactions__recurring_group_id__recurring_groups__id');

  $$RecurringGroupsTableProcessedTableManager? get recurringGroupId {
    final $_column = $_itemColumn<String>('recurring_group_id');
    if ($_column == null) return null;
    final manager = $$RecurringGroupsTableTableManager(
      $_db,
      $_db.recurringGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringGroupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AlertsTable, List<Alert>> _alertsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.alerts,
    aliasName: 'transactions__id__alerts__transaction_id',
  );

  $$AlertsTableProcessedTableManager get alertsRefs {
    final manager = $$AlertsTableTableManager(
      $_db,
      $_db.alerts,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_alertsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SplitSharesTable, List<SplitShare>>
  _splitSharesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.splitShares,
    aliasName: 'transactions__id__split_shares__transaction_id',
  );

  $$SplitSharesTableProcessedTableManager get splitSharesRefs {
    final manager = $$SplitSharesTableTableManager(
      $_db,
      $_db.splitShares,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitSharesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawTextEncrypted => $composableBuilder(
    column: $table.rawTextEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInternational => $composableBuilder(
    column: $table.isInternational,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFlaggedUnusual => $composableBuilder(
    column: $table.isFlaggedUnusual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawMerchant => $composableBuilder(
    column: $table.rawMerchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kindLocked => $composableBuilder(
    column: $table.kindLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundOfId => $composableBuilder(
    column: $table.refundOfId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get refundHint => $composableBuilder(
    column: $table.refundHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alsoInSource => $composableBuilder(
    column: $table.alsoInSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringGroupsTableFilterComposer get recurringGroupId {
    final $$RecurringGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringGroupId,
      referencedTable: $db.recurringGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringGroupsTableFilterComposer(
            $db: $db,
            $table: $db.recurringGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> alertsRefs(
    Expression<bool> Function($$AlertsTableFilterComposer f) f,
  ) {
    final $$AlertsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alerts,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableFilterComposer(
            $db: $db,
            $table: $db.alerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> splitSharesRefs(
    Expression<bool> Function($$SplitSharesTableFilterComposer f) f,
  ) {
    final $$SplitSharesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitShares,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitSharesTableFilterComposer(
            $db: $db,
            $table: $db.splitShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawTextEncrypted => $composableBuilder(
    column: $table.rawTextEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInternational => $composableBuilder(
    column: $table.isInternational,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFlaggedUnusual => $composableBuilder(
    column: $table.isFlaggedUnusual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawMerchant => $composableBuilder(
    column: $table.rawMerchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kindLocked => $composableBuilder(
    column: $table.kindLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundOfId => $composableBuilder(
    column: $table.refundOfId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get refundHint => $composableBuilder(
    column: $table.refundHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alsoInSource => $composableBuilder(
    column: $table.alsoInSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringGroupsTableOrderingComposer get recurringGroupId {
    final $$RecurringGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringGroupId,
      referencedTable: $db.recurringGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.recurringGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get rawTextEncrypted => $composableBuilder(
    column: $table.rawTextEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isInternational => $composableBuilder(
    column: $table.isInternational,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFlaggedUnusual => $composableBuilder(
    column: $table.isFlaggedUnusual,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<bool> get userEdited => $composableBuilder(
    column: $table.userEdited,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get rawMerchant => $composableBuilder(
    column: $table.rawMerchant,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get kindLocked => $composableBuilder(
    column: $table.kindLocked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refundOfId => $composableBuilder(
    column: $table.refundOfId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get refundHint => $composableBuilder(
    column: $table.refundHint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alsoInSource => $composableBuilder(
    column: $table.alsoInSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceHash => $composableBuilder(
    column: $table.sourceHash,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringGroupsTableAnnotationComposer get recurringGroupId {
    final $$RecurringGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringGroupId,
      referencedTable: $db.recurringGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> alertsRefs<T extends Object>(
    Expression<T> Function($$AlertsTableAnnotationComposer a) f,
  ) {
    final $$AlertsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.alerts,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlertsTableAnnotationComposer(
            $db: $db,
            $table: $db.alerts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> splitSharesRefs<T extends Object>(
    Expression<T> Function($$SplitSharesTableAnnotationComposer a) f,
  ) {
    final $$SplitSharesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitShares,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitSharesTableAnnotationComposer(
            $db: $db,
            $table: $db.splitShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({
            bool accountId,
            bool categoryId,
            bool recurringGroupId,
            bool alertsRefs,
            bool splitSharesRefs,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> merchant = const Value.absent(),
                Value<String?> rawTextEncrypted = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringGroupId = const Value.absent(),
                Value<bool> isInternational = const Value.absent(),
                Value<bool> isFlaggedUnusual = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> rawMerchant = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> kindLocked = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<String?> refundOfId = const Value.absent(),
                Value<bool> refundHint = const Value.absent(),
                Value<String?> alsoInSource = const Value.absent(),
                Value<String?> sourceHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                accountId: accountId,
                amountMinor: amountMinor,
                currency: currency,
                merchant: merchant,
                rawTextEncrypted: rawTextEncrypted,
                source: source,
                categoryId: categoryId,
                date: date,
                type: type,
                isRecurring: isRecurring,
                recurringGroupId: recurringGroupId,
                isInternational: isInternational,
                isFlaggedUnusual: isFlaggedUnusual,
                isDeleted: isDeleted,
                userEdited: userEdited,
                createdAt: createdAt,
                rawMerchant: rawMerchant,
                kind: kind,
                kindLocked: kindLocked,
                transferGroupId: transferGroupId,
                refundOfId: refundOfId,
                refundHint: refundHint,
                alsoInSource: alsoInSource,
                sourceHash: sourceHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> accountId = const Value.absent(),
                required int amountMinor,
                Value<String> currency = const Value.absent(),
                required String merchant,
                Value<String?> rawTextEncrypted = const Value.absent(),
                required String source,
                Value<String?> categoryId = const Value.absent(),
                required DateTime date,
                required String type,
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringGroupId = const Value.absent(),
                Value<bool> isInternational = const Value.absent(),
                Value<bool> isFlaggedUnusual = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<bool> userEdited = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> rawMerchant = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<bool> kindLocked = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<String?> refundOfId = const Value.absent(),
                Value<bool> refundHint = const Value.absent(),
                Value<String?> alsoInSource = const Value.absent(),
                Value<String?> sourceHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                amountMinor: amountMinor,
                currency: currency,
                merchant: merchant,
                rawTextEncrypted: rawTextEncrypted,
                source: source,
                categoryId: categoryId,
                date: date,
                type: type,
                isRecurring: isRecurring,
                recurringGroupId: recurringGroupId,
                isInternational: isInternational,
                isFlaggedUnusual: isFlaggedUnusual,
                isDeleted: isDeleted,
                userEdited: userEdited,
                createdAt: createdAt,
                rawMerchant: rawMerchant,
                kind: kind,
                kindLocked: kindLocked,
                transferGroupId: transferGroupId,
                refundOfId: refundOfId,
                refundHint: refundHint,
                alsoInSource: alsoInSource,
                sourceHash: sourceHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransactionsTable, Transaction>(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                categoryId = false,
                recurringGroupId = false,
                alertsRefs = false,
                splitSharesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (alertsRefs) db.alerts,
                    if (splitSharesRefs) db.splitShares,
                  ],
                  addJoins:
                      <
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
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$TransactionsTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TransactionsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (recurringGroupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.recurringGroupId,
                            referencedTable: $$TransactionsTableReferences
                                ._recurringGroupIdTable(db),
                            referencedColumn: $$TransactionsTableReferences
                                ._recurringGroupIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (alertsRefs)
                        await $_getPrefetchedData<
                          Transaction,
                          $TransactionsTable,
                          Alert
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._alertsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).alertsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (splitSharesRefs)
                        await $_getPrefetchedData<
                          Transaction,
                          $TransactionsTable,
                          SplitShare
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._splitSharesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).splitSharesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({
        bool accountId,
        bool categoryId,
        bool recurringGroupId,
        bool alertsRefs,
        bool splitSharesRefs,
      })
    >;
typedef $$RulesTableCreateCompanionBuilder = RulesCompanion Function({
  required String id,
  required String pattern,
  required String categoryId,
  Value<int> priority,
  required String source,
  Value<int> rowid,
});
typedef $$RulesTableUpdateCompanionBuilder = RulesCompanion Function({
  Value<String> id,
  Value<String> pattern,
  Value<String> categoryId,
  Value<int> priority,
  Value<String> source,
  Value<int> rowid,
});

final class $$RulesTableReferences
    extends BaseReferences<_$AppDatabase, $RulesTable, Rule> {
  $$RulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('rules__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RulesTableFilterComposer extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RulesTable> {
  $$RulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RulesTable,
          Rule,
          $$RulesTableFilterComposer,
          $$RulesTableOrderingComposer,
          $$RulesTableAnnotationComposer,
          $$RulesTableCreateCompanionBuilder,
          $$RulesTableUpdateCompanionBuilder,
          (Rule, $$RulesTableReferences),
          Rule,
          PrefetchHooks Function({bool categoryId})
        > {
  $$RulesTableTableManager(_$AppDatabase db, $RulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RulesCompanion(
                id: id,
                pattern: pattern,
                categoryId: categoryId,
                priority: priority,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pattern,
                required String categoryId,
                Value<int> priority = const Value.absent(),
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => RulesCompanion.insert(
                id: id,
                pattern: pattern,
                categoryId: categoryId,
                priority: priority,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RulesTable, Rule>(table),
                  $$RulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$RulesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$RulesTableReferences
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
        ),
      );
}

typedef $$RulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RulesTable,
      Rule,
      $$RulesTableFilterComposer,
      $$RulesTableOrderingComposer,
      $$RulesTableAnnotationComposer,
      $$RulesTableCreateCompanionBuilder,
      $$RulesTableUpdateCompanionBuilder,
      (Rule, $$RulesTableReferences),
      Rule,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$AlertsTableCreateCompanionBuilder = AlertsCompanion Function({
  required String id,
  Value<String?> transactionId,
  required String alertType,
  required String message,
  Value<DateTime> createdAt,
  Value<bool> dismissed,
  Value<int> rowid,
});
typedef $$AlertsTableUpdateCompanionBuilder = AlertsCompanion Function({
  Value<String> id,
  Value<String?> transactionId,
  Value<String> alertType,
  Value<String> message,
  Value<DateTime> createdAt,
  Value<bool> dismissed,
  Value<int> rowid,
});

final class $$AlertsTableReferences
    extends BaseReferences<_$AppDatabase, $AlertsTable, Alert> {
  $$AlertsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias('alerts__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager? get transactionId {
    final $_column = $_itemColumn<String>('transaction_id');
    if ($_column == null) return null;
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlertsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTable> {
  $$AlertsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlertsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTable,
          Alert,
          $$AlertsTableFilterComposer,
          $$AlertsTableOrderingComposer,
          $$AlertsTableAnnotationComposer,
          $$AlertsTableCreateCompanionBuilder,
          $$AlertsTableUpdateCompanionBuilder,
          (Alert, $$AlertsTableReferences),
          Alert,
          PrefetchHooks Function({bool transactionId})
        > {
  $$AlertsTableTableManager(_$AppDatabase db, $AlertsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String> alertType = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCompanion(
                id: id,
                transactionId: transactionId,
                alertType: alertType,
                message: message,
                createdAt: createdAt,
                dismissed: dismissed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> transactionId = const Value.absent(),
                required String alertType,
                required String message,
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsCompanion.insert(
                id: id,
                transactionId: transactionId,
                alertType: alertType,
                message: message,
                createdAt: createdAt,
                dismissed: dismissed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlertsTable, Alert>(table),
                  $$AlertsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$AlertsTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$AlertsTableReferences
                            ._transactionIdTable(db)
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
        ),
      );
}

typedef $$AlertsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTable,
      Alert,
      $$AlertsTableFilterComposer,
      $$AlertsTableOrderingComposer,
      $$AlertsTableAnnotationComposer,
      $$AlertsTableCreateCompanionBuilder,
      $$AlertsTableUpdateCompanionBuilder,
      (Alert, $$AlertsTableReferences),
      Alert,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String id,
  required String categoryId,
  required int monthlyLimitMinor,
  Value<String> fromMonthKey,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<int> monthlyLimitMinor,
  Value<String> fromMonthKey,
  Value<int> rowid,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get monthlyLimitMinor => $composableBuilder(
    column: $table.monthlyLimitMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromMonthKey => $composableBuilder(
    column: $table.fromMonthKey,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get monthlyLimitMinor => $composableBuilder(
    column: $table.monthlyLimitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromMonthKey => $composableBuilder(
    column: $table.fromMonthKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get monthlyLimitMinor => $composableBuilder(
    column: $table.monthlyLimitMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromMonthKey => $composableBuilder(
    column: $table.fromMonthKey,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
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
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> monthlyLimitMinor = const Value.absent(),
                Value<String> fromMonthKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                categoryId: categoryId,
                monthlyLimitMinor: monthlyLimitMinor,
                fromMonthKey: fromMonthKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required int monthlyLimitMinor,
                Value<String> fromMonthKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                categoryId: categoryId,
                monthlyLimitMinor: monthlyLimitMinor,
                fromMonthKey: fromMonthKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences
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
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
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
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String settingKey,
      required String settingValue,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> settingKey,
      Value<String> settingValue,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingValue => $composableBuilder(
    column: $table.settingValue,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> settingValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String settingValue,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                settingKey: settingKey,
                settingValue: settingValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$OwnIdentifiersTableCreateCompanionBuilder =
    OwnIdentifiersCompanion Function({
      required String id,
      required String value,
      Value<int> rowid,
    });
typedef $$OwnIdentifiersTableUpdateCompanionBuilder =
    OwnIdentifiersCompanion Function({
      Value<String> id,
      Value<String> value,
      Value<int> rowid,
    });

class $$OwnIdentifiersTableFilterComposer
    extends Composer<_$AppDatabase, $OwnIdentifiersTable> {
  $$OwnIdentifiersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OwnIdentifiersTableOrderingComposer
    extends Composer<_$AppDatabase, $OwnIdentifiersTable> {
  $$OwnIdentifiersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OwnIdentifiersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OwnIdentifiersTable> {
  $$OwnIdentifiersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$OwnIdentifiersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OwnIdentifiersTable,
          OwnIdentifier,
          $$OwnIdentifiersTableFilterComposer,
          $$OwnIdentifiersTableOrderingComposer,
          $$OwnIdentifiersTableAnnotationComposer,
          $$OwnIdentifiersTableCreateCompanionBuilder,
          $$OwnIdentifiersTableUpdateCompanionBuilder,
          (
            OwnIdentifier,
            BaseReferences<_$AppDatabase, $OwnIdentifiersTable, OwnIdentifier>,
          ),
          OwnIdentifier,
          PrefetchHooks Function()
        > {
  $$OwnIdentifiersTableTableManager(
    _$AppDatabase db,
    $OwnIdentifiersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OwnIdentifiersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OwnIdentifiersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OwnIdentifiersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => OwnIdentifiersCompanion(id: id, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => OwnIdentifiersCompanion.insert(
                id: id,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OwnIdentifiersTable, OwnIdentifier>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OwnIdentifiersTable,
                    OwnIdentifier
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OwnIdentifiersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OwnIdentifiersTable,
      OwnIdentifier,
      $$OwnIdentifiersTableFilterComposer,
      $$OwnIdentifiersTableOrderingComposer,
      $$OwnIdentifiersTableAnnotationComposer,
      $$OwnIdentifiersTableCreateCompanionBuilder,
      $$OwnIdentifiersTableUpdateCompanionBuilder,
      (
        OwnIdentifier,
        BaseReferences<_$AppDatabase, $OwnIdentifiersTable, OwnIdentifier>,
      ),
      OwnIdentifier,
      PrefetchHooks Function()
    >;
typedef $$MerchantAliasesTableCreateCompanionBuilder =
    MerchantAliasesCompanion Function({
      required String id,
      required String pattern,
      required String displayName,
      Value<int> rowid,
    });
typedef $$MerchantAliasesTableUpdateCompanionBuilder =
    MerchantAliasesCompanion Function({
      Value<String> id,
      Value<String> pattern,
      Value<String> displayName,
      Value<int> rowid,
    });

class $$MerchantAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $MerchantAliasesTable> {
  $$MerchantAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MerchantAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $MerchantAliasesTable> {
  $$MerchantAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pattern => $composableBuilder(
    column: $table.pattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MerchantAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MerchantAliasesTable> {
  $$MerchantAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pattern =>
      $composableBuilder(column: $table.pattern, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );
}

class $$MerchantAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MerchantAliasesTable,
          MerchantAliase,
          $$MerchantAliasesTableFilterComposer,
          $$MerchantAliasesTableOrderingComposer,
          $$MerchantAliasesTableAnnotationComposer,
          $$MerchantAliasesTableCreateCompanionBuilder,
          $$MerchantAliasesTableUpdateCompanionBuilder,
          (
            MerchantAliase,
            BaseReferences<
              _$AppDatabase,
              $MerchantAliasesTable,
              MerchantAliase
            >,
          ),
          MerchantAliase,
          PrefetchHooks Function()
        > {
  $$MerchantAliasesTableTableManager(
    _$AppDatabase db,
    $MerchantAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MerchantAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MerchantAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MerchantAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pattern = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MerchantAliasesCompanion(
                id: id,
                pattern: pattern,
                displayName: displayName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pattern,
                required String displayName,
                Value<int> rowid = const Value.absent(),
              }) => MerchantAliasesCompanion.insert(
                id: id,
                pattern: pattern,
                displayName: displayName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MerchantAliasesTable, MerchantAliase>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MerchantAliasesTable,
                    MerchantAliase
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MerchantAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MerchantAliasesTable,
      MerchantAliase,
      $$MerchantAliasesTableFilterComposer,
      $$MerchantAliasesTableOrderingComposer,
      $$MerchantAliasesTableAnnotationComposer,
      $$MerchantAliasesTableCreateCompanionBuilder,
      $$MerchantAliasesTableUpdateCompanionBuilder,
      (
        MerchantAliase,
        BaseReferences<_$AppDatabase, $MerchantAliasesTable, MerchantAliase>,
      ),
      MerchantAliase,
      PrefetchHooks Function()
    >;
typedef $$SplitSharesTableCreateCompanionBuilder =
    SplitSharesCompanion Function({
      required String id,
      required String transactionId,
      required String personName,
      required int shareMinor,
      Value<bool> settled,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$SplitSharesTableUpdateCompanionBuilder =
    SplitSharesCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String> personName,
      Value<int> shareMinor,
      Value<bool> settled,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SplitSharesTableReferences
    extends BaseReferences<_$AppDatabase, $SplitSharesTable, SplitShare> {
  $$SplitSharesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) => db
      .transactions
      .createAlias('split_shares__transaction_id__transactions__id');

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SplitSharesTableFilterComposer
    extends Composer<_$AppDatabase, $SplitSharesTable> {
  $$SplitSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shareMinor => $composableBuilder(
    column: $table.shareMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitSharesTable> {
  $$SplitSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shareMinor => $composableBuilder(
    column: $table.shareMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get settled => $composableBuilder(
    column: $table.settled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitSharesTable> {
  $$SplitSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personName => $composableBuilder(
    column: $table.personName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shareMinor => $composableBuilder(
    column: $table.shareMinor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get settled =>
      $composableBuilder(column: $table.settled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitSharesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitSharesTable,
          SplitShare,
          $$SplitSharesTableFilterComposer,
          $$SplitSharesTableOrderingComposer,
          $$SplitSharesTableAnnotationComposer,
          $$SplitSharesTableCreateCompanionBuilder,
          $$SplitSharesTableUpdateCompanionBuilder,
          (SplitShare, $$SplitSharesTableReferences),
          SplitShare,
          PrefetchHooks Function({bool transactionId})
        > {
  $$SplitSharesTableTableManager(_$AppDatabase db, $SplitSharesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> personName = const Value.absent(),
                Value<int> shareMinor = const Value.absent(),
                Value<bool> settled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitSharesCompanion(
                id: id,
                transactionId: transactionId,
                personName: personName,
                shareMinor: shareMinor,
                settled: settled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required String personName,
                required int shareMinor,
                Value<bool> settled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitSharesCompanion.insert(
                id: id,
                transactionId: transactionId,
                personName: personName,
                shareMinor: shareMinor,
                settled: settled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SplitSharesTable, SplitShare>(table),
                  $$SplitSharesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (transactionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transactionId,
                        referencedTable: $$SplitSharesTableReferences
                            ._transactionIdTable(db),
                        referencedColumn: $$SplitSharesTableReferences
                            ._transactionIdTable(db)
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
        ),
      );
}

typedef $$SplitSharesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitSharesTable,
      SplitShare,
      $$SplitSharesTableFilterComposer,
      $$SplitSharesTableOrderingComposer,
      $$SplitSharesTableAnnotationComposer,
      $$SplitSharesTableCreateCompanionBuilder,
      $$SplitSharesTableUpdateCompanionBuilder,
      (SplitShare, $$SplitSharesTableReferences),
      SplitShare,
      PrefetchHooks Function({bool transactionId})
    >;
typedef $$UnparsedMessagesTableCreateCompanionBuilder =
    UnparsedMessagesCompanion Function({
      required String id,
      required String source,
      Value<String?> senderCode,
      required String rawTextEncrypted,
      required String hash,
      required DateTime receivedAt,
      Value<bool> resolved,
      Value<int> rowid,
    });
typedef $$UnparsedMessagesTableUpdateCompanionBuilder =
    UnparsedMessagesCompanion Function({
      Value<String> id,
      Value<String> source,
      Value<String?> senderCode,
      Value<String> rawTextEncrypted,
      Value<String> hash,
      Value<DateTime> receivedAt,
      Value<bool> resolved,
      Value<int> rowid,
    });

class $$UnparsedMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $UnparsedMessagesTable> {
  $$UnparsedMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderCode => $composableBuilder(
    column: $table.senderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawTextEncrypted => $composableBuilder(
    column: $table.rawTextEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UnparsedMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $UnparsedMessagesTable> {
  $$UnparsedMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderCode => $composableBuilder(
    column: $table.senderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawTextEncrypted => $composableBuilder(
    column: $table.rawTextEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get resolved => $composableBuilder(
    column: $table.resolved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UnparsedMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnparsedMessagesTable> {
  $$UnparsedMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get senderCode => $composableBuilder(
    column: $table.senderCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawTextEncrypted => $composableBuilder(
    column: $table.rawTextEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get resolved =>
      $composableBuilder(column: $table.resolved, builder: (column) => column);
}

class $$UnparsedMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UnparsedMessagesTable,
          UnparsedMessage,
          $$UnparsedMessagesTableFilterComposer,
          $$UnparsedMessagesTableOrderingComposer,
          $$UnparsedMessagesTableAnnotationComposer,
          $$UnparsedMessagesTableCreateCompanionBuilder,
          $$UnparsedMessagesTableUpdateCompanionBuilder,
          (
            UnparsedMessage,
            BaseReferences<
              _$AppDatabase,
              $UnparsedMessagesTable,
              UnparsedMessage
            >,
          ),
          UnparsedMessage,
          PrefetchHooks Function()
        > {
  $$UnparsedMessagesTableTableManager(
    _$AppDatabase db,
    $UnparsedMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnparsedMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnparsedMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnparsedMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> senderCode = const Value.absent(),
                Value<String> rawTextEncrypted = const Value.absent(),
                Value<String> hash = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<bool> resolved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnparsedMessagesCompanion(
                id: id,
                source: source,
                senderCode: senderCode,
                rawTextEncrypted: rawTextEncrypted,
                hash: hash,
                receivedAt: receivedAt,
                resolved: resolved,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String source,
                Value<String?> senderCode = const Value.absent(),
                required String rawTextEncrypted,
                required String hash,
                required DateTime receivedAt,
                Value<bool> resolved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UnparsedMessagesCompanion.insert(
                id: id,
                source: source,
                senderCode: senderCode,
                rawTextEncrypted: rawTextEncrypted,
                hash: hash,
                receivedAt: receivedAt,
                resolved: resolved,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UnparsedMessagesTable, UnparsedMessage>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UnparsedMessagesTable,
                    UnparsedMessage
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UnparsedMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UnparsedMessagesTable,
      UnparsedMessage,
      $$UnparsedMessagesTableFilterComposer,
      $$UnparsedMessagesTableOrderingComposer,
      $$UnparsedMessagesTableAnnotationComposer,
      $$UnparsedMessagesTableCreateCompanionBuilder,
      $$UnparsedMessagesTableUpdateCompanionBuilder,
      (
        UnparsedMessage,
        BaseReferences<_$AppDatabase, $UnparsedMessagesTable, UnparsedMessage>,
      ),
      UnparsedMessage,
      PrefetchHooks Function()
    >;
typedef $$LendingEntriesTableCreateCompanionBuilder =
    LendingEntriesCompanion Function({
      required String id,
      required String person,
      required String direction,
      required int amountMinor,
      required DateTime date,
      Value<DateTime?> dueDate,
      Value<String?> note,
      Value<bool> isSettled,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LendingEntriesTableUpdateCompanionBuilder =
    LendingEntriesCompanion Function({
      Value<String> id,
      Value<String> person,
      Value<String> direction,
      Value<int> amountMinor,
      Value<DateTime> date,
      Value<DateTime?> dueDate,
      Value<String?> note,
      Value<bool> isSettled,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LendingEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LendingEntriesTable, LendingEntry> {
  $$LendingEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$LendingPaymentsTable, List<LendingPayment>>
  _lendingPaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lendingPayments,
    aliasName: 'lending_entries__id__lending_payments__entry_id',
  );

  $$LendingPaymentsTableProcessedTableManager get lendingPaymentsRefs {
    final manager = $$LendingPaymentsTableTableManager(
      $_db,
      $_db.lendingPayments,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _lendingPaymentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LendingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LendingEntriesTable> {
  $$LendingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lendingPaymentsRefs(
    Expression<bool> Function($$LendingPaymentsTableFilterComposer f) f,
  ) {
    final $$LendingPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lendingPayments,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.lendingPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LendingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LendingEntriesTable> {
  $$LendingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LendingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LendingEntriesTable> {
  $$LendingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> lendingPaymentsRefs<T extends Object>(
    Expression<T> Function($$LendingPaymentsTableAnnotationComposer a) f,
  ) {
    final $$LendingPaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lendingPayments,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingPaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.lendingPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LendingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LendingEntriesTable,
          LendingEntry,
          $$LendingEntriesTableFilterComposer,
          $$LendingEntriesTableOrderingComposer,
          $$LendingEntriesTableAnnotationComposer,
          $$LendingEntriesTableCreateCompanionBuilder,
          $$LendingEntriesTableUpdateCompanionBuilder,
          (LendingEntry, $$LendingEntriesTableReferences),
          LendingEntry,
          PrefetchHooks Function({bool lendingPaymentsRefs})
        > {
  $$LendingEntriesTableTableManager(
    _$AppDatabase db,
    $LendingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LendingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LendingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LendingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> person = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LendingEntriesCompanion(
                id: id,
                person: person,
                direction: direction,
                amountMinor: amountMinor,
                date: date,
                dueDate: dueDate,
                note: note,
                isSettled: isSettled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String person,
                required String direction,
                required int amountMinor,
                required DateTime date,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LendingEntriesCompanion.insert(
                id: id,
                person: person,
                direction: direction,
                amountMinor: amountMinor,
                date: date,
                dueDate: dueDate,
                note: note,
                isSettled: isSettled,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LendingEntriesTable, LendingEntry>(table),
                  $$LendingEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lendingPaymentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (lendingPaymentsRefs) db.lendingPayments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (lendingPaymentsRefs)
                    await $_getPrefetchedData<
                      LendingEntry,
                      $LendingEntriesTable,
                      LendingPayment
                    >(
                      currentTable: table,
                      referencedTable: $$LendingEntriesTableReferences
                          ._lendingPaymentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LendingEntriesTableReferences(
                            db,
                            table,
                            p0,
                          ).lendingPaymentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.entryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LendingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LendingEntriesTable,
      LendingEntry,
      $$LendingEntriesTableFilterComposer,
      $$LendingEntriesTableOrderingComposer,
      $$LendingEntriesTableAnnotationComposer,
      $$LendingEntriesTableCreateCompanionBuilder,
      $$LendingEntriesTableUpdateCompanionBuilder,
      (LendingEntry, $$LendingEntriesTableReferences),
      LendingEntry,
      PrefetchHooks Function({bool lendingPaymentsRefs})
    >;
typedef $$LendingPaymentsTableCreateCompanionBuilder =
    LendingPaymentsCompanion Function({
      required String id,
      required String entryId,
      required int amountMinor,
      required DateTime date,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$LendingPaymentsTableUpdateCompanionBuilder =
    LendingPaymentsCompanion Function({
      Value<String> id,
      Value<String> entryId,
      Value<int> amountMinor,
      Value<DateTime> date,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$LendingPaymentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $LendingPaymentsTable, LendingPayment> {
  $$LendingPaymentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LendingEntriesTable _entryIdTable(_$AppDatabase db) => db
      .lendingEntries
      .createAlias('lending_payments__entry_id__lending_entries__id');

  $$LendingEntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$LendingEntriesTableTableManager(
      $_db,
      $_db.lendingEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LendingPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $LendingPaymentsTable> {
  $$LendingPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$LendingEntriesTableFilterComposer get entryId {
    final $$LendingEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.lendingEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingEntriesTableFilterComposer(
            $db: $db,
            $table: $db.lendingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LendingPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LendingPaymentsTable> {
  $$LendingPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$LendingEntriesTableOrderingComposer get entryId {
    final $$LendingEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.lendingEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.lendingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LendingPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LendingPaymentsTable> {
  $$LendingPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$LendingEntriesTableAnnotationComposer get entryId {
    final $$LendingEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.lendingEntries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.lendingEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LendingPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LendingPaymentsTable,
          LendingPayment,
          $$LendingPaymentsTableFilterComposer,
          $$LendingPaymentsTableOrderingComposer,
          $$LendingPaymentsTableAnnotationComposer,
          $$LendingPaymentsTableCreateCompanionBuilder,
          $$LendingPaymentsTableUpdateCompanionBuilder,
          (LendingPayment, $$LendingPaymentsTableReferences),
          LendingPayment,
          PrefetchHooks Function({bool entryId})
        > {
  $$LendingPaymentsTableTableManager(
    _$AppDatabase db,
    $LendingPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LendingPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LendingPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LendingPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LendingPaymentsCompanion(
                id: id,
                entryId: entryId,
                amountMinor: amountMinor,
                date: date,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryId,
                required int amountMinor,
                required DateTime date,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LendingPaymentsCompanion.insert(
                id: id,
                entryId: entryId,
                amountMinor: amountMinor,
                date: date,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LendingPaymentsTable, LendingPayment>(table),
                  $$LendingPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entryId,
                        referencedTable: $$LendingPaymentsTableReferences
                            ._entryIdTable(db),
                        referencedColumn: $$LendingPaymentsTableReferences
                            ._entryIdTable(db)
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
        ),
      );
}

typedef $$LendingPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LendingPaymentsTable,
      LendingPayment,
      $$LendingPaymentsTableFilterComposer,
      $$LendingPaymentsTableOrderingComposer,
      $$LendingPaymentsTableAnnotationComposer,
      $$LendingPaymentsTableCreateCompanionBuilder,
      $$LendingPaymentsTableUpdateCompanionBuilder,
      (LendingPayment, $$LendingPaymentsTableReferences),
      LendingPayment,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$ParserTemplatesTableCreateCompanionBuilder =
    ParserTemplatesCompanion Function({
      required String id,
      Value<String?> senderCode,
      required String patternEncrypted,
      required String type,
      Value<int> hits,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ParserTemplatesTableUpdateCompanionBuilder =
    ParserTemplatesCompanion Function({
      Value<String> id,
      Value<String?> senderCode,
      Value<String> patternEncrypted,
      Value<String> type,
      Value<int> hits,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ParserTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $ParserTemplatesTable> {
  $$ParserTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderCode => $composableBuilder(
    column: $table.senderCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patternEncrypted => $composableBuilder(
    column: $table.patternEncrypted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParserTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ParserTemplatesTable> {
  $$ParserTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderCode => $composableBuilder(
    column: $table.senderCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patternEncrypted => $composableBuilder(
    column: $table.patternEncrypted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParserTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParserTemplatesTable> {
  $$ParserTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get senderCode => $composableBuilder(
    column: $table.senderCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patternEncrypted => $composableBuilder(
    column: $table.patternEncrypted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get hits =>
      $composableBuilder(column: $table.hits, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ParserTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParserTemplatesTable,
          ParserTemplate,
          $$ParserTemplatesTableFilterComposer,
          $$ParserTemplatesTableOrderingComposer,
          $$ParserTemplatesTableAnnotationComposer,
          $$ParserTemplatesTableCreateCompanionBuilder,
          $$ParserTemplatesTableUpdateCompanionBuilder,
          (
            ParserTemplate,
            BaseReferences<
              _$AppDatabase,
              $ParserTemplatesTable,
              ParserTemplate
            >,
          ),
          ParserTemplate,
          PrefetchHooks Function()
        > {
  $$ParserTemplatesTableTableManager(
    _$AppDatabase db,
    $ParserTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParserTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParserTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParserTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> senderCode = const Value.absent(),
                Value<String> patternEncrypted = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> hits = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParserTemplatesCompanion(
                id: id,
                senderCode: senderCode,
                patternEncrypted: patternEncrypted,
                type: type,
                hits: hits,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> senderCode = const Value.absent(),
                required String patternEncrypted,
                required String type,
                Value<int> hits = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParserTemplatesCompanion.insert(
                id: id,
                senderCode: senderCode,
                patternEncrypted: patternEncrypted,
                type: type,
                hits: hits,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ParserTemplatesTable, ParserTemplate>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ParserTemplatesTable,
                    ParserTemplate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParserTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParserTemplatesTable,
      ParserTemplate,
      $$ParserTemplatesTableFilterComposer,
      $$ParserTemplatesTableOrderingComposer,
      $$ParserTemplatesTableAnnotationComposer,
      $$ParserTemplatesTableCreateCompanionBuilder,
      $$ParserTemplatesTableUpdateCompanionBuilder,
      (
        ParserTemplate,
        BaseReferences<_$AppDatabase, $ParserTemplatesTable, ParserTemplate>,
      ),
      ParserTemplate,
      PrefetchHooks Function()
    >;
typedef $$BudgetOverridesTableCreateCompanionBuilder =
    BudgetOverridesCompanion Function({
      required String id,
      required String categoryId,
      required String monthKey,
      required int limitMinor,
      Value<int> rowid,
    });
typedef $$BudgetOverridesTableUpdateCompanionBuilder =
    BudgetOverridesCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String> monthKey,
      Value<int> limitMinor,
      Value<int> rowid,
    });

final class $$BudgetOverridesTableReferences
    extends
        BaseReferences<_$AppDatabase, $BudgetOverridesTable, BudgetOverride> {
  $$BudgetOverridesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias('budget_overrides__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetOverridesTable> {
  $$BudgetOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetOverridesTable> {
  $$BudgetOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetOverridesTable> {
  $$BudgetOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<int> get limitMinor => $composableBuilder(
    column: $table.limitMinor,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetOverridesTable,
          BudgetOverride,
          $$BudgetOverridesTableFilterComposer,
          $$BudgetOverridesTableOrderingComposer,
          $$BudgetOverridesTableAnnotationComposer,
          $$BudgetOverridesTableCreateCompanionBuilder,
          $$BudgetOverridesTableUpdateCompanionBuilder,
          (BudgetOverride, $$BudgetOverridesTableReferences),
          BudgetOverride,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetOverridesTableTableManager(
    _$AppDatabase db,
    $BudgetOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<int> limitMinor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetOverridesCompanion(
                id: id,
                categoryId: categoryId,
                monthKey: monthKey,
                limitMinor: limitMinor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String monthKey,
                required int limitMinor,
                Value<int> rowid = const Value.absent(),
              }) => BudgetOverridesCompanion.insert(
                id: id,
                categoryId: categoryId,
                monthKey: monthKey,
                limitMinor: limitMinor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetOverridesTable, BudgetOverride>(table),
                  $$BudgetOverridesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetOverridesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetOverridesTableReferences
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
        ),
      );
}

typedef $$BudgetOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetOverridesTable,
      BudgetOverride,
      $$BudgetOverridesTableFilterComposer,
      $$BudgetOverridesTableOrderingComposer,
      $$BudgetOverridesTableAnnotationComposer,
      $$BudgetOverridesTableCreateCompanionBuilder,
      $$BudgetOverridesTableUpdateCompanionBuilder,
      (BudgetOverride, $$BudgetOverridesTableReferences),
      BudgetOverride,
      PrefetchHooks Function({bool categoryId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RecurringGroupsTableTableManager get recurringGroups =>
      $$RecurringGroupsTableTableManager(_db, _db.recurringGroups);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$RulesTableTableManager get rules =>
      $$RulesTableTableManager(_db, _db.rules);
  $$AlertsTableTableManager get alerts =>
      $$AlertsTableTableManager(_db, _db.alerts);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$OwnIdentifiersTableTableManager get ownIdentifiers =>
      $$OwnIdentifiersTableTableManager(_db, _db.ownIdentifiers);
  $$MerchantAliasesTableTableManager get merchantAliases =>
      $$MerchantAliasesTableTableManager(_db, _db.merchantAliases);
  $$SplitSharesTableTableManager get splitShares =>
      $$SplitSharesTableTableManager(_db, _db.splitShares);
  $$UnparsedMessagesTableTableManager get unparsedMessages =>
      $$UnparsedMessagesTableTableManager(_db, _db.unparsedMessages);
  $$LendingEntriesTableTableManager get lendingEntries =>
      $$LendingEntriesTableTableManager(_db, _db.lendingEntries);
  $$LendingPaymentsTableTableManager get lendingPayments =>
      $$LendingPaymentsTableTableManager(_db, _db.lendingPayments);
  $$ParserTemplatesTableTableManager get parserTemplates =>
      $$ParserTemplatesTableTableManager(_db, _db.parserTemplates);
  $$BudgetOverridesTableTableManager get budgetOverrides =>
      $$BudgetOverridesTableTableManager(_db, _db.budgetOverrides);
}
