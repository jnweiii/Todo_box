import 'package:flutter/material.dart';
import '../models/message_item.dart';
import '../database/database_helper.dart';

class MessageProvider extends ChangeNotifier {
  // 状态变量
  List<MessageItem> _allMessages = [];
  List<MessageItem> _filteredMessages = [];
  String _selectedCategory = '全部';
  String _searchQuery = '';
  bool _isLoading = false;

  // Getters
  List<MessageItem> get filteredMessages => _filteredMessages;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  
  // 类别列表
  final List<String> categories = [
    '全部',
    '紧急且重要',
    '紧急不重要',
    '重要不紧急',
    '不紧急不重要',
    '其它'
  ];

  // 初始化加载数据
  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allMessages = await DatabaseHelper.instance.getMessages();
      _filterMessages();
    } catch (e) {
      debugPrint('加载消息失败: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新搜索关键词
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _filterMessages();
    notifyListeners();
  }

  // 更新选中类别
  void updateCategory(String category) {
    _selectedCategory = category;
    _filterMessages();
  }

  // 过滤消息
  void _filterMessages() {
    if (_searchQuery.isEmpty) {
      _filteredMessages = _allMessages.where((message) {
        return _selectedCategory == '全部' || message.category == _selectedCategory;
      }).toList();
    } else {
      _filteredMessages = _allMessages.where((message) {
        final matchesSearch = message.content.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            message.location.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
        return (_selectedCategory == '全部' || 
                message.category == _selectedCategory) &&
            matchesSearch;
      }).toList();
    }
    notifyListeners();
  }

  // 添加消息
  Future<void> addMessage(MessageItem message) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final newMessage = await DatabaseHelper.instance.create(message);
      _allMessages.insert(0, newMessage);
      _filterMessages();
    } catch (e) {
      debugPrint('添加消息失败: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新消息
  Future<void> updateMessage(MessageItem message) async {
    try {
      await DatabaseHelper.instance.update(message);
      final index = _allMessages.indexWhere((m) => m.id == message.id);
      if (index != -1) {
        _allMessages[index] = message;
        _filterMessages();
      }
    } catch (e) {
      debugPrint('更新消息失败: $e');
      rethrow;
    }
  }

  // 删除消息
  Future<void> deleteMessage(int id) async {
    try {
      await DatabaseHelper.instance.delete(id);
      _allMessages.removeWhere((message) => message.id == id);
      _filterMessages();
    } catch (e) {
      debugPrint('删除消息失败: $e');
      rethrow;
    }
  }
} 