import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/message_provider.dart';
import '../models/message_item.dart';
import '../core/error/error_handler.dart';

class MessageDialog extends StatefulWidget {
  final MessageItem? message;
  final bool isEditing;

  const MessageDialog({
    super.key,
    this.message,
    this.isEditing = false,
  });

  @override
  State<MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<MessageDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDateTime;
  late TextEditingController _contentController;
  late TextEditingController _locationController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.message?.dateTime ?? DateTime.now();
    _contentController = TextEditingController(text: widget.message?.content);
    _locationController = TextEditingController(text: widget.message?.location);
    _selectedCategory = widget.message?.category ?? 
        context.read<MessageProvider>().categories[1];
  }

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? '编辑信息' : '添加新信息'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '时间',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? '请输入内容' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '地点',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => 
                    value?.isEmpty ?? true ? '请输入地点' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '类别',
                  border: OutlineInputBorder(),
                ),
                items: context.read<MessageProvider>().categories
                    .where((c) => c != '全部')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => 
                    value == null ? '请选择类别' : null,
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
            if (_formKey.currentState?.validate() ?? false) {
              try {
                final message = MessageItem(
                  id: widget.message?.id,
                  dateTime: _selectedDateTime,
                  content: _contentController.text,
                  location: _locationController.text,
                  category: _selectedCategory!,
                );

                if (widget.isEditing) {
                  await context.read<MessageProvider>().updateMessage(message);
                } else {
                  await context.read<MessageProvider>().addMessage(message);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                AppErrorHandler.showError(
                  context,
                  '操作失败: ${e.toString()}',
                );
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
} 