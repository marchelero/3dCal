// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PrintersTable extends Printers
    with TableInfo<$PrintersTable, PrinterProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageWattsMeta = const VerificationMeta(
    'averageWatts',
  );
  @override
  late final GeneratedColumn<int> averageWatts = GeneratedColumn<int>(
    'average_watts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    name,
    averageWatts,
    isDefault,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'printers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrinterProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('average_watts')) {
      context.handle(
        _averageWattsMeta,
        averageWatts.isAcceptableOrUnknown(
          data['average_watts']!,
          _averageWattsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageWattsMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrinterProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrinterProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      averageWatts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_watts'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PrintersTable createAlias(String alias) {
    return $PrintersTable(attachedDatabase, alias);
  }
}

class PrinterProfile extends DataClass implements Insertable<PrinterProfile> {
  final int id;

  /// Marca (ej: "Anycubic", "Creality"). Opcional.
  final String? brand;

  /// Nombre del modelo (ej: "Kobra 3"). Requerido, 1-100 chars.
  final String name;

  /// Consumo promedio en Watts (>= 0). 0 = sin impresora.
  final int averageWatts;

  /// Marca como default. Solo uno a la vez (enforcement en repository).
  final bool isDefault;

  /// Fecha de creacion. UTC.
  final DateTime createdAt;
  const PrinterProfile({
    required this.id,
    this.brand,
    required this.name,
    required this.averageWatts,
    required this.isDefault,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['name'] = Variable<String>(name);
    map['average_watts'] = Variable<int>(averageWatts);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PrintersCompanion toCompanion(bool nullToAbsent) {
    return PrintersCompanion(
      id: Value(id),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      name: Value(name),
      averageWatts: Value(averageWatts),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
    );
  }

  factory PrinterProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrinterProfile(
      id: serializer.fromJson<int>(json['id']),
      brand: serializer.fromJson<String?>(json['brand']),
      name: serializer.fromJson<String>(json['name']),
      averageWatts: serializer.fromJson<int>(json['averageWatts']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brand': serializer.toJson<String?>(brand),
      'name': serializer.toJson<String>(name),
      'averageWatts': serializer.toJson<int>(averageWatts),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PrinterProfile copyWith({
    int? id,
    Value<String?> brand = const Value.absent(),
    String? name,
    int? averageWatts,
    bool? isDefault,
    DateTime? createdAt,
  }) => PrinterProfile(
    id: id ?? this.id,
    brand: brand.present ? brand.value : this.brand,
    name: name ?? this.name,
    averageWatts: averageWatts ?? this.averageWatts,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
  );
  PrinterProfile copyWithCompanion(PrintersCompanion data) {
    return PrinterProfile(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      name: data.name.present ? data.name.value : this.name,
      averageWatts: data.averageWatts.present
          ? data.averageWatts.value
          : this.averageWatts,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrinterProfile(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('averageWatts: $averageWatts, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, brand, name, averageWatts, isDefault, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrinterProfile &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.name == this.name &&
          other.averageWatts == this.averageWatts &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt);
}

class PrintersCompanion extends UpdateCompanion<PrinterProfile> {
  final Value<int> id;
  final Value<String?> brand;
  final Value<String> name;
  final Value<int> averageWatts;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  const PrintersCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.name = const Value.absent(),
    this.averageWatts = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PrintersCompanion.insert({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    required String name,
    required int averageWatts,
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       averageWatts = Value(averageWatts),
       createdAt = Value(createdAt);
  static Insertable<PrinterProfile> custom({
    Expression<int>? id,
    Expression<String>? brand,
    Expression<String>? name,
    Expression<int>? averageWatts,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (name != null) 'name': name,
      if (averageWatts != null) 'average_watts': averageWatts,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PrintersCompanion copyWith({
    Value<int>? id,
    Value<String?>? brand,
    Value<String>? name,
    Value<int>? averageWatts,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
  }) {
    return PrintersCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      averageWatts: averageWatts ?? this.averageWatts,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (averageWatts.present) {
      map['average_watts'] = Variable<int>(averageWatts.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintersCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('averageWatts: $averageWatts, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FilamentsTable extends Filaments
    with TableInfo<$FilamentsTable, Filament> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilamentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pricePerBobbinMeta = const VerificationMeta(
    'pricePerBobbin',
  );
  @override
  late final GeneratedColumn<double> pricePerBobbin = GeneratedColumn<double>(
    'price_per_bobbin',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gramsPerBobbinMeta = const VerificationMeta(
    'gramsPerBobbin',
  );
  @override
  late final GeneratedColumn<double> gramsPerBobbin = GeneratedColumn<double>(
    'grams_per_bobbin',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    pricePerBobbin,
    gramsPerBobbin,
    isDefault,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'filaments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Filament> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('price_per_bobbin')) {
      context.handle(
        _pricePerBobbinMeta,
        pricePerBobbin.isAcceptableOrUnknown(
          data['price_per_bobbin']!,
          _pricePerBobbinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerBobbinMeta);
    }
    if (data.containsKey('grams_per_bobbin')) {
      context.handle(
        _gramsPerBobbinMeta,
        gramsPerBobbin.isAcceptableOrUnknown(
          data['grams_per_bobbin']!,
          _gramsPerBobbinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gramsPerBobbinMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Filament map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Filament(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      pricePerBobbin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_bobbin'],
      )!,
      gramsPerBobbin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams_per_bobbin'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FilamentsTable createAlias(String alias) {
    return $FilamentsTable(attachedDatabase, alias);
  }
}

class Filament extends DataClass implements Insertable<Filament> {
  final int id;

  /// Nombre del filamento (ej: "PLA Negro"). Requerido, 1-100 chars.
  final String name;

  /// Marca (ej: "eSun", "Prusament"). Opcional.
  final String? brand;

  /// Precio de la bobina en BOB. > 0.
  final double pricePerBobbin;

  /// Gramos por bobina. > 0.
  final double gramsPerBobbin;

  /// Marca como default. Solo uno a la vez.
  final bool isDefault;

  /// Fecha de creacion. UTC.
  final DateTime createdAt;
  const Filament({
    required this.id,
    required this.name,
    this.brand,
    required this.pricePerBobbin,
    required this.gramsPerBobbin,
    required this.isDefault,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['price_per_bobbin'] = Variable<double>(pricePerBobbin);
    map['grams_per_bobbin'] = Variable<double>(gramsPerBobbin);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FilamentsCompanion toCompanion(bool nullToAbsent) {
    return FilamentsCompanion(
      id: Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      pricePerBobbin: Value(pricePerBobbin),
      gramsPerBobbin: Value(gramsPerBobbin),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
    );
  }

  factory Filament.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Filament(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      pricePerBobbin: serializer.fromJson<double>(json['pricePerBobbin']),
      gramsPerBobbin: serializer.fromJson<double>(json['gramsPerBobbin']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'pricePerBobbin': serializer.toJson<double>(pricePerBobbin),
      'gramsPerBobbin': serializer.toJson<double>(gramsPerBobbin),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Filament copyWith({
    int? id,
    String? name,
    Value<String?> brand = const Value.absent(),
    double? pricePerBobbin,
    double? gramsPerBobbin,
    bool? isDefault,
    DateTime? createdAt,
  }) => Filament(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    pricePerBobbin: pricePerBobbin ?? this.pricePerBobbin,
    gramsPerBobbin: gramsPerBobbin ?? this.gramsPerBobbin,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
  );
  Filament copyWithCompanion(FilamentsCompanion data) {
    return Filament(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      pricePerBobbin: data.pricePerBobbin.present
          ? data.pricePerBobbin.value
          : this.pricePerBobbin,
      gramsPerBobbin: data.gramsPerBobbin.present
          ? data.gramsPerBobbin.value
          : this.gramsPerBobbin,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Filament(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('pricePerBobbin: $pricePerBobbin, ')
          ..write('gramsPerBobbin: $gramsPerBobbin, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    brand,
    pricePerBobbin,
    gramsPerBobbin,
    isDefault,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Filament &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.pricePerBobbin == this.pricePerBobbin &&
          other.gramsPerBobbin == this.gramsPerBobbin &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt);
}

class FilamentsCompanion extends UpdateCompanion<Filament> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double> pricePerBobbin;
  final Value<double> gramsPerBobbin;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  const FilamentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.pricePerBobbin = const Value.absent(),
    this.gramsPerBobbin = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FilamentsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    required double pricePerBobbin,
    required double gramsPerBobbin,
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       pricePerBobbin = Value(pricePerBobbin),
       gramsPerBobbin = Value(gramsPerBobbin),
       createdAt = Value(createdAt);
  static Insertable<Filament> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? pricePerBobbin,
    Expression<double>? gramsPerBobbin,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (pricePerBobbin != null) 'price_per_bobbin': pricePerBobbin,
      if (gramsPerBobbin != null) 'grams_per_bobbin': gramsPerBobbin,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FilamentsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<double>? pricePerBobbin,
    Value<double>? gramsPerBobbin,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
  }) {
    return FilamentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      pricePerBobbin: pricePerBobbin ?? this.pricePerBobbin,
      gramsPerBobbin: gramsPerBobbin ?? this.gramsPerBobbin,
      isDefault: isDefault ?? this.isDefault,
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
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (pricePerBobbin.present) {
      map['price_per_bobbin'] = Variable<double>(pricePerBobbin.value);
    }
    if (gramsPerBobbin.present) {
      map['grams_per_bobbin'] = Variable<double>(gramsPerBobbin.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilamentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('pricePerBobbin: $pricePerBobbin, ')
          ..write('gramsPerBobbin: $gramsPerBobbin, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CalculationsTable extends Calculations
    with TableInfo<$CalculationsTable, Calculation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalculationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pieceNameMeta = const VerificationMeta(
    'pieceName',
  );
  @override
  late final GeneratedColumn<String> pieceName = GeneratedColumn<String>(
    'piece_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientNameMeta = const VerificationMeta(
    'clientName',
  );
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
    'client_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printerIdMeta = const VerificationMeta(
    'printerId',
  );
  @override
  late final GeneratedColumn<int> printerId = GeneratedColumn<int>(
    'printer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _printerNameSnapshotMeta =
      const VerificationMeta('printerNameSnapshot');
  @override
  late final GeneratedColumn<String> printerNameSnapshot =
      GeneratedColumn<String>(
        'printer_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _printerWattsSnapshotMeta =
      const VerificationMeta('printerWattsSnapshot');
  @override
  late final GeneratedColumn<double> printerWattsSnapshot =
      GeneratedColumn<double>(
        'printer_watts_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _totalHoursMeta = const VerificationMeta(
    'totalHours',
  );
  @override
  late final GeneratedColumn<double> totalHours = GeneratedColumn<double>(
    'total_hours',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountPercentageMeta =
      const VerificationMeta('discountPercentage');
  @override
  late final GeneratedColumn<double> discountPercentage =
      GeneratedColumn<double>(
        'discount_percentage',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _kwhRateSnapshotMeta = const VerificationMeta(
    'kwhRateSnapshot',
  );
  @override
  late final GeneratedColumn<double> kwhRateSnapshot = GeneratedColumn<double>(
    'kwh_rate_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitBaseSnapshotMeta =
      const VerificationMeta('profitBaseSnapshot');
  @override
  late final GeneratedColumn<double> profitBaseSnapshot =
      GeneratedColumn<double>(
        'profit_base_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isSoldMeta = const VerificationMeta('isSold');
  @override
  late final GeneratedColumn<bool> isSold = GeneratedColumn<bool>(
    'is_sold',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sold" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _materialCostSnapshotMeta =
      const VerificationMeta('materialCostSnapshot');
  @override
  late final GeneratedColumn<double> materialCostSnapshot =
      GeneratedColumn<double>(
        'material_cost_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _electricCostSnapshotMeta =
      const VerificationMeta('electricCostSnapshot');
  @override
  late final GeneratedColumn<double> electricCostSnapshot =
      GeneratedColumn<double>(
        'electric_cost_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _laborCostSnapshotMeta = const VerificationMeta(
    'laborCostSnapshot',
  );
  @override
  late final GeneratedColumn<double> laborCostSnapshot =
      GeneratedColumn<double>(
        'labor_cost_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _postProcessCostSnapshotMeta =
      const VerificationMeta('postProcessCostSnapshot');
  @override
  late final GeneratedColumn<double> postProcessCostSnapshot =
      GeneratedColumn<double>(
        'post_process_cost_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _baseCostSnapshotMeta = const VerificationMeta(
    'baseCostSnapshot',
  );
  @override
  late final GeneratedColumn<double> baseCostSnapshot = GeneratedColumn<double>(
    'base_cost_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _failureCostSnapshotMeta =
      const VerificationMeta('failureCostSnapshot');
  @override
  late final GeneratedColumn<double> failureCostSnapshot =
      GeneratedColumn<double>(
        'failure_cost_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _markupCostSnapshotMeta =
      const VerificationMeta('markupCostSnapshot');
  @override
  late final GeneratedColumn<double> markupCostSnapshot =
      GeneratedColumn<double>(
        'markup_cost_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _profitAmountSnapshotMeta =
      const VerificationMeta('profitAmountSnapshot');
  @override
  late final GeneratedColumn<double> profitAmountSnapshot =
      GeneratedColumn<double>(
        'profit_amount_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _minimumChargeAppliedSnapshotMeta =
      const VerificationMeta('minimumChargeAppliedSnapshot');
  @override
  late final GeneratedColumn<double> minimumChargeAppliedSnapshot =
      GeneratedColumn<double>(
        'minimum_charge_applied_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _effectiveTotalSnapshotMeta =
      const VerificationMeta('effectiveTotalSnapshot');
  @override
  late final GeneratedColumn<double> effectiveTotalSnapshot =
      GeneratedColumn<double>(
        'effective_total_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalPriceSnapshotMeta =
      const VerificationMeta('totalPriceSnapshot');
  @override
  late final GeneratedColumn<double> totalPriceSnapshot =
      GeneratedColumn<double>(
        'total_price_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _laborRateSnapshotMeta = const VerificationMeta(
    'laborRateSnapshot',
  );
  @override
  late final GeneratedColumn<double> laborRateSnapshot =
      GeneratedColumn<double>(
        'labor_rate_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _postProcessRateSnapshotMeta =
      const VerificationMeta('postProcessRateSnapshot');
  @override
  late final GeneratedColumn<double> postProcessRateSnapshot =
      GeneratedColumn<double>(
        'post_process_rate_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _failureRateSnapshotMeta =
      const VerificationMeta('failureRateSnapshot');
  @override
  late final GeneratedColumn<double> failureRateSnapshot =
      GeneratedColumn<double>(
        'failure_rate_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _minimumChargeSnapshotMeta =
      const VerificationMeta('minimumChargeSnapshot');
  @override
  late final GeneratedColumn<double> minimumChargeSnapshot =
      GeneratedColumn<double>(
        'minimum_charge_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _markupOnMaterialsSnapshotMeta =
      const VerificationMeta('markupOnMaterialsSnapshot');
  @override
  late final GeneratedColumn<double> markupOnMaterialsSnapshot =
      GeneratedColumn<double>(
        'markup_on_materials_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    pieceName,
    clientName,
    printerId,
    printerNameSnapshot,
    printerWattsSnapshot,
    totalHours,
    discountPercentage,
    kwhRateSnapshot,
    profitBaseSnapshot,
    isSold,
    materialCostSnapshot,
    electricCostSnapshot,
    laborCostSnapshot,
    postProcessCostSnapshot,
    baseCostSnapshot,
    failureCostSnapshot,
    markupCostSnapshot,
    profitAmountSnapshot,
    minimumChargeAppliedSnapshot,
    effectiveTotalSnapshot,
    totalPriceSnapshot,
    laborRateSnapshot,
    postProcessRateSnapshot,
    failureRateSnapshot,
    minimumChargeSnapshot,
    markupOnMaterialsSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calculations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Calculation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('piece_name')) {
      context.handle(
        _pieceNameMeta,
        pieceName.isAcceptableOrUnknown(data['piece_name']!, _pieceNameMeta),
      );
    }
    if (data.containsKey('client_name')) {
      context.handle(
        _clientNameMeta,
        clientName.isAcceptableOrUnknown(data['client_name']!, _clientNameMeta),
      );
    }
    if (data.containsKey('printer_id')) {
      context.handle(
        _printerIdMeta,
        printerId.isAcceptableOrUnknown(data['printer_id']!, _printerIdMeta),
      );
    }
    if (data.containsKey('printer_name_snapshot')) {
      context.handle(
        _printerNameSnapshotMeta,
        printerNameSnapshot.isAcceptableOrUnknown(
          data['printer_name_snapshot']!,
          _printerNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('printer_watts_snapshot')) {
      context.handle(
        _printerWattsSnapshotMeta,
        printerWattsSnapshot.isAcceptableOrUnknown(
          data['printer_watts_snapshot']!,
          _printerWattsSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('total_hours')) {
      context.handle(
        _totalHoursMeta,
        totalHours.isAcceptableOrUnknown(data['total_hours']!, _totalHoursMeta),
      );
    } else if (isInserting) {
      context.missing(_totalHoursMeta);
    }
    if (data.containsKey('discount_percentage')) {
      context.handle(
        _discountPercentageMeta,
        discountPercentage.isAcceptableOrUnknown(
          data['discount_percentage']!,
          _discountPercentageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountPercentageMeta);
    }
    if (data.containsKey('kwh_rate_snapshot')) {
      context.handle(
        _kwhRateSnapshotMeta,
        kwhRateSnapshot.isAcceptableOrUnknown(
          data['kwh_rate_snapshot']!,
          _kwhRateSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_kwhRateSnapshotMeta);
    }
    if (data.containsKey('profit_base_snapshot')) {
      context.handle(
        _profitBaseSnapshotMeta,
        profitBaseSnapshot.isAcceptableOrUnknown(
          data['profit_base_snapshot']!,
          _profitBaseSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profitBaseSnapshotMeta);
    }
    if (data.containsKey('is_sold')) {
      context.handle(
        _isSoldMeta,
        isSold.isAcceptableOrUnknown(data['is_sold']!, _isSoldMeta),
      );
    }
    if (data.containsKey('material_cost_snapshot')) {
      context.handle(
        _materialCostSnapshotMeta,
        materialCostSnapshot.isAcceptableOrUnknown(
          data['material_cost_snapshot']!,
          _materialCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_materialCostSnapshotMeta);
    }
    if (data.containsKey('electric_cost_snapshot')) {
      context.handle(
        _electricCostSnapshotMeta,
        electricCostSnapshot.isAcceptableOrUnknown(
          data['electric_cost_snapshot']!,
          _electricCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_electricCostSnapshotMeta);
    }
    if (data.containsKey('labor_cost_snapshot')) {
      context.handle(
        _laborCostSnapshotMeta,
        laborCostSnapshot.isAcceptableOrUnknown(
          data['labor_cost_snapshot']!,
          _laborCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_laborCostSnapshotMeta);
    }
    if (data.containsKey('post_process_cost_snapshot')) {
      context.handle(
        _postProcessCostSnapshotMeta,
        postProcessCostSnapshot.isAcceptableOrUnknown(
          data['post_process_cost_snapshot']!,
          _postProcessCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_postProcessCostSnapshotMeta);
    }
    if (data.containsKey('base_cost_snapshot')) {
      context.handle(
        _baseCostSnapshotMeta,
        baseCostSnapshot.isAcceptableOrUnknown(
          data['base_cost_snapshot']!,
          _baseCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCostSnapshotMeta);
    }
    if (data.containsKey('failure_cost_snapshot')) {
      context.handle(
        _failureCostSnapshotMeta,
        failureCostSnapshot.isAcceptableOrUnknown(
          data['failure_cost_snapshot']!,
          _failureCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_failureCostSnapshotMeta);
    }
    if (data.containsKey('markup_cost_snapshot')) {
      context.handle(
        _markupCostSnapshotMeta,
        markupCostSnapshot.isAcceptableOrUnknown(
          data['markup_cost_snapshot']!,
          _markupCostSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_markupCostSnapshotMeta);
    }
    if (data.containsKey('profit_amount_snapshot')) {
      context.handle(
        _profitAmountSnapshotMeta,
        profitAmountSnapshot.isAcceptableOrUnknown(
          data['profit_amount_snapshot']!,
          _profitAmountSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profitAmountSnapshotMeta);
    }
    if (data.containsKey('minimum_charge_applied_snapshot')) {
      context.handle(
        _minimumChargeAppliedSnapshotMeta,
        minimumChargeAppliedSnapshot.isAcceptableOrUnknown(
          data['minimum_charge_applied_snapshot']!,
          _minimumChargeAppliedSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minimumChargeAppliedSnapshotMeta);
    }
    if (data.containsKey('effective_total_snapshot')) {
      context.handle(
        _effectiveTotalSnapshotMeta,
        effectiveTotalSnapshot.isAcceptableOrUnknown(
          data['effective_total_snapshot']!,
          _effectiveTotalSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveTotalSnapshotMeta);
    }
    if (data.containsKey('total_price_snapshot')) {
      context.handle(
        _totalPriceSnapshotMeta,
        totalPriceSnapshot.isAcceptableOrUnknown(
          data['total_price_snapshot']!,
          _totalPriceSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPriceSnapshotMeta);
    }
    if (data.containsKey('labor_rate_snapshot')) {
      context.handle(
        _laborRateSnapshotMeta,
        laborRateSnapshot.isAcceptableOrUnknown(
          data['labor_rate_snapshot']!,
          _laborRateSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_laborRateSnapshotMeta);
    }
    if (data.containsKey('post_process_rate_snapshot')) {
      context.handle(
        _postProcessRateSnapshotMeta,
        postProcessRateSnapshot.isAcceptableOrUnknown(
          data['post_process_rate_snapshot']!,
          _postProcessRateSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_postProcessRateSnapshotMeta);
    }
    if (data.containsKey('failure_rate_snapshot')) {
      context.handle(
        _failureRateSnapshotMeta,
        failureRateSnapshot.isAcceptableOrUnknown(
          data['failure_rate_snapshot']!,
          _failureRateSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_failureRateSnapshotMeta);
    }
    if (data.containsKey('minimum_charge_snapshot')) {
      context.handle(
        _minimumChargeSnapshotMeta,
        minimumChargeSnapshot.isAcceptableOrUnknown(
          data['minimum_charge_snapshot']!,
          _minimumChargeSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minimumChargeSnapshotMeta);
    }
    if (data.containsKey('markup_on_materials_snapshot')) {
      context.handle(
        _markupOnMaterialsSnapshotMeta,
        markupOnMaterialsSnapshot.isAcceptableOrUnknown(
          data['markup_on_materials_snapshot']!,
          _markupOnMaterialsSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_markupOnMaterialsSnapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Calculation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Calculation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      pieceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}piece_name'],
      ),
      clientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_name'],
      ),
      printerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}printer_id'],
      ),
      printerNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}printer_name_snapshot'],
      ),
      printerWattsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}printer_watts_snapshot'],
      )!,
      totalHours: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_hours'],
      )!,
      discountPercentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_percentage'],
      )!,
      kwhRateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kwh_rate_snapshot'],
      )!,
      profitBaseSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_base_snapshot'],
      )!,
      isSold: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sold'],
      )!,
      materialCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}material_cost_snapshot'],
      )!,
      electricCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}electric_cost_snapshot'],
      )!,
      laborCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}labor_cost_snapshot'],
      )!,
      postProcessCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}post_process_cost_snapshot'],
      )!,
      baseCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_cost_snapshot'],
      )!,
      failureCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}failure_cost_snapshot'],
      )!,
      markupCostSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}markup_cost_snapshot'],
      )!,
      profitAmountSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_amount_snapshot'],
      )!,
      minimumChargeAppliedSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_charge_applied_snapshot'],
      )!,
      effectiveTotalSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effective_total_snapshot'],
      )!,
      totalPriceSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_price_snapshot'],
      )!,
      laborRateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}labor_rate_snapshot'],
      )!,
      postProcessRateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}post_process_rate_snapshot'],
      )!,
      failureRateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}failure_rate_snapshot'],
      )!,
      minimumChargeSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_charge_snapshot'],
      )!,
      markupOnMaterialsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}markup_on_materials_snapshot'],
      )!,
    );
  }

  @override
  $CalculationsTable createAlias(String alias) {
    return $CalculationsTable(attachedDatabase, alias);
  }
}

class Calculation extends DataClass implements Insertable<Calculation> {
  final int id;

  /// Fecha de creacion. UTC.
  final DateTime createdAt;

  /// Nombre de la pieza. Nullable para proformas rapidas.
  final String? pieceName;

  /// Nombre del cliente. Nullable.
  final String? clientName;

  /// Soft FK a `printers.id`. Nullable si no habia impresora.
  final int? printerId;

  /// Snapshot del nombre de la impresora (para mostrar en historico).
  final String? printerNameSnapshot;

  /// Snapshot de watts de la impresora al guardar.
  final double printerWattsSnapshot;

  /// Tiempo total en horas.
  final double totalHours;

  /// Descuento aplicado en % (0-50).
  final double discountPercentage;

  /// Snapshot de la tarifa electrica al guardar.
  final double kwhRateSnapshot;

  /// Snapshot de la ganancia base al guardar.
  final double profitBaseSnapshot;

  /// Marca como vendida (alimenta dashboard).
  final bool isSold;

  /// Snapshots financieros (cacheados para queries rapidas en dashboard).
  final double materialCostSnapshot;
  final double electricCostSnapshot;
  final double laborCostSnapshot;
  final double postProcessCostSnapshot;
  final double baseCostSnapshot;
  final double failureCostSnapshot;
  final double markupCostSnapshot;
  final double profitAmountSnapshot;
  final double minimumChargeAppliedSnapshot;
  final double effectiveTotalSnapshot;
  final double totalPriceSnapshot;

  /// Snapshots de settings (F1) al momento de guardar.
  final double laborRateSnapshot;
  final double postProcessRateSnapshot;
  final double failureRateSnapshot;
  final double minimumChargeSnapshot;
  final double markupOnMaterialsSnapshot;
  const Calculation({
    required this.id,
    required this.createdAt,
    this.pieceName,
    this.clientName,
    this.printerId,
    this.printerNameSnapshot,
    required this.printerWattsSnapshot,
    required this.totalHours,
    required this.discountPercentage,
    required this.kwhRateSnapshot,
    required this.profitBaseSnapshot,
    required this.isSold,
    required this.materialCostSnapshot,
    required this.electricCostSnapshot,
    required this.laborCostSnapshot,
    required this.postProcessCostSnapshot,
    required this.baseCostSnapshot,
    required this.failureCostSnapshot,
    required this.markupCostSnapshot,
    required this.profitAmountSnapshot,
    required this.minimumChargeAppliedSnapshot,
    required this.effectiveTotalSnapshot,
    required this.totalPriceSnapshot,
    required this.laborRateSnapshot,
    required this.postProcessRateSnapshot,
    required this.failureRateSnapshot,
    required this.minimumChargeSnapshot,
    required this.markupOnMaterialsSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || pieceName != null) {
      map['piece_name'] = Variable<String>(pieceName);
    }
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    if (!nullToAbsent || printerId != null) {
      map['printer_id'] = Variable<int>(printerId);
    }
    if (!nullToAbsent || printerNameSnapshot != null) {
      map['printer_name_snapshot'] = Variable<String>(printerNameSnapshot);
    }
    map['printer_watts_snapshot'] = Variable<double>(printerWattsSnapshot);
    map['total_hours'] = Variable<double>(totalHours);
    map['discount_percentage'] = Variable<double>(discountPercentage);
    map['kwh_rate_snapshot'] = Variable<double>(kwhRateSnapshot);
    map['profit_base_snapshot'] = Variable<double>(profitBaseSnapshot);
    map['is_sold'] = Variable<bool>(isSold);
    map['material_cost_snapshot'] = Variable<double>(materialCostSnapshot);
    map['electric_cost_snapshot'] = Variable<double>(electricCostSnapshot);
    map['labor_cost_snapshot'] = Variable<double>(laborCostSnapshot);
    map['post_process_cost_snapshot'] = Variable<double>(
      postProcessCostSnapshot,
    );
    map['base_cost_snapshot'] = Variable<double>(baseCostSnapshot);
    map['failure_cost_snapshot'] = Variable<double>(failureCostSnapshot);
    map['markup_cost_snapshot'] = Variable<double>(markupCostSnapshot);
    map['profit_amount_snapshot'] = Variable<double>(profitAmountSnapshot);
    map['minimum_charge_applied_snapshot'] = Variable<double>(
      minimumChargeAppliedSnapshot,
    );
    map['effective_total_snapshot'] = Variable<double>(effectiveTotalSnapshot);
    map['total_price_snapshot'] = Variable<double>(totalPriceSnapshot);
    map['labor_rate_snapshot'] = Variable<double>(laborRateSnapshot);
    map['post_process_rate_snapshot'] = Variable<double>(
      postProcessRateSnapshot,
    );
    map['failure_rate_snapshot'] = Variable<double>(failureRateSnapshot);
    map['minimum_charge_snapshot'] = Variable<double>(minimumChargeSnapshot);
    map['markup_on_materials_snapshot'] = Variable<double>(
      markupOnMaterialsSnapshot,
    );
    return map;
  }

  CalculationsCompanion toCompanion(bool nullToAbsent) {
    return CalculationsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      pieceName: pieceName == null && nullToAbsent
          ? const Value.absent()
          : Value(pieceName),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      printerId: printerId == null && nullToAbsent
          ? const Value.absent()
          : Value(printerId),
      printerNameSnapshot: printerNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(printerNameSnapshot),
      printerWattsSnapshot: Value(printerWattsSnapshot),
      totalHours: Value(totalHours),
      discountPercentage: Value(discountPercentage),
      kwhRateSnapshot: Value(kwhRateSnapshot),
      profitBaseSnapshot: Value(profitBaseSnapshot),
      isSold: Value(isSold),
      materialCostSnapshot: Value(materialCostSnapshot),
      electricCostSnapshot: Value(electricCostSnapshot),
      laborCostSnapshot: Value(laborCostSnapshot),
      postProcessCostSnapshot: Value(postProcessCostSnapshot),
      baseCostSnapshot: Value(baseCostSnapshot),
      failureCostSnapshot: Value(failureCostSnapshot),
      markupCostSnapshot: Value(markupCostSnapshot),
      profitAmountSnapshot: Value(profitAmountSnapshot),
      minimumChargeAppliedSnapshot: Value(minimumChargeAppliedSnapshot),
      effectiveTotalSnapshot: Value(effectiveTotalSnapshot),
      totalPriceSnapshot: Value(totalPriceSnapshot),
      laborRateSnapshot: Value(laborRateSnapshot),
      postProcessRateSnapshot: Value(postProcessRateSnapshot),
      failureRateSnapshot: Value(failureRateSnapshot),
      minimumChargeSnapshot: Value(minimumChargeSnapshot),
      markupOnMaterialsSnapshot: Value(markupOnMaterialsSnapshot),
    );
  }

  factory Calculation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Calculation(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      pieceName: serializer.fromJson<String?>(json['pieceName']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      printerId: serializer.fromJson<int?>(json['printerId']),
      printerNameSnapshot: serializer.fromJson<String?>(
        json['printerNameSnapshot'],
      ),
      printerWattsSnapshot: serializer.fromJson<double>(
        json['printerWattsSnapshot'],
      ),
      totalHours: serializer.fromJson<double>(json['totalHours']),
      discountPercentage: serializer.fromJson<double>(
        json['discountPercentage'],
      ),
      kwhRateSnapshot: serializer.fromJson<double>(json['kwhRateSnapshot']),
      profitBaseSnapshot: serializer.fromJson<double>(
        json['profitBaseSnapshot'],
      ),
      isSold: serializer.fromJson<bool>(json['isSold']),
      materialCostSnapshot: serializer.fromJson<double>(
        json['materialCostSnapshot'],
      ),
      electricCostSnapshot: serializer.fromJson<double>(
        json['electricCostSnapshot'],
      ),
      laborCostSnapshot: serializer.fromJson<double>(json['laborCostSnapshot']),
      postProcessCostSnapshot: serializer.fromJson<double>(
        json['postProcessCostSnapshot'],
      ),
      baseCostSnapshot: serializer.fromJson<double>(json['baseCostSnapshot']),
      failureCostSnapshot: serializer.fromJson<double>(
        json['failureCostSnapshot'],
      ),
      markupCostSnapshot: serializer.fromJson<double>(
        json['markupCostSnapshot'],
      ),
      profitAmountSnapshot: serializer.fromJson<double>(
        json['profitAmountSnapshot'],
      ),
      minimumChargeAppliedSnapshot: serializer.fromJson<double>(
        json['minimumChargeAppliedSnapshot'],
      ),
      effectiveTotalSnapshot: serializer.fromJson<double>(
        json['effectiveTotalSnapshot'],
      ),
      totalPriceSnapshot: serializer.fromJson<double>(
        json['totalPriceSnapshot'],
      ),
      laborRateSnapshot: serializer.fromJson<double>(json['laborRateSnapshot']),
      postProcessRateSnapshot: serializer.fromJson<double>(
        json['postProcessRateSnapshot'],
      ),
      failureRateSnapshot: serializer.fromJson<double>(
        json['failureRateSnapshot'],
      ),
      minimumChargeSnapshot: serializer.fromJson<double>(
        json['minimumChargeSnapshot'],
      ),
      markupOnMaterialsSnapshot: serializer.fromJson<double>(
        json['markupOnMaterialsSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'pieceName': serializer.toJson<String?>(pieceName),
      'clientName': serializer.toJson<String?>(clientName),
      'printerId': serializer.toJson<int?>(printerId),
      'printerNameSnapshot': serializer.toJson<String?>(printerNameSnapshot),
      'printerWattsSnapshot': serializer.toJson<double>(printerWattsSnapshot),
      'totalHours': serializer.toJson<double>(totalHours),
      'discountPercentage': serializer.toJson<double>(discountPercentage),
      'kwhRateSnapshot': serializer.toJson<double>(kwhRateSnapshot),
      'profitBaseSnapshot': serializer.toJson<double>(profitBaseSnapshot),
      'isSold': serializer.toJson<bool>(isSold),
      'materialCostSnapshot': serializer.toJson<double>(materialCostSnapshot),
      'electricCostSnapshot': serializer.toJson<double>(electricCostSnapshot),
      'laborCostSnapshot': serializer.toJson<double>(laborCostSnapshot),
      'postProcessCostSnapshot': serializer.toJson<double>(
        postProcessCostSnapshot,
      ),
      'baseCostSnapshot': serializer.toJson<double>(baseCostSnapshot),
      'failureCostSnapshot': serializer.toJson<double>(failureCostSnapshot),
      'markupCostSnapshot': serializer.toJson<double>(markupCostSnapshot),
      'profitAmountSnapshot': serializer.toJson<double>(profitAmountSnapshot),
      'minimumChargeAppliedSnapshot': serializer.toJson<double>(
        minimumChargeAppliedSnapshot,
      ),
      'effectiveTotalSnapshot': serializer.toJson<double>(
        effectiveTotalSnapshot,
      ),
      'totalPriceSnapshot': serializer.toJson<double>(totalPriceSnapshot),
      'laborRateSnapshot': serializer.toJson<double>(laborRateSnapshot),
      'postProcessRateSnapshot': serializer.toJson<double>(
        postProcessRateSnapshot,
      ),
      'failureRateSnapshot': serializer.toJson<double>(failureRateSnapshot),
      'minimumChargeSnapshot': serializer.toJson<double>(minimumChargeSnapshot),
      'markupOnMaterialsSnapshot': serializer.toJson<double>(
        markupOnMaterialsSnapshot,
      ),
    };
  }

  Calculation copyWith({
    int? id,
    DateTime? createdAt,
    Value<String?> pieceName = const Value.absent(),
    Value<String?> clientName = const Value.absent(),
    Value<int?> printerId = const Value.absent(),
    Value<String?> printerNameSnapshot = const Value.absent(),
    double? printerWattsSnapshot,
    double? totalHours,
    double? discountPercentage,
    double? kwhRateSnapshot,
    double? profitBaseSnapshot,
    bool? isSold,
    double? materialCostSnapshot,
    double? electricCostSnapshot,
    double? laborCostSnapshot,
    double? postProcessCostSnapshot,
    double? baseCostSnapshot,
    double? failureCostSnapshot,
    double? markupCostSnapshot,
    double? profitAmountSnapshot,
    double? minimumChargeAppliedSnapshot,
    double? effectiveTotalSnapshot,
    double? totalPriceSnapshot,
    double? laborRateSnapshot,
    double? postProcessRateSnapshot,
    double? failureRateSnapshot,
    double? minimumChargeSnapshot,
    double? markupOnMaterialsSnapshot,
  }) => Calculation(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    pieceName: pieceName.present ? pieceName.value : this.pieceName,
    clientName: clientName.present ? clientName.value : this.clientName,
    printerId: printerId.present ? printerId.value : this.printerId,
    printerNameSnapshot: printerNameSnapshot.present
        ? printerNameSnapshot.value
        : this.printerNameSnapshot,
    printerWattsSnapshot: printerWattsSnapshot ?? this.printerWattsSnapshot,
    totalHours: totalHours ?? this.totalHours,
    discountPercentage: discountPercentage ?? this.discountPercentage,
    kwhRateSnapshot: kwhRateSnapshot ?? this.kwhRateSnapshot,
    profitBaseSnapshot: profitBaseSnapshot ?? this.profitBaseSnapshot,
    isSold: isSold ?? this.isSold,
    materialCostSnapshot: materialCostSnapshot ?? this.materialCostSnapshot,
    electricCostSnapshot: electricCostSnapshot ?? this.electricCostSnapshot,
    laborCostSnapshot: laborCostSnapshot ?? this.laborCostSnapshot,
    postProcessCostSnapshot:
        postProcessCostSnapshot ?? this.postProcessCostSnapshot,
    baseCostSnapshot: baseCostSnapshot ?? this.baseCostSnapshot,
    failureCostSnapshot: failureCostSnapshot ?? this.failureCostSnapshot,
    markupCostSnapshot: markupCostSnapshot ?? this.markupCostSnapshot,
    profitAmountSnapshot: profitAmountSnapshot ?? this.profitAmountSnapshot,
    minimumChargeAppliedSnapshot:
        minimumChargeAppliedSnapshot ?? this.minimumChargeAppliedSnapshot,
    effectiveTotalSnapshot:
        effectiveTotalSnapshot ?? this.effectiveTotalSnapshot,
    totalPriceSnapshot: totalPriceSnapshot ?? this.totalPriceSnapshot,
    laborRateSnapshot: laborRateSnapshot ?? this.laborRateSnapshot,
    postProcessRateSnapshot:
        postProcessRateSnapshot ?? this.postProcessRateSnapshot,
    failureRateSnapshot: failureRateSnapshot ?? this.failureRateSnapshot,
    minimumChargeSnapshot: minimumChargeSnapshot ?? this.minimumChargeSnapshot,
    markupOnMaterialsSnapshot:
        markupOnMaterialsSnapshot ?? this.markupOnMaterialsSnapshot,
  );
  Calculation copyWithCompanion(CalculationsCompanion data) {
    return Calculation(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pieceName: data.pieceName.present ? data.pieceName.value : this.pieceName,
      clientName: data.clientName.present
          ? data.clientName.value
          : this.clientName,
      printerId: data.printerId.present ? data.printerId.value : this.printerId,
      printerNameSnapshot: data.printerNameSnapshot.present
          ? data.printerNameSnapshot.value
          : this.printerNameSnapshot,
      printerWattsSnapshot: data.printerWattsSnapshot.present
          ? data.printerWattsSnapshot.value
          : this.printerWattsSnapshot,
      totalHours: data.totalHours.present
          ? data.totalHours.value
          : this.totalHours,
      discountPercentage: data.discountPercentage.present
          ? data.discountPercentage.value
          : this.discountPercentage,
      kwhRateSnapshot: data.kwhRateSnapshot.present
          ? data.kwhRateSnapshot.value
          : this.kwhRateSnapshot,
      profitBaseSnapshot: data.profitBaseSnapshot.present
          ? data.profitBaseSnapshot.value
          : this.profitBaseSnapshot,
      isSold: data.isSold.present ? data.isSold.value : this.isSold,
      materialCostSnapshot: data.materialCostSnapshot.present
          ? data.materialCostSnapshot.value
          : this.materialCostSnapshot,
      electricCostSnapshot: data.electricCostSnapshot.present
          ? data.electricCostSnapshot.value
          : this.electricCostSnapshot,
      laborCostSnapshot: data.laborCostSnapshot.present
          ? data.laborCostSnapshot.value
          : this.laborCostSnapshot,
      postProcessCostSnapshot: data.postProcessCostSnapshot.present
          ? data.postProcessCostSnapshot.value
          : this.postProcessCostSnapshot,
      baseCostSnapshot: data.baseCostSnapshot.present
          ? data.baseCostSnapshot.value
          : this.baseCostSnapshot,
      failureCostSnapshot: data.failureCostSnapshot.present
          ? data.failureCostSnapshot.value
          : this.failureCostSnapshot,
      markupCostSnapshot: data.markupCostSnapshot.present
          ? data.markupCostSnapshot.value
          : this.markupCostSnapshot,
      profitAmountSnapshot: data.profitAmountSnapshot.present
          ? data.profitAmountSnapshot.value
          : this.profitAmountSnapshot,
      minimumChargeAppliedSnapshot: data.minimumChargeAppliedSnapshot.present
          ? data.minimumChargeAppliedSnapshot.value
          : this.minimumChargeAppliedSnapshot,
      effectiveTotalSnapshot: data.effectiveTotalSnapshot.present
          ? data.effectiveTotalSnapshot.value
          : this.effectiveTotalSnapshot,
      totalPriceSnapshot: data.totalPriceSnapshot.present
          ? data.totalPriceSnapshot.value
          : this.totalPriceSnapshot,
      laborRateSnapshot: data.laborRateSnapshot.present
          ? data.laborRateSnapshot.value
          : this.laborRateSnapshot,
      postProcessRateSnapshot: data.postProcessRateSnapshot.present
          ? data.postProcessRateSnapshot.value
          : this.postProcessRateSnapshot,
      failureRateSnapshot: data.failureRateSnapshot.present
          ? data.failureRateSnapshot.value
          : this.failureRateSnapshot,
      minimumChargeSnapshot: data.minimumChargeSnapshot.present
          ? data.minimumChargeSnapshot.value
          : this.minimumChargeSnapshot,
      markupOnMaterialsSnapshot: data.markupOnMaterialsSnapshot.present
          ? data.markupOnMaterialsSnapshot.value
          : this.markupOnMaterialsSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Calculation(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('pieceName: $pieceName, ')
          ..write('clientName: $clientName, ')
          ..write('printerId: $printerId, ')
          ..write('printerNameSnapshot: $printerNameSnapshot, ')
          ..write('printerWattsSnapshot: $printerWattsSnapshot, ')
          ..write('totalHours: $totalHours, ')
          ..write('discountPercentage: $discountPercentage, ')
          ..write('kwhRateSnapshot: $kwhRateSnapshot, ')
          ..write('profitBaseSnapshot: $profitBaseSnapshot, ')
          ..write('isSold: $isSold, ')
          ..write('materialCostSnapshot: $materialCostSnapshot, ')
          ..write('electricCostSnapshot: $electricCostSnapshot, ')
          ..write('laborCostSnapshot: $laborCostSnapshot, ')
          ..write('postProcessCostSnapshot: $postProcessCostSnapshot, ')
          ..write('baseCostSnapshot: $baseCostSnapshot, ')
          ..write('failureCostSnapshot: $failureCostSnapshot, ')
          ..write('markupCostSnapshot: $markupCostSnapshot, ')
          ..write('profitAmountSnapshot: $profitAmountSnapshot, ')
          ..write(
            'minimumChargeAppliedSnapshot: $minimumChargeAppliedSnapshot, ',
          )
          ..write('effectiveTotalSnapshot: $effectiveTotalSnapshot, ')
          ..write('totalPriceSnapshot: $totalPriceSnapshot, ')
          ..write('laborRateSnapshot: $laborRateSnapshot, ')
          ..write('postProcessRateSnapshot: $postProcessRateSnapshot, ')
          ..write('failureRateSnapshot: $failureRateSnapshot, ')
          ..write('minimumChargeSnapshot: $minimumChargeSnapshot, ')
          ..write('markupOnMaterialsSnapshot: $markupOnMaterialsSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    pieceName,
    clientName,
    printerId,
    printerNameSnapshot,
    printerWattsSnapshot,
    totalHours,
    discountPercentage,
    kwhRateSnapshot,
    profitBaseSnapshot,
    isSold,
    materialCostSnapshot,
    electricCostSnapshot,
    laborCostSnapshot,
    postProcessCostSnapshot,
    baseCostSnapshot,
    failureCostSnapshot,
    markupCostSnapshot,
    profitAmountSnapshot,
    minimumChargeAppliedSnapshot,
    effectiveTotalSnapshot,
    totalPriceSnapshot,
    laborRateSnapshot,
    postProcessRateSnapshot,
    failureRateSnapshot,
    minimumChargeSnapshot,
    markupOnMaterialsSnapshot,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Calculation &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.pieceName == this.pieceName &&
          other.clientName == this.clientName &&
          other.printerId == this.printerId &&
          other.printerNameSnapshot == this.printerNameSnapshot &&
          other.printerWattsSnapshot == this.printerWattsSnapshot &&
          other.totalHours == this.totalHours &&
          other.discountPercentage == this.discountPercentage &&
          other.kwhRateSnapshot == this.kwhRateSnapshot &&
          other.profitBaseSnapshot == this.profitBaseSnapshot &&
          other.isSold == this.isSold &&
          other.materialCostSnapshot == this.materialCostSnapshot &&
          other.electricCostSnapshot == this.electricCostSnapshot &&
          other.laborCostSnapshot == this.laborCostSnapshot &&
          other.postProcessCostSnapshot == this.postProcessCostSnapshot &&
          other.baseCostSnapshot == this.baseCostSnapshot &&
          other.failureCostSnapshot == this.failureCostSnapshot &&
          other.markupCostSnapshot == this.markupCostSnapshot &&
          other.profitAmountSnapshot == this.profitAmountSnapshot &&
          other.minimumChargeAppliedSnapshot ==
              this.minimumChargeAppliedSnapshot &&
          other.effectiveTotalSnapshot == this.effectiveTotalSnapshot &&
          other.totalPriceSnapshot == this.totalPriceSnapshot &&
          other.laborRateSnapshot == this.laborRateSnapshot &&
          other.postProcessRateSnapshot == this.postProcessRateSnapshot &&
          other.failureRateSnapshot == this.failureRateSnapshot &&
          other.minimumChargeSnapshot == this.minimumChargeSnapshot &&
          other.markupOnMaterialsSnapshot == this.markupOnMaterialsSnapshot);
}

class CalculationsCompanion extends UpdateCompanion<Calculation> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<String?> pieceName;
  final Value<String?> clientName;
  final Value<int?> printerId;
  final Value<String?> printerNameSnapshot;
  final Value<double> printerWattsSnapshot;
  final Value<double> totalHours;
  final Value<double> discountPercentage;
  final Value<double> kwhRateSnapshot;
  final Value<double> profitBaseSnapshot;
  final Value<bool> isSold;
  final Value<double> materialCostSnapshot;
  final Value<double> electricCostSnapshot;
  final Value<double> laborCostSnapshot;
  final Value<double> postProcessCostSnapshot;
  final Value<double> baseCostSnapshot;
  final Value<double> failureCostSnapshot;
  final Value<double> markupCostSnapshot;
  final Value<double> profitAmountSnapshot;
  final Value<double> minimumChargeAppliedSnapshot;
  final Value<double> effectiveTotalSnapshot;
  final Value<double> totalPriceSnapshot;
  final Value<double> laborRateSnapshot;
  final Value<double> postProcessRateSnapshot;
  final Value<double> failureRateSnapshot;
  final Value<double> minimumChargeSnapshot;
  final Value<double> markupOnMaterialsSnapshot;
  const CalculationsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pieceName = const Value.absent(),
    this.clientName = const Value.absent(),
    this.printerId = const Value.absent(),
    this.printerNameSnapshot = const Value.absent(),
    this.printerWattsSnapshot = const Value.absent(),
    this.totalHours = const Value.absent(),
    this.discountPercentage = const Value.absent(),
    this.kwhRateSnapshot = const Value.absent(),
    this.profitBaseSnapshot = const Value.absent(),
    this.isSold = const Value.absent(),
    this.materialCostSnapshot = const Value.absent(),
    this.electricCostSnapshot = const Value.absent(),
    this.laborCostSnapshot = const Value.absent(),
    this.postProcessCostSnapshot = const Value.absent(),
    this.baseCostSnapshot = const Value.absent(),
    this.failureCostSnapshot = const Value.absent(),
    this.markupCostSnapshot = const Value.absent(),
    this.profitAmountSnapshot = const Value.absent(),
    this.minimumChargeAppliedSnapshot = const Value.absent(),
    this.effectiveTotalSnapshot = const Value.absent(),
    this.totalPriceSnapshot = const Value.absent(),
    this.laborRateSnapshot = const Value.absent(),
    this.postProcessRateSnapshot = const Value.absent(),
    this.failureRateSnapshot = const Value.absent(),
    this.minimumChargeSnapshot = const Value.absent(),
    this.markupOnMaterialsSnapshot = const Value.absent(),
  });
  CalculationsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    this.pieceName = const Value.absent(),
    this.clientName = const Value.absent(),
    this.printerId = const Value.absent(),
    this.printerNameSnapshot = const Value.absent(),
    this.printerWattsSnapshot = const Value.absent(),
    required double totalHours,
    required double discountPercentage,
    required double kwhRateSnapshot,
    required double profitBaseSnapshot,
    this.isSold = const Value.absent(),
    required double materialCostSnapshot,
    required double electricCostSnapshot,
    required double laborCostSnapshot,
    required double postProcessCostSnapshot,
    required double baseCostSnapshot,
    required double failureCostSnapshot,
    required double markupCostSnapshot,
    required double profitAmountSnapshot,
    required double minimumChargeAppliedSnapshot,
    required double effectiveTotalSnapshot,
    required double totalPriceSnapshot,
    required double laborRateSnapshot,
    required double postProcessRateSnapshot,
    required double failureRateSnapshot,
    required double minimumChargeSnapshot,
    required double markupOnMaterialsSnapshot,
  }) : createdAt = Value(createdAt),
       totalHours = Value(totalHours),
       discountPercentage = Value(discountPercentage),
       kwhRateSnapshot = Value(kwhRateSnapshot),
       profitBaseSnapshot = Value(profitBaseSnapshot),
       materialCostSnapshot = Value(materialCostSnapshot),
       electricCostSnapshot = Value(electricCostSnapshot),
       laborCostSnapshot = Value(laborCostSnapshot),
       postProcessCostSnapshot = Value(postProcessCostSnapshot),
       baseCostSnapshot = Value(baseCostSnapshot),
       failureCostSnapshot = Value(failureCostSnapshot),
       markupCostSnapshot = Value(markupCostSnapshot),
       profitAmountSnapshot = Value(profitAmountSnapshot),
       minimumChargeAppliedSnapshot = Value(minimumChargeAppliedSnapshot),
       effectiveTotalSnapshot = Value(effectiveTotalSnapshot),
       totalPriceSnapshot = Value(totalPriceSnapshot),
       laborRateSnapshot = Value(laborRateSnapshot),
       postProcessRateSnapshot = Value(postProcessRateSnapshot),
       failureRateSnapshot = Value(failureRateSnapshot),
       minimumChargeSnapshot = Value(minimumChargeSnapshot),
       markupOnMaterialsSnapshot = Value(markupOnMaterialsSnapshot);
  static Insertable<Calculation> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? pieceName,
    Expression<String>? clientName,
    Expression<int>? printerId,
    Expression<String>? printerNameSnapshot,
    Expression<double>? printerWattsSnapshot,
    Expression<double>? totalHours,
    Expression<double>? discountPercentage,
    Expression<double>? kwhRateSnapshot,
    Expression<double>? profitBaseSnapshot,
    Expression<bool>? isSold,
    Expression<double>? materialCostSnapshot,
    Expression<double>? electricCostSnapshot,
    Expression<double>? laborCostSnapshot,
    Expression<double>? postProcessCostSnapshot,
    Expression<double>? baseCostSnapshot,
    Expression<double>? failureCostSnapshot,
    Expression<double>? markupCostSnapshot,
    Expression<double>? profitAmountSnapshot,
    Expression<double>? minimumChargeAppliedSnapshot,
    Expression<double>? effectiveTotalSnapshot,
    Expression<double>? totalPriceSnapshot,
    Expression<double>? laborRateSnapshot,
    Expression<double>? postProcessRateSnapshot,
    Expression<double>? failureRateSnapshot,
    Expression<double>? minimumChargeSnapshot,
    Expression<double>? markupOnMaterialsSnapshot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (pieceName != null) 'piece_name': pieceName,
      if (clientName != null) 'client_name': clientName,
      if (printerId != null) 'printer_id': printerId,
      if (printerNameSnapshot != null)
        'printer_name_snapshot': printerNameSnapshot,
      if (printerWattsSnapshot != null)
        'printer_watts_snapshot': printerWattsSnapshot,
      if (totalHours != null) 'total_hours': totalHours,
      if (discountPercentage != null) 'discount_percentage': discountPercentage,
      if (kwhRateSnapshot != null) 'kwh_rate_snapshot': kwhRateSnapshot,
      if (profitBaseSnapshot != null)
        'profit_base_snapshot': profitBaseSnapshot,
      if (isSold != null) 'is_sold': isSold,
      if (materialCostSnapshot != null)
        'material_cost_snapshot': materialCostSnapshot,
      if (electricCostSnapshot != null)
        'electric_cost_snapshot': electricCostSnapshot,
      if (laborCostSnapshot != null) 'labor_cost_snapshot': laborCostSnapshot,
      if (postProcessCostSnapshot != null)
        'post_process_cost_snapshot': postProcessCostSnapshot,
      if (baseCostSnapshot != null) 'base_cost_snapshot': baseCostSnapshot,
      if (failureCostSnapshot != null)
        'failure_cost_snapshot': failureCostSnapshot,
      if (markupCostSnapshot != null)
        'markup_cost_snapshot': markupCostSnapshot,
      if (profitAmountSnapshot != null)
        'profit_amount_snapshot': profitAmountSnapshot,
      if (minimumChargeAppliedSnapshot != null)
        'minimum_charge_applied_snapshot': minimumChargeAppliedSnapshot,
      if (effectiveTotalSnapshot != null)
        'effective_total_snapshot': effectiveTotalSnapshot,
      if (totalPriceSnapshot != null)
        'total_price_snapshot': totalPriceSnapshot,
      if (laborRateSnapshot != null) 'labor_rate_snapshot': laborRateSnapshot,
      if (postProcessRateSnapshot != null)
        'post_process_rate_snapshot': postProcessRateSnapshot,
      if (failureRateSnapshot != null)
        'failure_rate_snapshot': failureRateSnapshot,
      if (minimumChargeSnapshot != null)
        'minimum_charge_snapshot': minimumChargeSnapshot,
      if (markupOnMaterialsSnapshot != null)
        'markup_on_materials_snapshot': markupOnMaterialsSnapshot,
    });
  }

  CalculationsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<String?>? pieceName,
    Value<String?>? clientName,
    Value<int?>? printerId,
    Value<String?>? printerNameSnapshot,
    Value<double>? printerWattsSnapshot,
    Value<double>? totalHours,
    Value<double>? discountPercentage,
    Value<double>? kwhRateSnapshot,
    Value<double>? profitBaseSnapshot,
    Value<bool>? isSold,
    Value<double>? materialCostSnapshot,
    Value<double>? electricCostSnapshot,
    Value<double>? laborCostSnapshot,
    Value<double>? postProcessCostSnapshot,
    Value<double>? baseCostSnapshot,
    Value<double>? failureCostSnapshot,
    Value<double>? markupCostSnapshot,
    Value<double>? profitAmountSnapshot,
    Value<double>? minimumChargeAppliedSnapshot,
    Value<double>? effectiveTotalSnapshot,
    Value<double>? totalPriceSnapshot,
    Value<double>? laborRateSnapshot,
    Value<double>? postProcessRateSnapshot,
    Value<double>? failureRateSnapshot,
    Value<double>? minimumChargeSnapshot,
    Value<double>? markupOnMaterialsSnapshot,
  }) {
    return CalculationsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      pieceName: pieceName ?? this.pieceName,
      clientName: clientName ?? this.clientName,
      printerId: printerId ?? this.printerId,
      printerNameSnapshot: printerNameSnapshot ?? this.printerNameSnapshot,
      printerWattsSnapshot: printerWattsSnapshot ?? this.printerWattsSnapshot,
      totalHours: totalHours ?? this.totalHours,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      kwhRateSnapshot: kwhRateSnapshot ?? this.kwhRateSnapshot,
      profitBaseSnapshot: profitBaseSnapshot ?? this.profitBaseSnapshot,
      isSold: isSold ?? this.isSold,
      materialCostSnapshot: materialCostSnapshot ?? this.materialCostSnapshot,
      electricCostSnapshot: electricCostSnapshot ?? this.electricCostSnapshot,
      laborCostSnapshot: laborCostSnapshot ?? this.laborCostSnapshot,
      postProcessCostSnapshot:
          postProcessCostSnapshot ?? this.postProcessCostSnapshot,
      baseCostSnapshot: baseCostSnapshot ?? this.baseCostSnapshot,
      failureCostSnapshot: failureCostSnapshot ?? this.failureCostSnapshot,
      markupCostSnapshot: markupCostSnapshot ?? this.markupCostSnapshot,
      profitAmountSnapshot: profitAmountSnapshot ?? this.profitAmountSnapshot,
      minimumChargeAppliedSnapshot:
          minimumChargeAppliedSnapshot ?? this.minimumChargeAppliedSnapshot,
      effectiveTotalSnapshot:
          effectiveTotalSnapshot ?? this.effectiveTotalSnapshot,
      totalPriceSnapshot: totalPriceSnapshot ?? this.totalPriceSnapshot,
      laborRateSnapshot: laborRateSnapshot ?? this.laborRateSnapshot,
      postProcessRateSnapshot:
          postProcessRateSnapshot ?? this.postProcessRateSnapshot,
      failureRateSnapshot: failureRateSnapshot ?? this.failureRateSnapshot,
      minimumChargeSnapshot:
          minimumChargeSnapshot ?? this.minimumChargeSnapshot,
      markupOnMaterialsSnapshot:
          markupOnMaterialsSnapshot ?? this.markupOnMaterialsSnapshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pieceName.present) {
      map['piece_name'] = Variable<String>(pieceName.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (printerId.present) {
      map['printer_id'] = Variable<int>(printerId.value);
    }
    if (printerNameSnapshot.present) {
      map['printer_name_snapshot'] = Variable<String>(
        printerNameSnapshot.value,
      );
    }
    if (printerWattsSnapshot.present) {
      map['printer_watts_snapshot'] = Variable<double>(
        printerWattsSnapshot.value,
      );
    }
    if (totalHours.present) {
      map['total_hours'] = Variable<double>(totalHours.value);
    }
    if (discountPercentage.present) {
      map['discount_percentage'] = Variable<double>(discountPercentage.value);
    }
    if (kwhRateSnapshot.present) {
      map['kwh_rate_snapshot'] = Variable<double>(kwhRateSnapshot.value);
    }
    if (profitBaseSnapshot.present) {
      map['profit_base_snapshot'] = Variable<double>(profitBaseSnapshot.value);
    }
    if (isSold.present) {
      map['is_sold'] = Variable<bool>(isSold.value);
    }
    if (materialCostSnapshot.present) {
      map['material_cost_snapshot'] = Variable<double>(
        materialCostSnapshot.value,
      );
    }
    if (electricCostSnapshot.present) {
      map['electric_cost_snapshot'] = Variable<double>(
        electricCostSnapshot.value,
      );
    }
    if (laborCostSnapshot.present) {
      map['labor_cost_snapshot'] = Variable<double>(laborCostSnapshot.value);
    }
    if (postProcessCostSnapshot.present) {
      map['post_process_cost_snapshot'] = Variable<double>(
        postProcessCostSnapshot.value,
      );
    }
    if (baseCostSnapshot.present) {
      map['base_cost_snapshot'] = Variable<double>(baseCostSnapshot.value);
    }
    if (failureCostSnapshot.present) {
      map['failure_cost_snapshot'] = Variable<double>(
        failureCostSnapshot.value,
      );
    }
    if (markupCostSnapshot.present) {
      map['markup_cost_snapshot'] = Variable<double>(markupCostSnapshot.value);
    }
    if (profitAmountSnapshot.present) {
      map['profit_amount_snapshot'] = Variable<double>(
        profitAmountSnapshot.value,
      );
    }
    if (minimumChargeAppliedSnapshot.present) {
      map['minimum_charge_applied_snapshot'] = Variable<double>(
        minimumChargeAppliedSnapshot.value,
      );
    }
    if (effectiveTotalSnapshot.present) {
      map['effective_total_snapshot'] = Variable<double>(
        effectiveTotalSnapshot.value,
      );
    }
    if (totalPriceSnapshot.present) {
      map['total_price_snapshot'] = Variable<double>(totalPriceSnapshot.value);
    }
    if (laborRateSnapshot.present) {
      map['labor_rate_snapshot'] = Variable<double>(laborRateSnapshot.value);
    }
    if (postProcessRateSnapshot.present) {
      map['post_process_rate_snapshot'] = Variable<double>(
        postProcessRateSnapshot.value,
      );
    }
    if (failureRateSnapshot.present) {
      map['failure_rate_snapshot'] = Variable<double>(
        failureRateSnapshot.value,
      );
    }
    if (minimumChargeSnapshot.present) {
      map['minimum_charge_snapshot'] = Variable<double>(
        minimumChargeSnapshot.value,
      );
    }
    if (markupOnMaterialsSnapshot.present) {
      map['markup_on_materials_snapshot'] = Variable<double>(
        markupOnMaterialsSnapshot.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalculationsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('pieceName: $pieceName, ')
          ..write('clientName: $clientName, ')
          ..write('printerId: $printerId, ')
          ..write('printerNameSnapshot: $printerNameSnapshot, ')
          ..write('printerWattsSnapshot: $printerWattsSnapshot, ')
          ..write('totalHours: $totalHours, ')
          ..write('discountPercentage: $discountPercentage, ')
          ..write('kwhRateSnapshot: $kwhRateSnapshot, ')
          ..write('profitBaseSnapshot: $profitBaseSnapshot, ')
          ..write('isSold: $isSold, ')
          ..write('materialCostSnapshot: $materialCostSnapshot, ')
          ..write('electricCostSnapshot: $electricCostSnapshot, ')
          ..write('laborCostSnapshot: $laborCostSnapshot, ')
          ..write('postProcessCostSnapshot: $postProcessCostSnapshot, ')
          ..write('baseCostSnapshot: $baseCostSnapshot, ')
          ..write('failureCostSnapshot: $failureCostSnapshot, ')
          ..write('markupCostSnapshot: $markupCostSnapshot, ')
          ..write('profitAmountSnapshot: $profitAmountSnapshot, ')
          ..write(
            'minimumChargeAppliedSnapshot: $minimumChargeAppliedSnapshot, ',
          )
          ..write('effectiveTotalSnapshot: $effectiveTotalSnapshot, ')
          ..write('totalPriceSnapshot: $totalPriceSnapshot, ')
          ..write('laborRateSnapshot: $laborRateSnapshot, ')
          ..write('postProcessRateSnapshot: $postProcessRateSnapshot, ')
          ..write('failureRateSnapshot: $failureRateSnapshot, ')
          ..write('minimumChargeSnapshot: $minimumChargeSnapshot, ')
          ..write('markupOnMaterialsSnapshot: $markupOnMaterialsSnapshot')
          ..write(')'))
        .toString();
  }
}

class $CalculationMaterialsTable extends CalculationMaterials
    with TableInfo<$CalculationMaterialsTable, CalculationMaterial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalculationMaterialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _calculationIdMeta = const VerificationMeta(
    'calculationId',
  );
  @override
  late final GeneratedColumn<int> calculationId = GeneratedColumn<int>(
    'calculation_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES calculations (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filamentIdMeta = const VerificationMeta(
    'filamentId',
  );
  @override
  late final GeneratedColumn<int> filamentId = GeneratedColumn<int>(
    'filament_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightGramsMeta = const VerificationMeta(
    'weightGrams',
  );
  @override
  late final GeneratedColumn<double> weightGrams = GeneratedColumn<double>(
    'weight_grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pricePerBobbinSnapshotMeta =
      const VerificationMeta('pricePerBobbinSnapshot');
  @override
  late final GeneratedColumn<double> pricePerBobbinSnapshot =
      GeneratedColumn<double>(
        'price_per_bobbin_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gramsPerBobbinSnapshotMeta =
      const VerificationMeta('gramsPerBobbinSnapshot');
  @override
  late final GeneratedColumn<double> gramsPerBobbinSnapshot =
      GeneratedColumn<double>(
        'grams_per_bobbin_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    calculationId,
    filamentId,
    label,
    weightGrams,
    pricePerBobbinSnapshot,
    gramsPerBobbinSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calculation_materials';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalculationMaterial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('calculation_id')) {
      context.handle(
        _calculationIdMeta,
        calculationId.isAcceptableOrUnknown(
          data['calculation_id']!,
          _calculationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculationIdMeta);
    }
    if (data.containsKey('filament_id')) {
      context.handle(
        _filamentIdMeta,
        filamentId.isAcceptableOrUnknown(data['filament_id']!, _filamentIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('weight_grams')) {
      context.handle(
        _weightGramsMeta,
        weightGrams.isAcceptableOrUnknown(
          data['weight_grams']!,
          _weightGramsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightGramsMeta);
    }
    if (data.containsKey('price_per_bobbin_snapshot')) {
      context.handle(
        _pricePerBobbinSnapshotMeta,
        pricePerBobbinSnapshot.isAcceptableOrUnknown(
          data['price_per_bobbin_snapshot']!,
          _pricePerBobbinSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerBobbinSnapshotMeta);
    }
    if (data.containsKey('grams_per_bobbin_snapshot')) {
      context.handle(
        _gramsPerBobbinSnapshotMeta,
        gramsPerBobbinSnapshot.isAcceptableOrUnknown(
          data['grams_per_bobbin_snapshot']!,
          _gramsPerBobbinSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gramsPerBobbinSnapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalculationMaterial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalculationMaterial(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      calculationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculation_id'],
      )!,
      filamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}filament_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      weightGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_grams'],
      )!,
      pricePerBobbinSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_bobbin_snapshot'],
      )!,
      gramsPerBobbinSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams_per_bobbin_snapshot'],
      )!,
    );
  }

  @override
  $CalculationMaterialsTable createAlias(String alias) {
    return $CalculationMaterialsTable(attachedDatabase, alias);
  }
}

class CalculationMaterial extends DataClass
    implements Insertable<CalculationMaterial> {
  final int id;
  final int calculationId;

  /// Soft FK a `filaments.id`. Nullable.
  final int? filamentId;

  /// Etiqueta visible. Ej: "PLA Negro", "Generico".
  final String label;

  /// Peso del material en la pieza (gramos).
  final double weightGrams;

  /// Snapshot del precio por bobina al guardar.
  final double pricePerBobbinSnapshot;

  /// Snapshot de gramos por bobina al guardar.
  final double gramsPerBobbinSnapshot;
  const CalculationMaterial({
    required this.id,
    required this.calculationId,
    this.filamentId,
    required this.label,
    required this.weightGrams,
    required this.pricePerBobbinSnapshot,
    required this.gramsPerBobbinSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['calculation_id'] = Variable<int>(calculationId);
    if (!nullToAbsent || filamentId != null) {
      map['filament_id'] = Variable<int>(filamentId);
    }
    map['label'] = Variable<String>(label);
    map['weight_grams'] = Variable<double>(weightGrams);
    map['price_per_bobbin_snapshot'] = Variable<double>(pricePerBobbinSnapshot);
    map['grams_per_bobbin_snapshot'] = Variable<double>(gramsPerBobbinSnapshot);
    return map;
  }

  CalculationMaterialsCompanion toCompanion(bool nullToAbsent) {
    return CalculationMaterialsCompanion(
      id: Value(id),
      calculationId: Value(calculationId),
      filamentId: filamentId == null && nullToAbsent
          ? const Value.absent()
          : Value(filamentId),
      label: Value(label),
      weightGrams: Value(weightGrams),
      pricePerBobbinSnapshot: Value(pricePerBobbinSnapshot),
      gramsPerBobbinSnapshot: Value(gramsPerBobbinSnapshot),
    );
  }

  factory CalculationMaterial.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalculationMaterial(
      id: serializer.fromJson<int>(json['id']),
      calculationId: serializer.fromJson<int>(json['calculationId']),
      filamentId: serializer.fromJson<int?>(json['filamentId']),
      label: serializer.fromJson<String>(json['label']),
      weightGrams: serializer.fromJson<double>(json['weightGrams']),
      pricePerBobbinSnapshot: serializer.fromJson<double>(
        json['pricePerBobbinSnapshot'],
      ),
      gramsPerBobbinSnapshot: serializer.fromJson<double>(
        json['gramsPerBobbinSnapshot'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'calculationId': serializer.toJson<int>(calculationId),
      'filamentId': serializer.toJson<int?>(filamentId),
      'label': serializer.toJson<String>(label),
      'weightGrams': serializer.toJson<double>(weightGrams),
      'pricePerBobbinSnapshot': serializer.toJson<double>(
        pricePerBobbinSnapshot,
      ),
      'gramsPerBobbinSnapshot': serializer.toJson<double>(
        gramsPerBobbinSnapshot,
      ),
    };
  }

  CalculationMaterial copyWith({
    int? id,
    int? calculationId,
    Value<int?> filamentId = const Value.absent(),
    String? label,
    double? weightGrams,
    double? pricePerBobbinSnapshot,
    double? gramsPerBobbinSnapshot,
  }) => CalculationMaterial(
    id: id ?? this.id,
    calculationId: calculationId ?? this.calculationId,
    filamentId: filamentId.present ? filamentId.value : this.filamentId,
    label: label ?? this.label,
    weightGrams: weightGrams ?? this.weightGrams,
    pricePerBobbinSnapshot:
        pricePerBobbinSnapshot ?? this.pricePerBobbinSnapshot,
    gramsPerBobbinSnapshot:
        gramsPerBobbinSnapshot ?? this.gramsPerBobbinSnapshot,
  );
  CalculationMaterial copyWithCompanion(CalculationMaterialsCompanion data) {
    return CalculationMaterial(
      id: data.id.present ? data.id.value : this.id,
      calculationId: data.calculationId.present
          ? data.calculationId.value
          : this.calculationId,
      filamentId: data.filamentId.present
          ? data.filamentId.value
          : this.filamentId,
      label: data.label.present ? data.label.value : this.label,
      weightGrams: data.weightGrams.present
          ? data.weightGrams.value
          : this.weightGrams,
      pricePerBobbinSnapshot: data.pricePerBobbinSnapshot.present
          ? data.pricePerBobbinSnapshot.value
          : this.pricePerBobbinSnapshot,
      gramsPerBobbinSnapshot: data.gramsPerBobbinSnapshot.present
          ? data.gramsPerBobbinSnapshot.value
          : this.gramsPerBobbinSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalculationMaterial(')
          ..write('id: $id, ')
          ..write('calculationId: $calculationId, ')
          ..write('filamentId: $filamentId, ')
          ..write('label: $label, ')
          ..write('weightGrams: $weightGrams, ')
          ..write('pricePerBobbinSnapshot: $pricePerBobbinSnapshot, ')
          ..write('gramsPerBobbinSnapshot: $gramsPerBobbinSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    calculationId,
    filamentId,
    label,
    weightGrams,
    pricePerBobbinSnapshot,
    gramsPerBobbinSnapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalculationMaterial &&
          other.id == this.id &&
          other.calculationId == this.calculationId &&
          other.filamentId == this.filamentId &&
          other.label == this.label &&
          other.weightGrams == this.weightGrams &&
          other.pricePerBobbinSnapshot == this.pricePerBobbinSnapshot &&
          other.gramsPerBobbinSnapshot == this.gramsPerBobbinSnapshot);
}

class CalculationMaterialsCompanion
    extends UpdateCompanion<CalculationMaterial> {
  final Value<int> id;
  final Value<int> calculationId;
  final Value<int?> filamentId;
  final Value<String> label;
  final Value<double> weightGrams;
  final Value<double> pricePerBobbinSnapshot;
  final Value<double> gramsPerBobbinSnapshot;
  const CalculationMaterialsCompanion({
    this.id = const Value.absent(),
    this.calculationId = const Value.absent(),
    this.filamentId = const Value.absent(),
    this.label = const Value.absent(),
    this.weightGrams = const Value.absent(),
    this.pricePerBobbinSnapshot = const Value.absent(),
    this.gramsPerBobbinSnapshot = const Value.absent(),
  });
  CalculationMaterialsCompanion.insert({
    this.id = const Value.absent(),
    required int calculationId,
    this.filamentId = const Value.absent(),
    required String label,
    required double weightGrams,
    required double pricePerBobbinSnapshot,
    required double gramsPerBobbinSnapshot,
  }) : calculationId = Value(calculationId),
       label = Value(label),
       weightGrams = Value(weightGrams),
       pricePerBobbinSnapshot = Value(pricePerBobbinSnapshot),
       gramsPerBobbinSnapshot = Value(gramsPerBobbinSnapshot);
  static Insertable<CalculationMaterial> custom({
    Expression<int>? id,
    Expression<int>? calculationId,
    Expression<int>? filamentId,
    Expression<String>? label,
    Expression<double>? weightGrams,
    Expression<double>? pricePerBobbinSnapshot,
    Expression<double>? gramsPerBobbinSnapshot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calculationId != null) 'calculation_id': calculationId,
      if (filamentId != null) 'filament_id': filamentId,
      if (label != null) 'label': label,
      if (weightGrams != null) 'weight_grams': weightGrams,
      if (pricePerBobbinSnapshot != null)
        'price_per_bobbin_snapshot': pricePerBobbinSnapshot,
      if (gramsPerBobbinSnapshot != null)
        'grams_per_bobbin_snapshot': gramsPerBobbinSnapshot,
    });
  }

  CalculationMaterialsCompanion copyWith({
    Value<int>? id,
    Value<int>? calculationId,
    Value<int?>? filamentId,
    Value<String>? label,
    Value<double>? weightGrams,
    Value<double>? pricePerBobbinSnapshot,
    Value<double>? gramsPerBobbinSnapshot,
  }) {
    return CalculationMaterialsCompanion(
      id: id ?? this.id,
      calculationId: calculationId ?? this.calculationId,
      filamentId: filamentId ?? this.filamentId,
      label: label ?? this.label,
      weightGrams: weightGrams ?? this.weightGrams,
      pricePerBobbinSnapshot:
          pricePerBobbinSnapshot ?? this.pricePerBobbinSnapshot,
      gramsPerBobbinSnapshot:
          gramsPerBobbinSnapshot ?? this.gramsPerBobbinSnapshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (calculationId.present) {
      map['calculation_id'] = Variable<int>(calculationId.value);
    }
    if (filamentId.present) {
      map['filament_id'] = Variable<int>(filamentId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (weightGrams.present) {
      map['weight_grams'] = Variable<double>(weightGrams.value);
    }
    if (pricePerBobbinSnapshot.present) {
      map['price_per_bobbin_snapshot'] = Variable<double>(
        pricePerBobbinSnapshot.value,
      );
    }
    if (gramsPerBobbinSnapshot.present) {
      map['grams_per_bobbin_snapshot'] = Variable<double>(
        gramsPerBobbinSnapshot.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalculationMaterialsCompanion(')
          ..write('id: $id, ')
          ..write('calculationId: $calculationId, ')
          ..write('filamentId: $filamentId, ')
          ..write('label: $label, ')
          ..write('weightGrams: $weightGrams, ')
          ..write('pricePerBobbinSnapshot: $pricePerBobbinSnapshot, ')
          ..write('gramsPerBobbinSnapshot: $gramsPerBobbinSnapshot')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  /// Clave unica del setting (ej: "profit_base_percentage").
  final String key;

  /// Valor del setting como string. Conversion a tipo especifico en repository.
  final String value;

  /// Ultima actualizacion. UTC.
  final DateTime updatedAt;
  const Setting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      Setting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsTableCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsTableCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return (StringBuffer('SettingsTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PrintersTable printers = $PrintersTable(this);
  late final $FilamentsTable filaments = $FilamentsTable(this);
  late final $CalculationsTable calculations = $CalculationsTable(this);
  late final $CalculationMaterialsTable calculationMaterials =
      $CalculationMaterialsTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    printers,
    filaments,
    calculations,
    calculationMaterials,
    settingsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'calculations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calculation_materials', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PrintersTableCreateCompanionBuilder =
    PrintersCompanion Function({
      Value<int> id,
      Value<String?> brand,
      required String name,
      required int averageWatts,
      Value<bool> isDefault,
      required DateTime createdAt,
    });
typedef $$PrintersTableUpdateCompanionBuilder =
    PrintersCompanion Function({
      Value<int> id,
      Value<String?> brand,
      Value<String> name,
      Value<int> averageWatts,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
    });

class $$PrintersTableFilterComposer
    extends Composer<_$AppDatabase, $PrintersTable> {
  $$PrintersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get averageWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrintersTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintersTable> {
  $$PrintersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get averageWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrintersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintersTable> {
  $$PrintersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get averageWatts => $composableBuilder(
    column: $table.averageWatts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PrintersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintersTable,
          PrinterProfile,
          $$PrintersTableFilterComposer,
          $$PrintersTableOrderingComposer,
          $$PrintersTableAnnotationComposer,
          $$PrintersTableCreateCompanionBuilder,
          $$PrintersTableUpdateCompanionBuilder,
          (
            PrinterProfile,
            BaseReferences<_$AppDatabase, $PrintersTable, PrinterProfile>,
          ),
          PrinterProfile,
          PrefetchHooks Function()
        > {
  $$PrintersTableTableManager(_$AppDatabase db, $PrintersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> averageWatts = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PrintersCompanion(
                id: id,
                brand: brand,
                name: name,
                averageWatts: averageWatts,
                isDefault: isDefault,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                required String name,
                required int averageWatts,
                Value<bool> isDefault = const Value.absent(),
                required DateTime createdAt,
              }) => PrintersCompanion.insert(
                id: id,
                brand: brand,
                name: name,
                averageWatts: averageWatts,
                isDefault: isDefault,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrintersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintersTable,
      PrinterProfile,
      $$PrintersTableFilterComposer,
      $$PrintersTableOrderingComposer,
      $$PrintersTableAnnotationComposer,
      $$PrintersTableCreateCompanionBuilder,
      $$PrintersTableUpdateCompanionBuilder,
      (
        PrinterProfile,
        BaseReferences<_$AppDatabase, $PrintersTable, PrinterProfile>,
      ),
      PrinterProfile,
      PrefetchHooks Function()
    >;
typedef $$FilamentsTableCreateCompanionBuilder =
    FilamentsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> brand,
      required double pricePerBobbin,
      required double gramsPerBobbin,
      Value<bool> isDefault,
      required DateTime createdAt,
    });
typedef $$FilamentsTableUpdateCompanionBuilder =
    FilamentsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> brand,
      Value<double> pricePerBobbin,
      Value<double> gramsPerBobbin,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
    });

class $$FilamentsTableFilterComposer
    extends Composer<_$AppDatabase, $FilamentsTable> {
  $$FilamentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerBobbin => $composableBuilder(
    column: $table.pricePerBobbin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramsPerBobbin => $composableBuilder(
    column: $table.gramsPerBobbin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FilamentsTableOrderingComposer
    extends Composer<_$AppDatabase, $FilamentsTable> {
  $$FilamentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerBobbin => $composableBuilder(
    column: $table.pricePerBobbin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramsPerBobbin => $composableBuilder(
    column: $table.gramsPerBobbin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilamentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilamentsTable> {
  $$FilamentsTableAnnotationComposer({
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

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get pricePerBobbin => $composableBuilder(
    column: $table.pricePerBobbin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gramsPerBobbin => $composableBuilder(
    column: $table.gramsPerBobbin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FilamentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilamentsTable,
          Filament,
          $$FilamentsTableFilterComposer,
          $$FilamentsTableOrderingComposer,
          $$FilamentsTableAnnotationComposer,
          $$FilamentsTableCreateCompanionBuilder,
          $$FilamentsTableUpdateCompanionBuilder,
          (Filament, BaseReferences<_$AppDatabase, $FilamentsTable, Filament>),
          Filament,
          PrefetchHooks Function()
        > {
  $$FilamentsTableTableManager(_$AppDatabase db, $FilamentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilamentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilamentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilamentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double> pricePerBobbin = const Value.absent(),
                Value<double> gramsPerBobbin = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FilamentsCompanion(
                id: id,
                name: name,
                brand: brand,
                pricePerBobbin: pricePerBobbin,
                gramsPerBobbin: gramsPerBobbin,
                isDefault: isDefault,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                required double pricePerBobbin,
                required double gramsPerBobbin,
                Value<bool> isDefault = const Value.absent(),
                required DateTime createdAt,
              }) => FilamentsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                pricePerBobbin: pricePerBobbin,
                gramsPerBobbin: gramsPerBobbin,
                isDefault: isDefault,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FilamentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilamentsTable,
      Filament,
      $$FilamentsTableFilterComposer,
      $$FilamentsTableOrderingComposer,
      $$FilamentsTableAnnotationComposer,
      $$FilamentsTableCreateCompanionBuilder,
      $$FilamentsTableUpdateCompanionBuilder,
      (Filament, BaseReferences<_$AppDatabase, $FilamentsTable, Filament>),
      Filament,
      PrefetchHooks Function()
    >;
typedef $$CalculationsTableCreateCompanionBuilder =
    CalculationsCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      Value<String?> pieceName,
      Value<String?> clientName,
      Value<int?> printerId,
      Value<String?> printerNameSnapshot,
      Value<double> printerWattsSnapshot,
      required double totalHours,
      required double discountPercentage,
      required double kwhRateSnapshot,
      required double profitBaseSnapshot,
      Value<bool> isSold,
      required double materialCostSnapshot,
      required double electricCostSnapshot,
      required double laborCostSnapshot,
      required double postProcessCostSnapshot,
      required double baseCostSnapshot,
      required double failureCostSnapshot,
      required double markupCostSnapshot,
      required double profitAmountSnapshot,
      required double minimumChargeAppliedSnapshot,
      required double effectiveTotalSnapshot,
      required double totalPriceSnapshot,
      required double laborRateSnapshot,
      required double postProcessRateSnapshot,
      required double failureRateSnapshot,
      required double minimumChargeSnapshot,
      required double markupOnMaterialsSnapshot,
    });
typedef $$CalculationsTableUpdateCompanionBuilder =
    CalculationsCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<String?> pieceName,
      Value<String?> clientName,
      Value<int?> printerId,
      Value<String?> printerNameSnapshot,
      Value<double> printerWattsSnapshot,
      Value<double> totalHours,
      Value<double> discountPercentage,
      Value<double> kwhRateSnapshot,
      Value<double> profitBaseSnapshot,
      Value<bool> isSold,
      Value<double> materialCostSnapshot,
      Value<double> electricCostSnapshot,
      Value<double> laborCostSnapshot,
      Value<double> postProcessCostSnapshot,
      Value<double> baseCostSnapshot,
      Value<double> failureCostSnapshot,
      Value<double> markupCostSnapshot,
      Value<double> profitAmountSnapshot,
      Value<double> minimumChargeAppliedSnapshot,
      Value<double> effectiveTotalSnapshot,
      Value<double> totalPriceSnapshot,
      Value<double> laborRateSnapshot,
      Value<double> postProcessRateSnapshot,
      Value<double> failureRateSnapshot,
      Value<double> minimumChargeSnapshot,
      Value<double> markupOnMaterialsSnapshot,
    });

final class $$CalculationsTableReferences
    extends BaseReferences<_$AppDatabase, $CalculationsTable, Calculation> {
  $$CalculationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CalculationMaterialsTable,
    List<CalculationMaterial>
  >
  _calculationMaterialsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.calculationMaterials,
        aliasName: $_aliasNameGenerator(
          db.calculations.id,
          db.calculationMaterials.calculationId,
        ),
      );

  $$CalculationMaterialsTableProcessedTableManager
  get calculationMaterialsRefs {
    final manager = $$CalculationMaterialsTableTableManager(
      $_db,
      $_db.calculationMaterials,
    ).filter((f) => f.calculationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _calculationMaterialsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CalculationsTableFilterComposer
    extends Composer<_$AppDatabase, $CalculationsTable> {
  $$CalculationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pieceName => $composableBuilder(
    column: $table.pieceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get printerId => $composableBuilder(
    column: $table.printerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printerNameSnapshot => $composableBuilder(
    column: $table.printerNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get printerWattsSnapshot => $composableBuilder(
    column: $table.printerWattsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalHours => $composableBuilder(
    column: $table.totalHours,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountPercentage => $composableBuilder(
    column: $table.discountPercentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kwhRateSnapshot => $composableBuilder(
    column: $table.kwhRateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitBaseSnapshot => $composableBuilder(
    column: $table.profitBaseSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSold => $composableBuilder(
    column: $table.isSold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get materialCostSnapshot => $composableBuilder(
    column: $table.materialCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get electricCostSnapshot => $composableBuilder(
    column: $table.electricCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get laborCostSnapshot => $composableBuilder(
    column: $table.laborCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get postProcessCostSnapshot => $composableBuilder(
    column: $table.postProcessCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseCostSnapshot => $composableBuilder(
    column: $table.baseCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get failureCostSnapshot => $composableBuilder(
    column: $table.failureCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get markupCostSnapshot => $composableBuilder(
    column: $table.markupCostSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitAmountSnapshot => $composableBuilder(
    column: $table.profitAmountSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumChargeAppliedSnapshot => $composableBuilder(
    column: $table.minimumChargeAppliedSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effectiveTotalSnapshot => $composableBuilder(
    column: $table.effectiveTotalSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPriceSnapshot => $composableBuilder(
    column: $table.totalPriceSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get laborRateSnapshot => $composableBuilder(
    column: $table.laborRateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get postProcessRateSnapshot => $composableBuilder(
    column: $table.postProcessRateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get failureRateSnapshot => $composableBuilder(
    column: $table.failureRateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumChargeSnapshot => $composableBuilder(
    column: $table.minimumChargeSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get markupOnMaterialsSnapshot => $composableBuilder(
    column: $table.markupOnMaterialsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> calculationMaterialsRefs(
    Expression<bool> Function($$CalculationMaterialsTableFilterComposer f) f,
  ) {
    final $$CalculationMaterialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calculationMaterials,
      getReferencedColumn: (t) => t.calculationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalculationMaterialsTableFilterComposer(
            $db: $db,
            $table: $db.calculationMaterials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CalculationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalculationsTable> {
  $$CalculationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pieceName => $composableBuilder(
    column: $table.pieceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get printerId => $composableBuilder(
    column: $table.printerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printerNameSnapshot => $composableBuilder(
    column: $table.printerNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get printerWattsSnapshot => $composableBuilder(
    column: $table.printerWattsSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalHours => $composableBuilder(
    column: $table.totalHours,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountPercentage => $composableBuilder(
    column: $table.discountPercentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kwhRateSnapshot => $composableBuilder(
    column: $table.kwhRateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitBaseSnapshot => $composableBuilder(
    column: $table.profitBaseSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSold => $composableBuilder(
    column: $table.isSold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get materialCostSnapshot => $composableBuilder(
    column: $table.materialCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get electricCostSnapshot => $composableBuilder(
    column: $table.electricCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get laborCostSnapshot => $composableBuilder(
    column: $table.laborCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get postProcessCostSnapshot => $composableBuilder(
    column: $table.postProcessCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseCostSnapshot => $composableBuilder(
    column: $table.baseCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get failureCostSnapshot => $composableBuilder(
    column: $table.failureCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get markupCostSnapshot => $composableBuilder(
    column: $table.markupCostSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitAmountSnapshot => $composableBuilder(
    column: $table.profitAmountSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumChargeAppliedSnapshot =>
      $composableBuilder(
        column: $table.minimumChargeAppliedSnapshot,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<double> get effectiveTotalSnapshot => $composableBuilder(
    column: $table.effectiveTotalSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPriceSnapshot => $composableBuilder(
    column: $table.totalPriceSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get laborRateSnapshot => $composableBuilder(
    column: $table.laborRateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get postProcessRateSnapshot => $composableBuilder(
    column: $table.postProcessRateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get failureRateSnapshot => $composableBuilder(
    column: $table.failureRateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumChargeSnapshot => $composableBuilder(
    column: $table.minimumChargeSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get markupOnMaterialsSnapshot => $composableBuilder(
    column: $table.markupOnMaterialsSnapshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CalculationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalculationsTable> {
  $$CalculationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get pieceName =>
      $composableBuilder(column: $table.pieceName, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
    column: $table.clientName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get printerId =>
      $composableBuilder(column: $table.printerId, builder: (column) => column);

  GeneratedColumn<String> get printerNameSnapshot => $composableBuilder(
    column: $table.printerNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get printerWattsSnapshot => $composableBuilder(
    column: $table.printerWattsSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalHours => $composableBuilder(
    column: $table.totalHours,
    builder: (column) => column,
  );

  GeneratedColumn<double> get discountPercentage => $composableBuilder(
    column: $table.discountPercentage,
    builder: (column) => column,
  );

  GeneratedColumn<double> get kwhRateSnapshot => $composableBuilder(
    column: $table.kwhRateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitBaseSnapshot => $composableBuilder(
    column: $table.profitBaseSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSold =>
      $composableBuilder(column: $table.isSold, builder: (column) => column);

  GeneratedColumn<double> get materialCostSnapshot => $composableBuilder(
    column: $table.materialCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get electricCostSnapshot => $composableBuilder(
    column: $table.electricCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get laborCostSnapshot => $composableBuilder(
    column: $table.laborCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get postProcessCostSnapshot => $composableBuilder(
    column: $table.postProcessCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseCostSnapshot => $composableBuilder(
    column: $table.baseCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get failureCostSnapshot => $composableBuilder(
    column: $table.failureCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get markupCostSnapshot => $composableBuilder(
    column: $table.markupCostSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitAmountSnapshot => $composableBuilder(
    column: $table.profitAmountSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumChargeAppliedSnapshot =>
      $composableBuilder(
        column: $table.minimumChargeAppliedSnapshot,
        builder: (column) => column,
      );

  GeneratedColumn<double> get effectiveTotalSnapshot => $composableBuilder(
    column: $table.effectiveTotalSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPriceSnapshot => $composableBuilder(
    column: $table.totalPriceSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get laborRateSnapshot => $composableBuilder(
    column: $table.laborRateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get postProcessRateSnapshot => $composableBuilder(
    column: $table.postProcessRateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get failureRateSnapshot => $composableBuilder(
    column: $table.failureRateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumChargeSnapshot => $composableBuilder(
    column: $table.minimumChargeSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get markupOnMaterialsSnapshot => $composableBuilder(
    column: $table.markupOnMaterialsSnapshot,
    builder: (column) => column,
  );

  Expression<T> calculationMaterialsRefs<T extends Object>(
    Expression<T> Function($$CalculationMaterialsTableAnnotationComposer a) f,
  ) {
    final $$CalculationMaterialsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.calculationMaterials,
          getReferencedColumn: (t) => t.calculationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalculationMaterialsTableAnnotationComposer(
                $db: $db,
                $table: $db.calculationMaterials,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CalculationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalculationsTable,
          Calculation,
          $$CalculationsTableFilterComposer,
          $$CalculationsTableOrderingComposer,
          $$CalculationsTableAnnotationComposer,
          $$CalculationsTableCreateCompanionBuilder,
          $$CalculationsTableUpdateCompanionBuilder,
          (Calculation, $$CalculationsTableReferences),
          Calculation,
          PrefetchHooks Function({bool calculationMaterialsRefs})
        > {
  $$CalculationsTableTableManager(_$AppDatabase db, $CalculationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalculationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalculationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalculationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> pieceName = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<int?> printerId = const Value.absent(),
                Value<String?> printerNameSnapshot = const Value.absent(),
                Value<double> printerWattsSnapshot = const Value.absent(),
                Value<double> totalHours = const Value.absent(),
                Value<double> discountPercentage = const Value.absent(),
                Value<double> kwhRateSnapshot = const Value.absent(),
                Value<double> profitBaseSnapshot = const Value.absent(),
                Value<bool> isSold = const Value.absent(),
                Value<double> materialCostSnapshot = const Value.absent(),
                Value<double> electricCostSnapshot = const Value.absent(),
                Value<double> laborCostSnapshot = const Value.absent(),
                Value<double> postProcessCostSnapshot = const Value.absent(),
                Value<double> baseCostSnapshot = const Value.absent(),
                Value<double> failureCostSnapshot = const Value.absent(),
                Value<double> markupCostSnapshot = const Value.absent(),
                Value<double> profitAmountSnapshot = const Value.absent(),
                Value<double> minimumChargeAppliedSnapshot =
                    const Value.absent(),
                Value<double> effectiveTotalSnapshot = const Value.absent(),
                Value<double> totalPriceSnapshot = const Value.absent(),
                Value<double> laborRateSnapshot = const Value.absent(),
                Value<double> postProcessRateSnapshot = const Value.absent(),
                Value<double> failureRateSnapshot = const Value.absent(),
                Value<double> minimumChargeSnapshot = const Value.absent(),
                Value<double> markupOnMaterialsSnapshot = const Value.absent(),
              }) => CalculationsCompanion(
                id: id,
                createdAt: createdAt,
                pieceName: pieceName,
                clientName: clientName,
                printerId: printerId,
                printerNameSnapshot: printerNameSnapshot,
                printerWattsSnapshot: printerWattsSnapshot,
                totalHours: totalHours,
                discountPercentage: discountPercentage,
                kwhRateSnapshot: kwhRateSnapshot,
                profitBaseSnapshot: profitBaseSnapshot,
                isSold: isSold,
                materialCostSnapshot: materialCostSnapshot,
                electricCostSnapshot: electricCostSnapshot,
                laborCostSnapshot: laborCostSnapshot,
                postProcessCostSnapshot: postProcessCostSnapshot,
                baseCostSnapshot: baseCostSnapshot,
                failureCostSnapshot: failureCostSnapshot,
                markupCostSnapshot: markupCostSnapshot,
                profitAmountSnapshot: profitAmountSnapshot,
                minimumChargeAppliedSnapshot: minimumChargeAppliedSnapshot,
                effectiveTotalSnapshot: effectiveTotalSnapshot,
                totalPriceSnapshot: totalPriceSnapshot,
                laborRateSnapshot: laborRateSnapshot,
                postProcessRateSnapshot: postProcessRateSnapshot,
                failureRateSnapshot: failureRateSnapshot,
                minimumChargeSnapshot: minimumChargeSnapshot,
                markupOnMaterialsSnapshot: markupOnMaterialsSnapshot,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                Value<String?> pieceName = const Value.absent(),
                Value<String?> clientName = const Value.absent(),
                Value<int?> printerId = const Value.absent(),
                Value<String?> printerNameSnapshot = const Value.absent(),
                Value<double> printerWattsSnapshot = const Value.absent(),
                required double totalHours,
                required double discountPercentage,
                required double kwhRateSnapshot,
                required double profitBaseSnapshot,
                Value<bool> isSold = const Value.absent(),
                required double materialCostSnapshot,
                required double electricCostSnapshot,
                required double laborCostSnapshot,
                required double postProcessCostSnapshot,
                required double baseCostSnapshot,
                required double failureCostSnapshot,
                required double markupCostSnapshot,
                required double profitAmountSnapshot,
                required double minimumChargeAppliedSnapshot,
                required double effectiveTotalSnapshot,
                required double totalPriceSnapshot,
                required double laborRateSnapshot,
                required double postProcessRateSnapshot,
                required double failureRateSnapshot,
                required double minimumChargeSnapshot,
                required double markupOnMaterialsSnapshot,
              }) => CalculationsCompanion.insert(
                id: id,
                createdAt: createdAt,
                pieceName: pieceName,
                clientName: clientName,
                printerId: printerId,
                printerNameSnapshot: printerNameSnapshot,
                printerWattsSnapshot: printerWattsSnapshot,
                totalHours: totalHours,
                discountPercentage: discountPercentage,
                kwhRateSnapshot: kwhRateSnapshot,
                profitBaseSnapshot: profitBaseSnapshot,
                isSold: isSold,
                materialCostSnapshot: materialCostSnapshot,
                electricCostSnapshot: electricCostSnapshot,
                laborCostSnapshot: laborCostSnapshot,
                postProcessCostSnapshot: postProcessCostSnapshot,
                baseCostSnapshot: baseCostSnapshot,
                failureCostSnapshot: failureCostSnapshot,
                markupCostSnapshot: markupCostSnapshot,
                profitAmountSnapshot: profitAmountSnapshot,
                minimumChargeAppliedSnapshot: minimumChargeAppliedSnapshot,
                effectiveTotalSnapshot: effectiveTotalSnapshot,
                totalPriceSnapshot: totalPriceSnapshot,
                laborRateSnapshot: laborRateSnapshot,
                postProcessRateSnapshot: postProcessRateSnapshot,
                failureRateSnapshot: failureRateSnapshot,
                minimumChargeSnapshot: minimumChargeSnapshot,
                markupOnMaterialsSnapshot: markupOnMaterialsSnapshot,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CalculationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calculationMaterialsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (calculationMaterialsRefs) db.calculationMaterials,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (calculationMaterialsRefs)
                    await $_getPrefetchedData<
                      Calculation,
                      $CalculationsTable,
                      CalculationMaterial
                    >(
                      currentTable: table,
                      referencedTable: $$CalculationsTableReferences
                          ._calculationMaterialsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CalculationsTableReferences(
                            db,
                            table,
                            p0,
                          ).calculationMaterialsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.calculationId == item.id,
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

typedef $$CalculationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalculationsTable,
      Calculation,
      $$CalculationsTableFilterComposer,
      $$CalculationsTableOrderingComposer,
      $$CalculationsTableAnnotationComposer,
      $$CalculationsTableCreateCompanionBuilder,
      $$CalculationsTableUpdateCompanionBuilder,
      (Calculation, $$CalculationsTableReferences),
      Calculation,
      PrefetchHooks Function({bool calculationMaterialsRefs})
    >;
typedef $$CalculationMaterialsTableCreateCompanionBuilder =
    CalculationMaterialsCompanion Function({
      Value<int> id,
      required int calculationId,
      Value<int?> filamentId,
      required String label,
      required double weightGrams,
      required double pricePerBobbinSnapshot,
      required double gramsPerBobbinSnapshot,
    });
typedef $$CalculationMaterialsTableUpdateCompanionBuilder =
    CalculationMaterialsCompanion Function({
      Value<int> id,
      Value<int> calculationId,
      Value<int?> filamentId,
      Value<String> label,
      Value<double> weightGrams,
      Value<double> pricePerBobbinSnapshot,
      Value<double> gramsPerBobbinSnapshot,
    });

final class $$CalculationMaterialsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CalculationMaterialsTable,
          CalculationMaterial
        > {
  $$CalculationMaterialsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CalculationsTable _calculationIdTable(_$AppDatabase db) =>
      db.calculations.createAlias(
        $_aliasNameGenerator(
          db.calculationMaterials.calculationId,
          db.calculations.id,
        ),
      );

  $$CalculationsTableProcessedTableManager get calculationId {
    final $_column = $_itemColumn<int>('calculation_id')!;

    final manager = $$CalculationsTableTableManager(
      $_db,
      $_db.calculations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calculationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalculationMaterialsTableFilterComposer
    extends Composer<_$AppDatabase, $CalculationMaterialsTable> {
  $$CalculationMaterialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get filamentId => $composableBuilder(
    column: $table.filamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerBobbinSnapshot => $composableBuilder(
    column: $table.pricePerBobbinSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramsPerBobbinSnapshot => $composableBuilder(
    column: $table.gramsPerBobbinSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  $$CalculationsTableFilterComposer get calculationId {
    final $$CalculationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calculationId,
      referencedTable: $db.calculations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalculationsTableFilterComposer(
            $db: $db,
            $table: $db.calculations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalculationMaterialsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalculationMaterialsTable> {
  $$CalculationMaterialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get filamentId => $composableBuilder(
    column: $table.filamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerBobbinSnapshot => $composableBuilder(
    column: $table.pricePerBobbinSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramsPerBobbinSnapshot => $composableBuilder(
    column: $table.gramsPerBobbinSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  $$CalculationsTableOrderingComposer get calculationId {
    final $$CalculationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calculationId,
      referencedTable: $db.calculations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalculationsTableOrderingComposer(
            $db: $db,
            $table: $db.calculations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalculationMaterialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalculationMaterialsTable> {
  $$CalculationMaterialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get filamentId => $composableBuilder(
    column: $table.filamentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pricePerBobbinSnapshot => $composableBuilder(
    column: $table.pricePerBobbinSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gramsPerBobbinSnapshot => $composableBuilder(
    column: $table.gramsPerBobbinSnapshot,
    builder: (column) => column,
  );

  $$CalculationsTableAnnotationComposer get calculationId {
    final $$CalculationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calculationId,
      referencedTable: $db.calculations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalculationsTableAnnotationComposer(
            $db: $db,
            $table: $db.calculations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalculationMaterialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalculationMaterialsTable,
          CalculationMaterial,
          $$CalculationMaterialsTableFilterComposer,
          $$CalculationMaterialsTableOrderingComposer,
          $$CalculationMaterialsTableAnnotationComposer,
          $$CalculationMaterialsTableCreateCompanionBuilder,
          $$CalculationMaterialsTableUpdateCompanionBuilder,
          (CalculationMaterial, $$CalculationMaterialsTableReferences),
          CalculationMaterial,
          PrefetchHooks Function({bool calculationId})
        > {
  $$CalculationMaterialsTableTableManager(
    _$AppDatabase db,
    $CalculationMaterialsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalculationMaterialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalculationMaterialsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CalculationMaterialsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> calculationId = const Value.absent(),
                Value<int?> filamentId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> weightGrams = const Value.absent(),
                Value<double> pricePerBobbinSnapshot = const Value.absent(),
                Value<double> gramsPerBobbinSnapshot = const Value.absent(),
              }) => CalculationMaterialsCompanion(
                id: id,
                calculationId: calculationId,
                filamentId: filamentId,
                label: label,
                weightGrams: weightGrams,
                pricePerBobbinSnapshot: pricePerBobbinSnapshot,
                gramsPerBobbinSnapshot: gramsPerBobbinSnapshot,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int calculationId,
                Value<int?> filamentId = const Value.absent(),
                required String label,
                required double weightGrams,
                required double pricePerBobbinSnapshot,
                required double gramsPerBobbinSnapshot,
              }) => CalculationMaterialsCompanion.insert(
                id: id,
                calculationId: calculationId,
                filamentId: filamentId,
                label: label,
                weightGrams: weightGrams,
                pricePerBobbinSnapshot: pricePerBobbinSnapshot,
                gramsPerBobbinSnapshot: gramsPerBobbinSnapshot,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CalculationMaterialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({calculationId = false}) {
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
                    if (calculationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.calculationId,
                                referencedTable:
                                    $$CalculationMaterialsTableReferences
                                        ._calculationIdTable(db),
                                referencedColumn:
                                    $$CalculationMaterialsTableReferences
                                        ._calculationIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$CalculationMaterialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalculationMaterialsTable,
      CalculationMaterial,
      $$CalculationMaterialsTableFilterComposer,
      $$CalculationMaterialsTableOrderingComposer,
      $$CalculationMaterialsTableAnnotationComposer,
      $$CalculationMaterialsTableCreateCompanionBuilder,
      $$CalculationMaterialsTableUpdateCompanionBuilder,
      (CalculationMaterial, $$CalculationMaterialsTableReferences),
      CalculationMaterial,
      PrefetchHooks Function({bool calculationId})
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          Setting,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            Setting,
            BaseReferences<_$AppDatabase, $SettingsTableTable, Setting>,
          ),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      Setting,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTableTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PrintersTableTableManager get printers =>
      $$PrintersTableTableManager(_db, _db.printers);
  $$FilamentsTableTableManager get filaments =>
      $$FilamentsTableTableManager(_db, _db.filaments);
  $$CalculationsTableTableManager get calculations =>
      $$CalculationsTableTableManager(_db, _db.calculations);
  $$CalculationMaterialsTableTableManager get calculationMaterials =>
      $$CalculationMaterialsTableTableManager(_db, _db.calculationMaterials);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
