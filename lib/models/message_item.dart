class MessageItem {
  final int? id;
  final DateTime dateTime;
  final String content;
  final String location;
  final String category;
  final DateTime createdAt;

  static final List<String> columns = [
    'id',
    'dateTime',
    'content',
    'location',
    'category',
    'createdAt'
  ];

  MessageItem({
    this.id,
    required this.dateTime,
    required this.content,
    required this.location,
    required this.category,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  MessageItem copy({
    int? id,
    DateTime? dateTime,
    String? content,
    String? location,
    String? category,
    DateTime? createdAt,
  }) =>
      MessageItem(
        id: id ?? this.id,
        dateTime: dateTime ?? this.dateTime,
        content: content ?? this.content,
        location: location ?? this.location,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'content': content,
        'location': location,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  static MessageItem fromJson(Map<String, dynamic> json) => MessageItem(
        id: json['id'] as int?,
        dateTime: DateTime.parse(json['dateTime'] as String),
        content: json['content'] as String,
        location: json['location'] as String,
        category: json['category'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
} 