class EventModel {
  final String id;
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  bool isAllDay;
  int colorIndex; // 0=white, 1=blue, 2=green, 3=orange, 4=red
  int notificationId;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.startDate,
    required this.endDate,
    this.isAllDay = false,
    this.colorIndex = 0,
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'isAllDay': isAllDay,
        'colorIndex': colorIndex,
        'notificationId': notificationId,
      };

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        isAllDay: json['isAllDay'] ?? false,
        colorIndex: json['colorIndex'] ?? 0,
        notificationId: json['notificationId'],
      );

  EventModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    int? colorIndex,
  }) =>
      EventModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        isAllDay: isAllDay ?? this.isAllDay,
        colorIndex: colorIndex ?? this.colorIndex,
        notificationId: notificationId,
      );

  bool isOnDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}
