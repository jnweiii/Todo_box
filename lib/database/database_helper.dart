import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('messages.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateTime TEXT NOT NULL,
        content TEXT NOT NULL,
        location TEXT NOT NULL,
        category TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<MessageItem> create(MessageItem message) async {
    final db = await instance.database;
    final id = await db.insert('messages', message.toJson());
    return message.copy(id: id);
  }

  Future<MessageItem?> readMessage(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'messages',
      columns: MessageItem.columns,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return MessageItem.fromJson(maps.first);
    }
    return null;
  }

  Future<List<MessageItem>> readAllMessages() async {
    final db = await instance.database;
    final result = await db.query('messages', orderBy: 'createdAt DESC');
    return result.map((json) => MessageItem.fromJson(json)).toList();
  }

  Future<int> update(MessageItem message) async {
    final db = await instance.database;
    return db.update(
      'messages',
      message.toJson(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MessageItem>> search(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'content LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => MessageItem.fromJson(json)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 