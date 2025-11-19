import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL,
        reply_to_id INTEGER
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN reply_to_id INTEGER');
    }
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', {
      'text': note.text,
      'created_at': note.createdAt.toIso8601String(),
      'reply_to_id': note.replyToId,
    });
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.update(
      'notes',
      {
        'text': note.text,
        'created_at': note.createdAt.toIso8601String(),
        'reply_to_id': note.replyToId,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getNotesForDay(String dateKey) async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'strftime("%Y-%m-%d", created_at) = ?',
      whereArgs: [dateKey],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<Map<String, int>> getNoteCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT strftime("%Y-%m-%d", created_at) as date_key, COUNT(*) as count
      FROM notes
      GROUP BY date_key
      ORDER BY date_key DESC
    ''');
    Map<String, int> counts = {};
    for (var row in result) {
      counts[row['date_key'] as String] = row['count'] as int;
    }
    return counts;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
