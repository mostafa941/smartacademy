class WeeklyReportModel {
  final String id;
  final String studentId;
  final DateTime createdAt;
  final bool completedDuties;
  final String completedLessons;
  final String note;
  final int weekNumber;
  final int year;
  final String? teacherName;
  final String? teacherPhotoUrl;
  final String? subject;

  WeeklyReportModel({
    required this.id,
    required this.studentId,
    required this.createdAt,
    this.completedDuties = false,
    required this.completedLessons,
    required this.note,
    required this.weekNumber,
    required this.year,
    this.teacherName,
    this.teacherPhotoUrl,
    this.subject,
  });

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now();
    // Calculate ISO week number
    final startOfYear = DateTime(createdAt.year, 1, 1);
    final diff = createdAt.difference(startOfYear);
    final weekNum = ((diff.inDays + startOfYear.weekday) / 7).ceil();

    return WeeklyReportModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      createdAt: createdAt,
      completedDuties: json['completed_duties'] ?? false,
      completedLessons: json['completed_lessons'] ?? 'لا يوجد',
      note: json['note'] ?? 'لا يوجد',
      weekNumber: weekNum,
      year: createdAt.year,
      teacherName: json['teacher_name'],
      teacherPhotoUrl: json['teacher_photo_url'],
      subject: json['subject'],
    );
  }
}
