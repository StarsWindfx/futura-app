import 'package:uuid/uuid.dart';

class SportExercise {
  final String id;
  String name;
  String emoji;
  String unit; // 'reps', 'sec', 'min'
  int dailyGoal;
  List<int> restDays; // DateTime.weekday: 1=Lun … 7=Dim

  SportExercise({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unit,
    required this.dailyGoal,
    this.restDays = const [],
  });

  bool isRestOn(DateTime date) => restDays.contains(date.weekday);
  bool get isRestToday => isRestOn(DateTime.now());

  SportExercise copyWith({
    String? name,
    String? emoji,
    String? unit,
    int? dailyGoal,
    List<int>? restDays,
  }) =>
      SportExercise(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        unit: unit ?? this.unit,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        restDays: restDays ?? List<int>.from(this.restDays),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'unit': unit,
        'dailyGoal': dailyGoal,
        'restDays': restDays,
      };

  factory SportExercise.fromJson(Map<String, dynamic> j) => SportExercise(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'],
        unit: j['unit'] ?? 'reps',
        dailyGoal: j['dailyGoal'] ?? 10,
        restDays: List<int>.from(j['restDays'] ?? []),
      );

  static List<SportExercise> get defaults {
    const uuid = Uuid();
    return [
      SportExercise(id: uuid.v4(), name: 'Pompes', emoji: '💪', unit: 'reps', dailyGoal: 40),
      SportExercise(id: uuid.v4(), name: 'Squats', emoji: '🏋️', unit: 'reps', dailyGoal: 50),
      SportExercise(id: uuid.v4(), name: 'Abdos', emoji: '🔥', unit: 'reps', dailyGoal: 40),
      SportExercise(id: uuid.v4(), name: 'Burpees', emoji: '⚡', unit: 'reps', dailyGoal: 15),
      SportExercise(id: uuid.v4(), name: 'Planche', emoji: '⏱️', unit: 'sec', dailyGoal: 60),
      SportExercise(id: uuid.v4(), name: 'Fentes', emoji: '🚶', unit: 'reps', dailyGoal: 30),
      SportExercise(id: uuid.v4(), name: 'Dips', emoji: '🤲', unit: 'reps', dailyGoal: 25),
      SportExercise(id: uuid.v4(), name: 'Mountain Climbers', emoji: '🏔️', unit: 'reps', dailyGoal: 40),
    ];
  }
}

class SportDayLog {
  final String date; // YYYY-MM-DD
  final Map<String, int> counts; // exerciseId -> count

  SportDayLog({required this.date, required this.counts});

  int countFor(String id) => counts[id] ?? 0;
  int get totalReps => counts.values.fold(0, (a, b) => a + b);

  SportDayLog withCount(String id, int count) {
    final c = Map<String, int>.from(counts);
    if (count <= 0) {
      c.remove(id);
    } else {
      c[id] = count;
    }
    return SportDayLog(date: date, counts: c);
  }

  Map<String, dynamic> toJson() => {'date': date, 'counts': counts};

  factory SportDayLog.fromJson(Map<String, dynamic> j) => SportDayLog(
        date: j['date'],
        counts: Map<String, int>.from(j['counts'] ?? {}),
      );
}
