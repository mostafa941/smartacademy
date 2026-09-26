import 'package:flutter/material.dart';
import '../../teacher/screens/teacher_main_layout.dart';
import 'package:provider/provider.dart';
import '../../student/screens/student_main_layout.dart';
import '../../student/providers/student_provider.dart';

class HomeScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String role;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'teacher') {
      return TeacherMainLayout(userId: userId, userName: userName);
    }

    // Student Layout
    return ChangeNotifierProvider(
      create: (_) => StudentProvider(),
      child: StudentMainLayout(userId: userId, userName: userName),
    );
  }
}
