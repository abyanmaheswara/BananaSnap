import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'banana_classifier.dart';

/// Model data untuk riwayat deteksi
class DetectionHistory {
  final int?   id;
  final String label;
  final double confidence;
  final bool   isFresh;
  final String imagePath;
  final DateTime timestamp;

  DetectionHistory({
    this.id,
    required this.label,
    required this.confidence,
    required this.isFresh,
    required this.imagePath,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id':         id,
    'label':      label,
    'confidence': confidence,
    'is_fresh':   isFresh ? 1 : 0,
    'image_path': imagePath,
    'timestamp':  timestamp.toIso8601String(),
  };

  factory DetectionHistory.fromMap(Map<String, dynamic> map) =>
      DetectionHistory(
        id:         map['id'],
        label:      map['label'],
        confidence: map['confidence'],
        isFresh:    map['is_fresh'] == 1,
        imagePath:  map['image_path'],
        timestamp:  DateTime.parse(map['timestamp']),
      );
}

/// Service database SQLite untuk menyimpan riwayat
class HistoryDatabase {
  static final HistoryDatabase _instance = HistoryDatabase._internal();
  factory HistoryDatabase() => _instance;
  HistoryDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'banana_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            label      TEXT    NOT NULL,
            confidence REAL    NOT NULL,
            is_fresh   INTEGER NOT NULL,
            image_path TEXT    NOT NULL,
            timestamp  TEXT    NOT NULL
          )
        ''');
      },
    );
  }

  /// Simpan hasil deteksi baru
  Future<int> insertDetection({
    required PredictionResult result,
    required String imagePath,
  }) async {
    final db = await database;
    return await db.insert('history', {
      'label':      result.label,
      'confidence': result.confidence,
      'is_fresh':   result.isFresh ? 1 : 0,
      'image_path': imagePath,
      'timestamp':  result.timestamp.toIso8601String(),
    });
  }

  /// Ambil semua riwayat (terbaru di atas)
  Future<List<DetectionHistory>> getAllHistory() async {
    final db = await database;
    final maps = await db.query(
      'history',
      orderBy: 'timestamp DESC',
    );
    return maps.map(DetectionHistory.fromMap).toList();
  }

  /// Hapus satu item
  Future<void> deleteDetection(int id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  /// Hapus semua riwayat
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('history');
  }

  /// Statistik: total, layak, tidak layak
  Future<Map<String, int>> getStats() async {
    final db = await database;
    final total  = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM history')) ?? 0;
    final fresh  = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM history WHERE is_fresh = 1')) ?? 0;
    final rotten = total - fresh;
    return {'total': total, 'fresh': fresh, 'rotten': rotten};
  }
}
