class MessageItem {
  final int? id;
  final DateTime dateTime;
  final String content;
  final String location;
  final String category;

  MessageItem({
    this.id,
    required this.dateTime,
    required this.content,
    required this.location,
    required this.category,
  });

  MessageItem copyWith({
    int? id,
    DateTime? dateTime,
    String? content,
    String? location,
    String? category,
  }) {
    return MessageItem(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      content: content ?? this.content,
      location: location ?? this.location,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'content': content,
      'location': location,
      'category': category,
    };
  }

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: json['id'] as int?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      content: json['content'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
    );
  }
} 