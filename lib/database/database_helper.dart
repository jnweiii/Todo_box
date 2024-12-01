import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/message_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      throw UnsupportedError('Web平台不支持SQLite');
    } else {
      // 移动平台使用 SQLite
      _database = await _initDB('messages.db');
      return _database!;
    }
  }

  // 创建消息
  Future<MessageItem> create(MessageItem message) async {
    try {
      if (kIsWeb) {
        // Web平台使用 localStorage
        final prefs = await SharedPreferences.getInstance();
        final messages = await _getWebMessages();
        final newId = messages.isEmpty ? 1 : messages.map((m) => m.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
        final newMessage = message.copyWith(id: newId);
        messages.add(newMessage);
        await _saveWebMessages(messages);
        return newMessage;
      } else {
        // 移动平台使用原有的 SQLite 实现
        final db = await database;
        final id = await db.insert('messages', message.toJson());
        return message.copyWith(id: id);
      }
    } catch (e) {
      debugPrint('保存消息时出错: $e');
      rethrow;
    }
  }

  // 获取所有消息
  Future<List<MessageItem>> getMessages() async {
    try {
      if (kIsWeb) {
        return await _getWebMessages();
      } else {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query('messages');
        return List.generate(maps.length, (i) => MessageItem.fromJson(maps[i]));
      }
    } catch (e) {
      debugPrint('获取消息时出错: $e');
      rethrow;
    }
  }

  // Web平台特定方法
  Future<List<MessageItem>> _getWebMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? messagesJson = prefs.getString('messages');
    if (messagesJson == null) return [];
    final List<dynamic> decoded = jsonDecode(messagesJson);
    return decoded.map((json) => MessageItem.fromJson(json)).toList();
  }

  Future<void> _saveWebMessages(List<MessageItem> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString('messages', encoded);
  }

  // 原有的 SQLite 相关方法保持不变
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
      CREATE TABLE messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateTime TEXT NOT NULL,
        content TEXT NOT NULL,
        location TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');
  }

  // 更新消息
  Future<void> update(MessageItem message) async {
    try {
      if (kIsWeb) {
        final messages = await _getWebMessages();
        final index = messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          messages[index] = message;
          await _saveWebMessages(messages);
        }
      } else {
        final db = await database;
        await db.update(
          'messages',
          message.toJson(),
          where: 'id = ?',
          whereArgs: [message.id],
        );
      }
    } catch (e) {
      debugPrint('更新消息时出错: $e');
      rethrow;
    }
  }

  // 删除消息
  Future<void> delete(int id) async {
    try {
      if (kIsWeb) {
        final messages = await _getWebMessages();
        messages.removeWhere((m) => m.id == id);
        await _saveWebMessages(messages);
      } else {
        final db = await database;
        await db.delete(
          'messages',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('删除消息时出错: $e');
      rethrow;
    }
  }
} 