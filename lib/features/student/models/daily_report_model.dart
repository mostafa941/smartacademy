class DailyReportModel {
  final String id;
  final String studentId;
  final DateTime reportDate;
  final bool isPresent;
  final String? arrivalTime;
  final bool mealEaten;
  final bool breakTaken;
  final String? note;
  final int stars;
  final List<HomeworkModel> homeworks;
  final String? teacherName;
  final String? teacherPhotoUrl;
  final String? subject;

  DailyReportModel({
    required this.id,
    required this.studentId,
    required this.reportDate,
    this.isPresent = false,
    this.arrivalTime,
    this.mealEaten = false,
    this.breakTaken = false,
    this.note,
    this.stars = 0,
    this.homeworks = const [],
    this.teacherName,
    this.teacherPhotoUrl,
    this.subject,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      reportDate: json['report_date'] != null 
          ? DateTime.parse(json['report_date']) 
          : DateTime.now(),
      isPresent: json['attendance'] ?? json['is_present'] ?? false,
      arrivalTime: json['arrival_time'],
      mealEaten: json['ate_meal'] ?? json['meal_eaten'] ?? false,
      breakTaken: json['took_break'] ?? json['break_taken'] ?? false,
      note: json['note'],
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      homeworks: json['homeworks'] != null 
          ? (json['homeworks'] as List).map((hw) => HomeworkModel.fromJson(hw)).toList() 
          : [],
      teacherName: json['teacher_name'],
      teacherPhotoUrl: json['teacher_photo_url'],
      subject: json['subject'],
    );
  }
}

class HomeworkModel {
  final String subject;
  final String title;
  final bool isCompleted;

  HomeworkModel({
    required this.subject,
    required this.title,
    this.isCompleted = false,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      subject: json['subject'] ?? '',
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
    );
  }
}
