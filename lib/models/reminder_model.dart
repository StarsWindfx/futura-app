class ReminderModel {
  final String id;
  String title;
  String note;
  DateTime dateTime;
  bool isCompleted;
  bool isRecurring;
  List<int> recurringDays; // 1=Mon .. 7=Sun
  int notificationId;

  ReminderModel({
    required this.id,
    required this.title,
    this.note = '',
    required this.dateTime,
    this.isCompleted = false,
    this.isRecurring = false,
    this.recurringDays = const [],
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'dateTime': dateTime.toIso8601String(),
        'isCompleted': isCompleted,
        'isRecurring': isRecurring,
        'recurringDays': recurringDays,
        'notificationId': notificationId,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'],
        title: json['title'],
        note: json['note'] ?? '',
        dateTime: DateTime.parse(json['dateTime']),
        isCompleted: json['isCompleted'] ?? false,
        isRecurring: json['isRecurring'] ?? false,
        recurringDays: List<int>.from(json['recurringDays'] ?? []),
        notificationId: json['notificationId'],
      );

  ReminderModel copyWith({
    String? title,
    String? note,
    DateTime? dateTime,
    bool? isCompleted,
    bool? isRecurring,
    List<int>? recurringDays,
  }) =>
      ReminderModel(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        dateTime: dateTime ?? this.dateTime,
        isCompleted: isCompleted ?? this.isCompleted,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringDays: recurringDays ?? this.recurringDays,
        notificationId: notificationId,
      );

  String get recurringLabel {
    if (!isRecurring || recurringDays.isEmpty) return '';
    const days = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    if (recurringDays.length == 7) return 'Chaque jour';
    if (recurringDays.toSet().containsAll({1, 2, 3, 4, 5}) && recurringDays.length == 5) {
      return 'Jours de semaine';
    }
    return recurringDays.map((d) => days[d]).join(' · ');
  }
}
