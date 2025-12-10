enum NotePriority { low, medium, high }

class Note {
  final int id;
  final String title;
  final String content;
  final DateTime createdAt;
  final NotePriority priority;
  final bool isCompleted;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.priority = NotePriority.medium,
    this.isCompleted = false,
  });

  // Convert Note to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority.toString().split('.').last,
      'isCompleted': isCompleted,
    };
  }

  // Create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      priority: _priorityFromString(json['priority'] ?? 'medium'),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // Copy with method for updating notes
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    NotePriority? priority,
    bool? isCompleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static NotePriority _priorityFromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return NotePriority.high;
      case 'medium':
        return NotePriority.medium;
      case 'low':
        return NotePriority.low;
      default:
        return NotePriority.medium;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          createdAt == other.createdAt &&
          priority == other.priority &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      priority.hashCode ^
      isCompleted.hashCode;

  @override
  String toString() =>
      'Note(id: $id, title: $title, priority: $priority, isCompleted: $isCompleted)';
}
