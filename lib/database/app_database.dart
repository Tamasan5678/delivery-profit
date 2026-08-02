import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const databaseName = 'delivery_profit.db';
  static const databaseVersion = 3;
  static const deliveryRecordsTable = 'delivery_records';

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final path = p.join(await getDatabasesPath(), databaseName);
    return databaseFactory.openDatabase(path, options: openOptions);
  }

  static OpenDatabaseOptions get openOptions => OpenDatabaseOptions(
    version: databaseVersion,
    onCreate: createDatabase,
    onUpgrade: upgradeDatabase,
  );

  static Future<void> createDatabase(Database db, int version) async {
    await db.execute(_createDeliveryRecordsTable(deliveryRecordsTable));
    await _createIndexes(db);
  }

  static Future<void> upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $deliveryRecordsTable ADD COLUMN session_id TEXT',
      );
      await db.execute('''
            UPDATE $deliveryRecordsTable
            SET session_id = 'legacy-' || started_at_utc_ms ||
              CASE
                WHEN id = (
                  SELECT MIN(existing.id)
                  FROM $deliveryRecordsTable AS existing
                  WHERE existing.started_at_utc_ms =
                    $deliveryRecordsTable.started_at_utc_ms
                ) THEN ''
                ELSE '-' || id
              END
      ''');
      await db.execute('''
            CREATE UNIQUE INDEX idx_delivery_records_session_id
            ON $deliveryRecordsTable (session_id)
      ''');
      await db.execute('''
            CREATE TRIGGER delivery_records_session_id_required
            BEFORE INSERT ON $deliveryRecordsTable
            WHEN NEW.session_id IS NULL OR trim(NEW.session_id) = ''
            BEGIN
              SELECT RAISE(ABORT, 'session_id is required');
            END
      ''');
    }
    if (oldVersion < 3) {
      await _migrateToValidatedSchema(db);
    }
  }

  static Future<void> _migrateToValidatedSchema(Database db) async {
    const replacementTable = 'delivery_records_v3';
    await db.execute(_createDeliveryRecordsTable(replacementTable));
    await db.execute('''
      INSERT INTO $replacementTable (
        id, session_id, started_at_utc_ms, finished_at_utc_ms,
        start_distance_km, target_count, weather, online_minutes,
        sales_yen, delivery_count, travel_distance_km,
        fuel_efficiency_km_per_liter, fuel_price_yen_per_liter,
        fuel_used_liters, fuel_cost_yen, profit_yen, created_at_utc_ms
      )
      SELECT
        id, session_id, started_at_utc_ms, finished_at_utc_ms,
        start_distance_km, target_count, weather, online_minutes,
        sales_yen, delivery_count, travel_distance_km,
        fuel_efficiency_km_per_liter, fuel_price_yen_per_liter,
        fuel_used_liters, fuel_cost_yen, profit_yen, created_at_utc_ms
      FROM $deliveryRecordsTable
    ''');
    await db.execute('DROP TABLE $deliveryRecordsTable');
    await db.execute(
      'ALTER TABLE $replacementTable RENAME TO $deliveryRecordsTable',
    );
    await _createIndexes(db);
  }

  static String _createDeliveryRecordsTable(String table) =>
      '''
    CREATE TABLE $table (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id TEXT NOT NULL
        CHECK(typeof(session_id) = 'text' AND length(trim(session_id)) > 0),
      started_at_utc_ms INTEGER NOT NULL
        CHECK(typeof(started_at_utc_ms) = 'integer' AND started_at_utc_ms >= 0),
      finished_at_utc_ms INTEGER NOT NULL
        CHECK(typeof(finished_at_utc_ms) = 'integer' AND
          finished_at_utc_ms >= started_at_utc_ms),
      start_distance_km REAL NOT NULL
        CHECK(typeof(start_distance_km) IN ('real', 'integer') AND
          start_distance_km >= 0 AND start_distance_km < 1.0e308),
      target_count INTEGER NOT NULL
        CHECK(typeof(target_count) = 'integer' AND target_count BETWEEN 0 AND 99),
      weather TEXT NOT NULL
        CHECK(typeof(weather) = 'text' AND length(trim(weather)) > 0),
      online_minutes INTEGER NOT NULL
        CHECK(typeof(online_minutes) = 'integer' AND online_minutes >= 0),
      sales_yen INTEGER NOT NULL
        CHECK(typeof(sales_yen) = 'integer' AND sales_yen >= 0),
      delivery_count INTEGER NOT NULL
        CHECK(typeof(delivery_count) = 'integer' AND delivery_count >= 0),
      travel_distance_km REAL NOT NULL
        CHECK(typeof(travel_distance_km) IN ('real', 'integer') AND
          travel_distance_km >= 0 AND travel_distance_km < 1.0e308),
      fuel_efficiency_km_per_liter REAL NOT NULL
        CHECK(typeof(fuel_efficiency_km_per_liter) IN ('real', 'integer') AND
          fuel_efficiency_km_per_liter > 0 AND
          fuel_efficiency_km_per_liter <= 50.0),
      fuel_price_yen_per_liter INTEGER NOT NULL
        CHECK(typeof(fuel_price_yen_per_liter) = 'integer' AND
          fuel_price_yen_per_liter BETWEEN 100 AND 300),
      fuel_used_liters REAL NOT NULL
        CHECK(typeof(fuel_used_liters) IN ('real', 'integer') AND
          fuel_used_liters >= 0 AND fuel_used_liters < 1.0e308),
      fuel_cost_yen INTEGER NOT NULL
        CHECK(typeof(fuel_cost_yen) = 'integer' AND fuel_cost_yen >= 0),
      profit_yen INTEGER NOT NULL
        CHECK(typeof(profit_yen) = 'integer' AND
          profit_yen = sales_yen - fuel_cost_yen),
      created_at_utc_ms INTEGER NOT NULL
        CHECK(typeof(created_at_utc_ms) = 'integer' AND created_at_utc_ms >= 0)
    )
  ''';

  static Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX idx_delivery_records_finished_at
      ON $deliveryRecordsTable (finished_at_utc_ms)
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX idx_delivery_records_session_id
      ON $deliveryRecordsTable (session_id)
    ''');
  }
}
