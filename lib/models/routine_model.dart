enum RecurringAlertType { none, interval, hourly, daily }

class RoutineModel {
  final String id;
  String title;
  String description;
  List<String> steps;
  int timeMinutes;
  int? endTimeMinutes; // fin de la plage de rappels (null = pas de plage)
  List<int> days;
  bool isActive;
  bool notificationsEnabled;
  List<int> notificationIds;

  RecurringAlertType alertType;
  int alertIntervalMinutes;
  List<int> alertNotifIds;

  RoutineModel({
    required this.id,
    required this.title,
    this.description = '',
    this.steps = const [],
    required this.timeMinutes,
    this.endTimeMinutes,
    this.days = const [1, 2, 3, 4, 5],
    this.isActive = true,
    this.notificationsEnabled = true,
    this.notificationIds = const [],
    this.alertType = RecurringAlertType.none,
    this.alertIntervalMinutes = 60,
    this.alertNotifIds = const [],
  });

  int get hour => timeMinutes ~/ 60;
  int get minute => timeMinutes % 60;
  int get endHour => (endTimeMinutes ?? timeMinutes) ~/ 60;
  int get endMinute => (endTimeMinutes ?? timeMinutes) % 60;

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get timeLabelFull {
    if (endTimeMinutes == null || alertType == RecurringAlertType.none) return timeLabel;
    final eh = endHour.toString().padLeft(2, '0');
    final em = endMinute.toString().padLeft(2, '0');
    return '$timeLabel → $eh:$em';
  }

  String get daysLabel {
    const names = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    if (days.length == 7) return 'Quotidien';
    if (days.toSet().containsAll({1, 2, 3, 4, 5}) && days.length == 5) return 'Sem.';
    if (days.toSet().containsAll({6, 7}) && days.length == 2) return 'W-E';
    return days.map((d) => names[d]).join(' ');
  }

  String get alertLabel {
    switch (alertType) {
      case RecurringAlertType.none: return 'Désactivé';
      case RecurringAlertType.hourly: return 'Toutes les heures';
      case RecurringAlertType.daily: return 'Chaque jour';
      case RecurringAlertType.interval:
        if (alertIntervalMinutes < 60) return 'Toutes les ${alertIntervalMinutes}min';
        final h = alertIntervalMinutes ~/ 60;
        final m = alertIntervalMinutes % 60;
        return m == 0 ? 'Toutes les ${h}h' : 'Toutes les ${h}h${m}min';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'steps': steps,
        'timeMinutes': timeMinutes,
        'endTimeMinutes': endTimeMinutes,
        'days': days,
        'isActive': isActive,
        'notificationsEnabled': notificationsEnabled,
        'notificationIds': notificationIds,
        'alertType': alertType.index,
        'alertIntervalMinutes': alertIntervalMinutes,
        'alertNotifIds': alertNotifIds,
      };

  factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        steps: List<String>.from(json['steps'] ?? []),
        timeMinutes: json['timeMinutes'] ?? 420,
        endTimeMinutes: json['endTimeMinutes'],
        days: List<int>.from(json['days'] ?? [1, 2, 3, 4, 5]),
        isActive: json['isActive'] ?? true,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        notificationIds: List<int>.from(json['notificationIds'] ?? []),
        alertType: RecurringAlertType.values[json['alertType'] ?? 0],
        alertIntervalMinutes: json['alertIntervalMinutes'] ?? 60,
        alertNotifIds: List<int>.from(json['alertNotifIds'] ?? []),
      );

  RoutineModel copyWith({
    String? title,
    String? description,
    List<String>? steps,
    int? timeMinutes,
    int? endTimeMinutes,
    bool clearEndTime = false,
    List<int>? days,
    bool? isActive,
    bool? notificationsEnabled,
    List<int>? notificationIds,
    RecurringAlertType? alertType,
    int? alertIntervalMinutes,
    List<int>? alertNotifIds,
  }) =>
      RoutineModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        steps: steps ?? this.steps,
        timeMinutes: timeMinutes ?? this.timeMinutes,
        endTimeMinutes: clearEndTime ? null : (endTimeMinutes ?? this.endTimeMinutes),
        days: days ?? this.days,
        isActive: isActive ?? this.isActive,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        notificationIds: notificationIds ?? this.notificationIds,
        alertType: alertType ?? this.alertType,
        alertIntervalMinutes: alertIntervalMinutes ?? this.alertIntervalMinutes,
        alertNotifIds: alertNotifIds ?? this.alertNotifIds,
      );
}
