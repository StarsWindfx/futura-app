class TaskModel {
  final String id;
  String title;
  String description;
  bool isCompleted;
  int priority; // 0=low, 1=medium, 2=high
  DateTime? dueDate;
  String category;
  final DateTime createdAt;
  List<String> subtasks;
  List<bool> subtasksDone;
  DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 0,
    this.dueDate,
    this.category = '',
    required this.createdAt,
    this.subtasks = const [],
    this.subtasksDone = const [],
    this.completedAt,
  });

  int get subtaskCount => subtasks.length;
  int get subtaskDoneCount => subtasksDone.where((d) => d).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'subtasks': subtasks,
        'subtasksDone': subtasksDone,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
        priority: json['priority'] ?? 0,
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        category: json['category'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        subtasks: List<String>.from(json['subtasks'] ?? []),
        subtasksDone: List<bool>.from(json['subtasksDone'] ?? []),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      );

  TaskModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    String? category,
    bool clearDueDate = false,
    List<String>? subtasks,
    List<bool>? subtasksDone,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) =>
      TaskModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        priority: priority ?? this.priority,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        category: category ?? this.category,
        createdAt: createdAt,
        subtasks: subtasks ?? this.subtasks,
        subtasksDone: subtasksDone ?? this.subtasksDone,
        completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      );
}
