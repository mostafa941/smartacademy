class StudentModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String grade;
  final String parentPhone;

  StudentModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.grade,
    required this.parentPhone,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      photoUrl: json['photo_url'],
      grade: json['age_group'] ?? json['grade'] ?? '',
      parentPhone: json['parent_phone'] ?? '',
    );
  }
}
