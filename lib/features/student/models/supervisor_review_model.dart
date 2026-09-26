class SupervisorReviewModel {
  final String id;
  final String studentId;
  final DateTime reviewDate;
  final String teacherName;
  final String? teacherPhotoUrl;
  final String subject;
  final String notes;
  final String behaviorRating; // e.g., مميز, جيد جداً, يحتاج متابعة

  SupervisorReviewModel({
    required this.id,
    required this.studentId,
    required this.reviewDate,
    required this.teacherName,
    this.teacherPhotoUrl,
    required this.subject,
    required this.notes,
    required this.behaviorRating,
  });

  factory SupervisorReviewModel.fromJson(Map<String, dynamic> json) {
    return SupervisorReviewModel(
      id: json['id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      reviewDate: json['review_date'] != null 
          ? DateTime.parse(json['review_date']) 
          : DateTime.now(),
      teacherName: json['teacher_name'] ?? '',
      teacherPhotoUrl: json['teacher_photo_url'],
      subject: json['subject'] ?? '',
      notes: json['notes'] ?? '',
      behaviorRating: json['behavior_rating'] ?? 'جيد',
    );
  }
}
