import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:message_box/database/database_helper.dart';
import 'package:message_box/models/message_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '信息收纳箱',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFE5B5B5), // 粉色背景
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 当前选中的类别
  String selectedCategory = '全部';
  
  // 类别列表
  final List<String> categories = [
    '全部',
    '紧急且重要',
    '紧急不重要',
    '重要不紧急',
    '不紧急不重要',
    '其它'
  ];

  // 模拟的信息数据
  final List<MessageItem> messages = [
    MessageItem(
      dateTime: DateTime.now(),
      content: '你的外卖已送到指定取餐点',
      location: '学校食堂',
      category: '紧急不重要',
    ),
    // 可以添加更多示例数据
  ];

  final TextEditingController _searchController = TextEditingController();
  List<MessageItem> _allMessages = [];
  List<MessageItem> _filteredMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    _allMessages = await DatabaseHelper.instance.readAllMessages();
    _filterMessages();
    setState(() => _isLoading = false);
  }

  void _filterMessages() {
    if (_searchController.text.isEmpty) {
      _filteredMessages = _allMessages.where((message) {
        return selectedCategory == '全部' || message.category == selectedCategory;
      }).toList();
    } else {
      _filteredMessages = _allMessages.where((message) {
        final matchesSearch = message.content.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            message.location.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        return (selectedCategory == '全部' || message.category == selectedCategory) &&
            matchesSearch;
      }).toList();
    }
    setState(() {});
  }

  void _onSearchChanged() {
    _filterMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 添加浮动按钮用于新增信息
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMessageDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部导航栏
            _buildAppBar(),
            // 搜索栏
            _buildSearchBar(),
            // 类别选择区
            _buildCategorySelector(),
            // 信息展示区
            Expanded(
              child: _buildMessageList(),
            ),
          ],
        ),
      ),
    );
  }

  // 顶部导航栏
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Text(
            '信息',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索信息',
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
    );
  }

  // 类别选择区
  Widget _buildCategorySelector() {
    return Container(
      height: 100,  // 增加高度以适应两行
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(  // 使用 Wrap 替换 ListView.builder 来实现自动换行
        spacing: 8.0,  // 水平间距
        runSpacing: 8.0,  // 垂直间距
        alignment: WrapAlignment.center,  // 居中对齐
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          
          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                selectedCategory = category;
              });
            },
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        }).toList(),
      ),
    );
  }

  // 信息列表
  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: _filteredMessages.length,
      itemBuilder: (context, index) {
        final message = _filteredMessages[index];
        return _buildMessageItem(message);
      },
    );
  }

  // 单个信息项
  Widget _buildMessageItem(MessageItem message) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          DateFormat('yyyy-MM-dd HH:mm').format(message.dateTime),
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(message.content),
        trailing: Text(message.category),
        onTap: () => _showMessageDetails(message),
      ),
    );
  }

  // 显示信息详情对话框
  void _showMessageDetails(MessageItem message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('信息详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间: ${DateFormat('yyyy-MM-dd HH:mm').format(message.dateTime)}'),
            const SizedBox(height: 8),
            Text('内容: ${message.content}'),
            const SizedBox(height: 8),
            Text('地点: ${message.location}'),
            const SizedBox(height: 8),
            Text('类别: ${message.category}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditMessageDialog(message);
            },
            child: const Text('编辑'),
          ),
          TextButton(
            onPressed: () {
              // 实现删除功能
              setState(() {
                _allMessages.remove(message);
              });
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 添加日期时间选择方法
  Future<DateTime?> _selectDateTime(BuildContext context, DateTime? initialDate) async {
    initialDate ??= DateTime.now();
    
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      
      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }
    return null;
  }

  // 更新添加信息对话框
  Future<void> _showAddMessageDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDateTime = DateTime.now();
    String content = '';
    String location = '';
    String category = categories[1];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新信息'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await _selectDateTime(context, selectedDateTime);
                    if (picked != null) {
                      setState(() => selectedDateTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? '请输入内容' : null,
                  onSaved: (value) => content = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '地点',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? '请输入地点' : null,
                  onSaved: (value) => location = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: '类别',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .where((c) => c != '全部')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => category = value ?? category,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                final message = MessageItem(
                  dateTime: selectedDateTime,
                  content: content,
                  location: location,
                  category: category,
                );
                await DatabaseHelper.instance.create(message);
                await _loadMessages();
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示编辑信息对话框
  Future<void> _showEditMessageDialog(MessageItem message) async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDateTime = message.dateTime;
    String content = message.content;
    String location = message.location;
    String category = message.category;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑信息'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await _selectDateTime(
                      context,
                      selectedDateTime,
                    );
                    if (picked != null) {
                      setState(() => selectedDateTime = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: content,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '请输入内容' : null,
                  onSaved: (value) => content = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: location,
                  decoration: const InputDecoration(
                    labelText: '地点',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '请输入地点' : null,
                  onSaved: (value) => location = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: '类别',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .where((c) => c != '全部')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => category = value ?? category,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                final updatedMessage = message.copy(
                  dateTime: selectedDateTime,
                  content: content,
                  location: location,
                  category: category,
                );
                await DatabaseHelper.instance.update(updatedMessage);
                await _loadMessages();
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
} 