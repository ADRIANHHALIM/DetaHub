// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SectorsTable extends Sectors with TableInfo<$SectorsTable, Sector> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SectorsTable(this.attachedDatabase, [this._alias]);
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
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 128),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sectors';
  @override
  VerificationContext validateIntegrity(Insertable<Sector> instance,
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
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Sector map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sector(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SectorsTable createAlias(String alias) {
    return $SectorsTable(attachedDatabase, alias);
  }
}

class Sector extends DataClass implements Insertable<Sector> {
  /// Auto-incremented surrogate primary key.
  final int id;

  /// Human-readable sector name. Required, non-empty.
  final String name;

  /// ISO-8601 timestamp of when this sector was created locally.
  final DateTime createdAt;
  const Sector({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SectorsCompanion toCompanion(bool nullToAbsent) {
    return SectorsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Sector.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sector(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sector copyWith({int? id, String? name, DateTime? createdAt}) => Sector(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  Sector copyWithCompanion(SectorsCompanion data) {
    return Sector(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sector(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sector &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class SectorsCompanion extends UpdateCompanion<Sector> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const SectorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SectorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Sector> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SectorsCompanion copyWith(
      {Value<int>? id, Value<String>? name, Value<DateTime>? createdAt}) {
    return SectorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SectorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SubSectorsTable extends SubSectors
    with TableInfo<$SubSectorsTable, SubSector> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubSectorsTable(this.attachedDatabase, [this._alias]);
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
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 128),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _sectorIdMeta =
      const VerificationMeta('sectorId');
  @override
  late final GeneratedColumn<int> sectorId = GeneratedColumn<int>(
      'sector_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES sectors (id) ON DELETE CASCADE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, name, sectorId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sub_sectors';
  @override
  VerificationContext validateIntegrity(Insertable<SubSector> instance,
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
    if (data.containsKey('sector_id')) {
      context.handle(_sectorIdMeta,
          sectorId.isAcceptableOrUnknown(data['sector_id']!, _sectorIdMeta));
    } else if (isInserting) {
      context.missing(_sectorIdMeta);
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
  SubSector map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubSector(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sectorId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sector_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SubSectorsTable createAlias(String alias) {
    return $SubSectorsTable(attachedDatabase, alias);
  }
}

class SubSector extends DataClass implements Insertable<SubSector> {
  /// Auto-incremented surrogate primary key.
  final int id;

  /// Human-readable sub-sector name. Required, non-empty.
  final String name;

  /// FK → sectors.id. Cascades DELETE so that removing a Sector
  /// automatically removes all its Sub-Sectors (and their Devices
  /// via the chain of cascades).
  final int sectorId;

  /// ISO-8601 timestamp of local creation.
  final DateTime createdAt;
  const SubSector(
      {required this.id,
      required this.name,
      required this.sectorId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sector_id'] = Variable<int>(sectorId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SubSectorsCompanion toCompanion(bool nullToAbsent) {
    return SubSectorsCompanion(
      id: Value(id),
      name: Value(name),
      sectorId: Value(sectorId),
      createdAt: Value(createdAt),
    );
  }

  factory SubSector.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubSector(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sectorId: serializer.fromJson<int>(json['sectorId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sectorId': serializer.toJson<int>(sectorId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SubSector copyWith(
          {int? id, String? name, int? sectorId, DateTime? createdAt}) =>
      SubSector(
        id: id ?? this.id,
        name: name ?? this.name,
        sectorId: sectorId ?? this.sectorId,
        createdAt: createdAt ?? this.createdAt,
      );
  SubSector copyWithCompanion(SubSectorsCompanion data) {
    return SubSector(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sectorId: data.sectorId.present ? data.sectorId.value : this.sectorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubSector(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sectorId: $sectorId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sectorId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubSector &&
          other.id == this.id &&
          other.name == this.name &&
          other.sectorId == this.sectorId &&
          other.createdAt == this.createdAt);
}

class SubSectorsCompanion extends UpdateCompanion<SubSector> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sectorId;
  final Value<DateTime> createdAt;
  const SubSectorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sectorId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SubSectorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int sectorId,
    this.createdAt = const Value.absent(),
  })  : name = Value(name),
        sectorId = Value(sectorId);
  static Insertable<SubSector> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sectorId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sectorId != null) 'sector_id': sectorId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SubSectorsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? sectorId,
      Value<DateTime>? createdAt}) {
    return SubSectorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sectorId: sectorId ?? this.sectorId,
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
    if (sectorId.present) {
      map['sector_id'] = Variable<int>(sectorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubSectorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sectorId: $sectorId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 128),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _baseUrlMeta =
      const VerificationMeta('baseUrl');
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
      'base_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productTypeMeta =
      const VerificationMeta('productType');
  @override
  late final GeneratedColumn<String> productType = GeneratedColumn<String>(
      'product_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subSectorIdMeta =
      const VerificationMeta('subSectorId');
  @override
  late final GeneratedColumn<int> subSectorId = GeneratedColumn<int>(
      'sub_sector_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES sub_sectors (id) ON DELETE CASCADE'));
  static const VerificationMeta _lastSeenAtMeta =
      const VerificationMeta('lastSeenAt');
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
      'last_seen_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
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
      [id, name, baseUrl, productType, subSectorId, lastSeenAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<Device> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(_baseUrlMeta,
          baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta));
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('product_type')) {
      context.handle(
          _productTypeMeta,
          productType.isAcceptableOrUnknown(
              data['product_type']!, _productTypeMeta));
    } else if (isInserting) {
      context.missing(_productTypeMeta);
    }
    if (data.containsKey('sub_sector_id')) {
      context.handle(
          _subSectorIdMeta,
          subSectorId.isAcceptableOrUnknown(
              data['sub_sector_id']!, _subSectorIdMeta));
    } else if (isInserting) {
      context.missing(_subSectorIdMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
          _lastSeenAtMeta,
          lastSeenAt.isAcceptableOrUnknown(
              data['last_seen_at']!, _lastSeenAtMeta));
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
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      baseUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base_url'])!,
      productType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_type'])!,
      subSectorId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sub_sector_id'])!,
      lastSeenAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  /// User-defined primary key mirroring the device's own ID from /api/manifest.
  /// Example: "lat-lab-01"
  final String id;

  /// Friendly display name for UI (may differ from raw ID).
  final String name;

  /// Base HTTP URL of the device's local micro-server.
  /// Example: "http://192.168.1.50"
  final String baseUrl;

  /// Product type string matching a known DetaLab product family.
  /// Used to select the correct AI model and metric schema.
  /// Example: "LAT_ENS160"
  final String productType;

  /// FK → sub_sectors.id. Cascades DELETE so that removing a Sub-Sector
  /// removes all its Device Nodes (and their telemetry records).
  final int subSectorId;

  /// Last successful ping timestamp. Null if device has never been reached.
  final DateTime? lastSeenAt;

  /// Local creation timestamp.
  final DateTime createdAt;
  const Device(
      {required this.id,
      required this.name,
      required this.baseUrl,
      required this.productType,
      required this.subSectorId,
      this.lastSeenAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_url'] = Variable<String>(baseUrl);
    map['product_type'] = Variable<String>(productType);
    map['sub_sector_id'] = Variable<int>(subSectorId);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      name: Value(name),
      baseUrl: Value(baseUrl),
      productType: Value(productType),
      subSectorId: Value(subSectorId),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      createdAt: Value(createdAt),
    );
  }

  factory Device.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      productType: serializer.fromJson<String>(json['productType']),
      subSectorId: serializer.fromJson<int>(json['subSectorId']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'productType': serializer.toJson<String>(productType),
      'subSectorId': serializer.toJson<int>(subSectorId),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Device copyWith(
          {String? id,
          String? name,
          String? baseUrl,
          String? productType,
          int? subSectorId,
          Value<DateTime?> lastSeenAt = const Value.absent(),
          DateTime? createdAt}) =>
      Device(
        id: id ?? this.id,
        name: name ?? this.name,
        baseUrl: baseUrl ?? this.baseUrl,
        productType: productType ?? this.productType,
        subSectorId: subSectorId ?? this.subSectorId,
        lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
        createdAt: createdAt ?? this.createdAt,
      );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      productType:
          data.productType.present ? data.productType.value : this.productType,
      subSectorId:
          data.subSectorId.present ? data.subSectorId.value : this.subSectorId,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('productType: $productType, ')
          ..write('subSectorId: $subSectorId, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, baseUrl, productType, subSectorId, lastSeenAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseUrl == this.baseUrl &&
          other.productType == this.productType &&
          other.subSectorId == this.subSectorId &&
          other.lastSeenAt == this.lastSeenAt &&
          other.createdAt == this.createdAt);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseUrl;
  final Value<String> productType;
  final Value<int> subSectorId;
  final Value<DateTime?> lastSeenAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.productType = const Value.absent(),
    this.subSectorId = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required String name,
    required String baseUrl,
    required String productType,
    required int subSectorId,
    this.lastSeenAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        baseUrl = Value(baseUrl),
        productType = Value(productType),
        subSectorId = Value(subSectorId);
  static Insertable<Device> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseUrl,
    Expression<String>? productType,
    Expression<int>? subSectorId,
    Expression<DateTime>? lastSeenAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseUrl != null) 'base_url': baseUrl,
      if (productType != null) 'product_type': productType,
      if (subSectorId != null) 'sub_sector_id': subSectorId,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? baseUrl,
      Value<String>? productType,
      Value<int>? subSectorId,
      Value<DateTime?>? lastSeenAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return DevicesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      productType: productType ?? this.productType,
      subSectorId: subSectorId ?? this.subSectorId,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
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
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (productType.present) {
      map['product_type'] = Variable<String>(productType.value);
    }
    if (subSectorId.present) {
      map['sub_sector_id'] = Variable<int>(subSectorId.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
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
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('productType: $productType, ')
          ..write('subSectorId: $subSectorId, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TelemetryRecordsTable extends TelemetryRecords
    with TableInfo<$TelemetryRecordsTable, TelemetryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TelemetryRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES devices (id) ON DELETE CASCADE'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _humidityMeta =
      const VerificationMeta('humidity');
  @override
  late final GeneratedColumn<double> humidity = GeneratedColumn<double>(
      'humidity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _eco2Meta = const VerificationMeta('eco2');
  @override
  late final GeneratedColumn<int> eco2 = GeneratedColumn<int>(
      'eco2', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tvocMeta = const VerificationMeta('tvoc');
  @override
  late final GeneratedColumn<int> tvoc = GeneratedColumn<int>(
      'tvoc', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _aqiMeta = const VerificationMeta('aqi');
  @override
  late final GeneratedColumn<int> aqi = GeneratedColumn<int>(
      'aqi', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, deviceId, timestamp, temperature, humidity, eco2, tvoc, aqi];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'telemetry_records';
  @override
  VerificationContext validateIntegrity(Insertable<TelemetryRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('humidity')) {
      context.handle(_humidityMeta,
          humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta));
    }
    if (data.containsKey('eco2')) {
      context.handle(
          _eco2Meta, eco2.isAcceptableOrUnknown(data['eco2']!, _eco2Meta));
    }
    if (data.containsKey('tvoc')) {
      context.handle(
          _tvocMeta, tvoc.isAcceptableOrUnknown(data['tvoc']!, _tvocMeta));
    }
    if (data.containsKey('aqi')) {
      context.handle(
          _aqiMeta, aqi.isAcceptableOrUnknown(data['aqi']!, _aqiMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TelemetryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TelemetryRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature']),
      humidity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}humidity']),
      eco2: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}eco2']),
      tvoc: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tvoc']),
      aqi: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}aqi']),
    );
  }

  @override
  $TelemetryRecordsTable createAlias(String alias) {
    return $TelemetryRecordsTable(attachedDatabase, alias);
  }
}

class TelemetryRecord extends DataClass implements Insertable<TelemetryRecord> {
  /// Auto-incremented internal row ID.
  final int id;

  /// FK → devices.id. Cascades DELETE so that removing a Device also removes
  /// all its historical telemetry data, keeping the DB lean.
  final String deviceId;

  /// UTC timestamp of the sample. Combined with deviceId forms the unique key.
  final DateTime timestamp;

  /// Ambient temperature in degrees Celsius.
  final double? temperature;

  /// Relative humidity in percent (0–100).
  final double? humidity;

  /// Equivalent CO₂ concentration in ppm (ENS160 calculated).
  final int? eco2;

  /// Total Volatile Organic Compounds in ppb (ENS160 calculated).
  final int? tvoc;

  /// ENS160 Air Quality Index: integer 1 (Excellent) to 5 (Unhealthy).
  final int? aqi;
  const TelemetryRecord(
      {required this.id,
      required this.deviceId,
      required this.timestamp,
      this.temperature,
      this.humidity,
      this.eco2,
      this.tvoc,
      this.aqi});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['device_id'] = Variable<String>(deviceId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || humidity != null) {
      map['humidity'] = Variable<double>(humidity);
    }
    if (!nullToAbsent || eco2 != null) {
      map['eco2'] = Variable<int>(eco2);
    }
    if (!nullToAbsent || tvoc != null) {
      map['tvoc'] = Variable<int>(tvoc);
    }
    if (!nullToAbsent || aqi != null) {
      map['aqi'] = Variable<int>(aqi);
    }
    return map;
  }

  TelemetryRecordsCompanion toCompanion(bool nullToAbsent) {
    return TelemetryRecordsCompanion(
      id: Value(id),
      deviceId: Value(deviceId),
      timestamp: Value(timestamp),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      humidity: humidity == null && nullToAbsent
          ? const Value.absent()
          : Value(humidity),
      eco2: eco2 == null && nullToAbsent ? const Value.absent() : Value(eco2),
      tvoc: tvoc == null && nullToAbsent ? const Value.absent() : Value(tvoc),
      aqi: aqi == null && nullToAbsent ? const Value.absent() : Value(aqi),
    );
  }

  factory TelemetryRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TelemetryRecord(
      id: serializer.fromJson<int>(json['id']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      humidity: serializer.fromJson<double?>(json['humidity']),
      eco2: serializer.fromJson<int?>(json['eco2']),
      tvoc: serializer.fromJson<int?>(json['tvoc']),
      aqi: serializer.fromJson<int?>(json['aqi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deviceId': serializer.toJson<String>(deviceId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'temperature': serializer.toJson<double?>(temperature),
      'humidity': serializer.toJson<double?>(humidity),
      'eco2': serializer.toJson<int?>(eco2),
      'tvoc': serializer.toJson<int?>(tvoc),
      'aqi': serializer.toJson<int?>(aqi),
    };
  }

  TelemetryRecord copyWith(
          {int? id,
          String? deviceId,
          DateTime? timestamp,
          Value<double?> temperature = const Value.absent(),
          Value<double?> humidity = const Value.absent(),
          Value<int?> eco2 = const Value.absent(),
          Value<int?> tvoc = const Value.absent(),
          Value<int?> aqi = const Value.absent()}) =>
      TelemetryRecord(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        timestamp: timestamp ?? this.timestamp,
        temperature: temperature.present ? temperature.value : this.temperature,
        humidity: humidity.present ? humidity.value : this.humidity,
        eco2: eco2.present ? eco2.value : this.eco2,
        tvoc: tvoc.present ? tvoc.value : this.tvoc,
        aqi: aqi.present ? aqi.value : this.aqi,
      );
  TelemetryRecord copyWithCompanion(TelemetryRecordsCompanion data) {
    return TelemetryRecord(
      id: data.id.present ? data.id.value : this.id,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
      eco2: data.eco2.present ? data.eco2.value : this.eco2,
      tvoc: data.tvoc.present ? data.tvoc.value : this.tvoc,
      aqi: data.aqi.present ? data.aqi.value : this.aqi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRecord(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('temperature: $temperature, ')
          ..write('humidity: $humidity, ')
          ..write('eco2: $eco2, ')
          ..write('tvoc: $tvoc, ')
          ..write('aqi: $aqi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, deviceId, timestamp, temperature, humidity, eco2, tvoc, aqi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TelemetryRecord &&
          other.id == this.id &&
          other.deviceId == this.deviceId &&
          other.timestamp == this.timestamp &&
          other.temperature == this.temperature &&
          other.humidity == this.humidity &&
          other.eco2 == this.eco2 &&
          other.tvoc == this.tvoc &&
          other.aqi == this.aqi);
}

class TelemetryRecordsCompanion extends UpdateCompanion<TelemetryRecord> {
  final Value<int> id;
  final Value<String> deviceId;
  final Value<DateTime> timestamp;
  final Value<double?> temperature;
  final Value<double?> humidity;
  final Value<int?> eco2;
  final Value<int?> tvoc;
  final Value<int?> aqi;
  const TelemetryRecordsCompanion({
    this.id = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.temperature = const Value.absent(),
    this.humidity = const Value.absent(),
    this.eco2 = const Value.absent(),
    this.tvoc = const Value.absent(),
    this.aqi = const Value.absent(),
  });
  TelemetryRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String deviceId,
    required DateTime timestamp,
    this.temperature = const Value.absent(),
    this.humidity = const Value.absent(),
    this.eco2 = const Value.absent(),
    this.tvoc = const Value.absent(),
    this.aqi = const Value.absent(),
  })  : deviceId = Value(deviceId),
        timestamp = Value(timestamp);
  static Insertable<TelemetryRecord> custom({
    Expression<int>? id,
    Expression<String>? deviceId,
    Expression<DateTime>? timestamp,
    Expression<double>? temperature,
    Expression<double>? humidity,
    Expression<int>? eco2,
    Expression<int>? tvoc,
    Expression<int>? aqi,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceId != null) 'device_id': deviceId,
      if (timestamp != null) 'timestamp': timestamp,
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
      if (eco2 != null) 'eco2': eco2,
      if (tvoc != null) 'tvoc': tvoc,
      if (aqi != null) 'aqi': aqi,
    });
  }

  TelemetryRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? deviceId,
      Value<DateTime>? timestamp,
      Value<double?>? temperature,
      Value<double?>? humidity,
      Value<int?>? eco2,
      Value<int?>? tvoc,
      Value<int?>? aqi}) {
    return TelemetryRecordsCompanion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      eco2: eco2 ?? this.eco2,
      tvoc: tvoc ?? this.tvoc,
      aqi: aqi ?? this.aqi,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<double>(humidity.value);
    }
    if (eco2.present) {
      map['eco2'] = Variable<int>(eco2.value);
    }
    if (tvoc.present) {
      map['tvoc'] = Variable<int>(tvoc.value);
    }
    if (aqi.present) {
      map['aqi'] = Variable<int>(aqi.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRecordsCompanion(')
          ..write('id: $id, ')
          ..write('deviceId: $deviceId, ')
          ..write('timestamp: $timestamp, ')
          ..write('temperature: $temperature, ')
          ..write('humidity: $humidity, ')
          ..write('eco2: $eco2, ')
          ..write('tvoc: $tvoc, ')
          ..write('aqi: $aqi')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SectorsTable sectors = $SectorsTable(this);
  late final $SubSectorsTable subSectors = $SubSectorsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $TelemetryRecordsTable telemetryRecords =
      $TelemetryRecordsTable(this);
  late final Index idxTelemetryTimestamp = Index('idx_telemetry_timestamp',
      'CREATE INDEX idx_telemetry_timestamp ON telemetry_records (timestamp)');
  late final Index idxTelemetryDeviceTimestamp = Index(
      'idx_telemetry_device_timestamp',
      'CREATE UNIQUE INDEX idx_telemetry_device_timestamp ON telemetry_records (device_id, timestamp)');
  late final SectorDao sectorDao = SectorDao(this as AppDatabase);
  late final DeviceDao deviceDao = DeviceDao(this as AppDatabase);
  late final TelemetryDao telemetryDao = TelemetryDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        sectors,
        subSectors,
        devices,
        telemetryRecords,
        idxTelemetryTimestamp,
        idxTelemetryDeviceTimestamp
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('sectors',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('sub_sectors', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('sub_sectors',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('devices', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('devices',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('telemetry_records', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$SectorsTableCreateCompanionBuilder = SectorsCompanion Function({
  Value<int> id,
  required String name,
  Value<DateTime> createdAt,
});
typedef $$SectorsTableUpdateCompanionBuilder = SectorsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<DateTime> createdAt,
});

class $$SectorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SectorsTable,
    Sector,
    $$SectorsTableFilterComposer,
    $$SectorsTableOrderingComposer,
    $$SectorsTableCreateCompanionBuilder,
    $$SectorsTableUpdateCompanionBuilder> {
  $$SectorsTableTableManager(_$AppDatabase db, $SectorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SectorsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SectorsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SectorsCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SectorsCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
          ),
        ));
}

class $$SectorsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SectorsTable> {
  $$SectorsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter subSectorsRefs(
      ComposableFilter Function($$SubSectorsTableFilterComposer f) f) {
    final $$SubSectorsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.subSectors,
        getReferencedColumn: (t) => t.sectorId,
        builder: (joinBuilder, parentComposers) =>
            $$SubSectorsTableFilterComposer(ComposerState($state.db,
                $state.db.subSectors, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$SectorsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SectorsTable> {
  $$SectorsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SubSectorsTableCreateCompanionBuilder = SubSectorsCompanion Function({
  Value<int> id,
  required String name,
  required int sectorId,
  Value<DateTime> createdAt,
});
typedef $$SubSectorsTableUpdateCompanionBuilder = SubSectorsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sectorId,
  Value<DateTime> createdAt,
});

class $$SubSectorsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubSectorsTable,
    SubSector,
    $$SubSectorsTableFilterComposer,
    $$SubSectorsTableOrderingComposer,
    $$SubSectorsTableCreateCompanionBuilder,
    $$SubSectorsTableUpdateCompanionBuilder> {
  $$SubSectorsTableTableManager(_$AppDatabase db, $SubSectorsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SubSectorsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SubSectorsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sectorId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SubSectorsCompanion(
            id: id,
            name: name,
            sectorId: sectorId,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int sectorId,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SubSectorsCompanion.insert(
            id: id,
            name: name,
            sectorId: sectorId,
            createdAt: createdAt,
          ),
        ));
}

class $$SubSectorsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SubSectorsTable> {
  $$SubSectorsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$SectorsTableFilterComposer get sectorId {
    final $$SectorsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sectorId,
        referencedTable: $state.db.sectors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$SectorsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.sectors, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter devicesRefs(
      ComposableFilter Function($$DevicesTableFilterComposer f) f) {
    final $$DevicesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.devices,
        getReferencedColumn: (t) => t.subSectorId,
        builder: (joinBuilder, parentComposers) => $$DevicesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.devices, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$SubSectorsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SubSectorsTable> {
  $$SubSectorsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$SectorsTableOrderingComposer get sectorId {
    final $$SectorsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sectorId,
        referencedTable: $state.db.sectors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SectorsTableOrderingComposer(ComposerState(
                $state.db, $state.db.sectors, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required String name,
  required String baseUrl,
  required String productType,
  required int subSectorId,
  Value<DateTime?> lastSeenAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> baseUrl,
  Value<String> productType,
  Value<int> subSectorId,
  Value<DateTime?> lastSeenAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$DevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder> {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DevicesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DevicesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> baseUrl = const Value.absent(),
            Value<String> productType = const Value.absent(),
            Value<int> subSectorId = const Value.absent(),
            Value<DateTime?> lastSeenAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            id: id,
            name: name,
            baseUrl: baseUrl,
            productType: productType,
            subSectorId: subSectorId,
            lastSeenAt: lastSeenAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String baseUrl,
            required String productType,
            required int subSectorId,
            Value<DateTime?> lastSeenAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            id: id,
            name: name,
            baseUrl: baseUrl,
            productType: productType,
            subSectorId: subSectorId,
            lastSeenAt: lastSeenAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
        ));
}

class $$DevicesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get baseUrl => $state.composableBuilder(
      column: $state.table.baseUrl,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productType => $state.composableBuilder(
      column: $state.table.productType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastSeenAt => $state.composableBuilder(
      column: $state.table.lastSeenAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$SubSectorsTableFilterComposer get subSectorId {
    final $$SubSectorsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subSectorId,
        referencedTable: $state.db.subSectors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SubSectorsTableFilterComposer(ComposerState($state.db,
                $state.db.subSectors, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter telemetryRecordsRefs(
      ComposableFilter Function($$TelemetryRecordsTableFilterComposer f) f) {
    final $$TelemetryRecordsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.telemetryRecords,
            getReferencedColumn: (t) => t.deviceId,
            builder: (joinBuilder, parentComposers) =>
                $$TelemetryRecordsTableFilterComposer(ComposerState($state.db,
                    $state.db.telemetryRecords, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$DevicesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get baseUrl => $state.composableBuilder(
      column: $state.table.baseUrl,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productType => $state.composableBuilder(
      column: $state.table.productType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastSeenAt => $state.composableBuilder(
      column: $state.table.lastSeenAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$SubSectorsTableOrderingComposer get subSectorId {
    final $$SubSectorsTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subSectorId,
        referencedTable: $state.db.subSectors,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$SubSectorsTableOrderingComposer(ComposerState($state.db,
                $state.db.subSectors, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$TelemetryRecordsTableCreateCompanionBuilder
    = TelemetryRecordsCompanion Function({
  Value<int> id,
  required String deviceId,
  required DateTime timestamp,
  Value<double?> temperature,
  Value<double?> humidity,
  Value<int?> eco2,
  Value<int?> tvoc,
  Value<int?> aqi,
});
typedef $$TelemetryRecordsTableUpdateCompanionBuilder
    = TelemetryRecordsCompanion Function({
  Value<int> id,
  Value<String> deviceId,
  Value<DateTime> timestamp,
  Value<double?> temperature,
  Value<double?> humidity,
  Value<int?> eco2,
  Value<int?> tvoc,
  Value<int?> aqi,
});

class $$TelemetryRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TelemetryRecordsTable,
    TelemetryRecord,
    $$TelemetryRecordsTableFilterComposer,
    $$TelemetryRecordsTableOrderingComposer,
    $$TelemetryRecordsTableCreateCompanionBuilder,
    $$TelemetryRecordsTableUpdateCompanionBuilder> {
  $$TelemetryRecordsTableTableManager(
      _$AppDatabase db, $TelemetryRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TelemetryRecordsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TelemetryRecordsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<double?> temperature = const Value.absent(),
            Value<double?> humidity = const Value.absent(),
            Value<int?> eco2 = const Value.absent(),
            Value<int?> tvoc = const Value.absent(),
            Value<int?> aqi = const Value.absent(),
          }) =>
              TelemetryRecordsCompanion(
            id: id,
            deviceId: deviceId,
            timestamp: timestamp,
            temperature: temperature,
            humidity: humidity,
            eco2: eco2,
            tvoc: tvoc,
            aqi: aqi,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String deviceId,
            required DateTime timestamp,
            Value<double?> temperature = const Value.absent(),
            Value<double?> humidity = const Value.absent(),
            Value<int?> eco2 = const Value.absent(),
            Value<int?> tvoc = const Value.absent(),
            Value<int?> aqi = const Value.absent(),
          }) =>
              TelemetryRecordsCompanion.insert(
            id: id,
            deviceId: deviceId,
            timestamp: timestamp,
            temperature: temperature,
            humidity: humidity,
            eco2: eco2,
            tvoc: tvoc,
            aqi: aqi,
          ),
        ));
}

class $$TelemetryRecordsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TelemetryRecordsTable> {
  $$TelemetryRecordsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get temperature => $state.composableBuilder(
      column: $state.table.temperature,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get humidity => $state.composableBuilder(
      column: $state.table.humidity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get eco2 => $state.composableBuilder(
      column: $state.table.eco2,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get tvoc => $state.composableBuilder(
      column: $state.table.tvoc,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get aqi => $state.composableBuilder(
      column: $state.table.aqi,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$DevicesTableFilterComposer get deviceId {
    final $$DevicesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $state.db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$DevicesTableFilterComposer(
            ComposerState(
                $state.db, $state.db.devices, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$TelemetryRecordsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TelemetryRecordsTable> {
  $$TelemetryRecordsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get temperature => $state.composableBuilder(
      column: $state.table.temperature,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get humidity => $state.composableBuilder(
      column: $state.table.humidity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get eco2 => $state.composableBuilder(
      column: $state.table.eco2,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get tvoc => $state.composableBuilder(
      column: $state.table.tvoc,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get aqi => $state.composableBuilder(
      column: $state.table.aqi,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$DevicesTableOrderingComposer get deviceId {
    final $$DevicesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.deviceId,
        referencedTable: $state.db.devices,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$DevicesTableOrderingComposer(ComposerState(
                $state.db, $state.db.devices, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SectorsTableTableManager get sectors =>
      $$SectorsTableTableManager(_db, _db.sectors);
  $$SubSectorsTableTableManager get subSectors =>
      $$SubSectorsTableTableManager(_db, _db.subSectors);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$TelemetryRecordsTableTableManager get telemetryRecords =>
      $$TelemetryRecordsTableTableManager(_db, _db.telemetryRecords);
}
