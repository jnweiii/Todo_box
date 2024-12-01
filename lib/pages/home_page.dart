class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages();
    });
    
    // 搜索监听
    _searchController.addListener(() {
      context.read<MessageProvider>().updateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE6D5B8),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '消息收纳箱',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMessageDialog(context),
        child: const Icon(Icons.add),
      ),
      body: messageProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildCategorySelector(messageProvider),
                  _buildMessageList(messageProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索信息',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  // UI 构建方法保持不变，但使用 Provider 中的数据
  Widget _buildCategorySelector(MessageProvider provider) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: provider.categories.map((category) {
          final isSelected = category == provider.selectedCategory;
          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => provider.updateCategory(category),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageList(MessageProvider provider) {
    return Expanded(
      child: ListView.builder(
        itemCount: provider.filteredMessages.length,
        itemBuilder: (context, index) {
          final message = provider.filteredMessages[index];
          return _buildMessageItem(message);
        },
      ),
    );
  }

  void _showAddMessageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MessageDialog(),
    );
  }

  void _showEditMessageDialog(MessageItem message) {
    showDialog(
      context: context,
      builder: (context) => MessageDialog(
        message: message,
        isEditing: true,
      ),
    );
  }

  Widget _buildMessageItem(MessageItem message) {
    return Dismissible(
      key: Key(message.id.toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除这条信息吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        try {
          await context.read<MessageProvider>().deleteMessage(message.id!);
          AppErrorHandler.showSuccess(context, '信息删除成功');
        } catch (e) {
          AppErrorHandler.showError(context, '删除失败: ${e.toString()}');
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(
            DateFormat('yyyy-MM-dd HH:mm').format(message.dateTime),
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(message.content),
          trailing: Text(message.category),
          onTap: () => _showEditMessageDialog(message),
        ),
      ),
    );
  }
} 