import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'widgets/message_dialog.dart';
import 'models/message_item.dart';
import 'database/database_helper.dart';
import 'providers/message_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MessageProvider(),
      child: MaterialApp(
        title: '消息收纳箱',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<MessageItem> _allMessages = [];
  String selectedCategory = '全部';
  List<MessageItem> filteredMessages = [];

  final List<String> categories = [
    '全部',
    '紧急且重要',
    '紧急不重要',
    '重要不紧急',
    '不紧急不重要',
    '其它'
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await DatabaseHelper.instance.getMessages();
      setState(() {
        _allMessages = messages;
      });
    } catch (e) {
      debugPrint('加载消息失败: $e');
    }
  }

  void _onSearchChanged() {
    // 搜索逻辑实现
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE6D5B8),  // 更深的米黄色
            Colors.white,       // 白色
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddMessageDialog(context),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildCategorySelector(),
              Expanded(
                child: _buildMessageList(),
              ),
            ],
          ),
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
            '消息收纳箱',
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
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedCategory = category;
                _filterMessages();
              });
            },
          );
        }).toList(),
      ),
    );
  }

  // 添加消息过滤方法
  void _filterMessages() {
    if (_searchController.text.isEmpty) {
      filteredMessages = _allMessages.where((message) {
        return selectedCategory == '全部' || message.category == selectedCategory;
      }).toList();
    } else {
      filteredMessages = _allMessages.where((message) {
        final matchesSearch = message.content.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            message.location.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );
        return (selectedCategory == '全部' || 
                message.category == selectedCategory) &&
            matchesSearch;
      }).toList();
    }
  }

  // 信息列表
  Widget _buildMessageList() {
    return ListView.builder(
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      
                      if (date != null) {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                alwaysUse24HourFormat: true, // 强制使用 24 小时制
                              ),
                              child: child!,
                            );
                          },
                        );
                        
                        if (time != null) {
                          setState(() {
                            // 正确处理 AM/PM 转换为 24 小时制
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
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
                debugPrint('保存按钮被点击'); // 调试点 1
                if (formKey.currentState?.validate() ?? false) {
                  debugPrint('表单验证通过'); // 调试点 2
                  formKey.currentState?.save();
                  final message = MessageItem(
                    dateTime: selectedDateTime,
                    content: content,
                    location: location,
                    category: category,
                  );
                  debugPrint('准备保存消息: ${message.toString()}'); // 调试点 3
                  try {
                    await DatabaseHelper.instance.create(message);
                    debugPrint('数据库保存成功'); // 调试点 4
                    await _loadMessages();
                    debugPrint('消息列表已重新加载'); // 调试点 5
                    Navigator.pop(context);
                  } catch (e) {
                    debugPrint('保存失败: $e'); // 调试点 6
                    // 添加错误提示
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('保存失败: $e')),
                      );
                    }
                  }
                } else {
                  debugPrint('表单验证失败'); // 调试点 7
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
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
                final updatedMessage = message.copyWith(
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