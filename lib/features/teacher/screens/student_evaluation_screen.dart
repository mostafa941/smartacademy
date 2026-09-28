import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentEvaluationScreen extends StatefulWidget {
  final String studentId;
  final String teacherId;
  final String studentName;
  final String category;
  final String initial;
  final String? photoUrl;
  final String teacherName;
  final String? teacherAvatarUrl;
  final String teacherSubject;

  const StudentEvaluationScreen({
    super.key,
    required this.studentId,
    required this.teacherId,
    required this.studentName,
    required this.category,
    required this.initial,
    this.photoUrl,
    required this.teacherName,
    this.teacherAvatarUrl,
    this.teacherSubject = 'غير محدد',
  });

  @override
  State<StudentEvaluationScreen> createState() => _StudentEvaluationScreenState();
}

class _StudentEvaluationScreenState extends State<StudentEvaluationScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Daily Evaluation State
  bool isPresent = true;
  bool ateMeal = false;
  bool tookBreak = false;
  int dailyStars = 0;
  final TextEditingController _dailyNoteController = TextEditingController();

  // Weekly Evaluation State
  final TextEditingController _weeklyNoteController = TextEditingController();
  final TextEditingController _completedLessonsController = TextEditingController();
  bool completedWeeklyDuties = true;
  String _weeklyAttendanceRate = 'جاري الحساب...';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calculateWeeklyAttendance();
  }

  Future<void> _calculateWeeklyAttendance() async {
    try {
      // Calculate start of the week (assuming Sunday as start)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      final startStr = startOfWeek.toIso8601String().split('T')[0];
      
      final reportsRes = await _supabase
          .from('daily_reports')
          .select('status, attendance')
          .eq('student_id', widget.studentId)
          .gte('created_at', '${startStr}T00:00:00Z');

      final List reports = reportsRes as List;
      
      if (reports.isEmpty) {
        if (mounted) setState(() => _weeklyAttendanceRate = '٠٪');
        return;
      }

      int presentCount = 0;
      for (var r in reports) {
        if (r['status'] == 'present' || r['attendance'] == true) {
          presentCount++;
        }
      }

      final rate = (presentCount / reports.length) * 100;
      
      // Convert to Arabic numerals
      final arabicRate = rate.toStringAsFixed(0)
          .replaceAll('0', '٠')
          .replaceAll('1', '١')
          .replaceAll('2', '٢')
          .replaceAll('3', '٣')
          .replaceAll('4', '٤')
          .replaceAll('5', '٥')
          .replaceAll('6', '٦')
          .replaceAll('7', '٧')
          .replaceAll('8', '٨')
          .replaceAll('9', '٩');

      if (mounted) {
        setState(() {
          _weeklyAttendanceRate = '$arabicRate٪';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _weeklyAttendanceRate = 'غير متوفر');
    }
  }

  @override
  void dispose() {
    _dailyNoteController.dispose();
    _weeklyNoteController.dispose();
    _completedLessonsController.dispose();
    super.dispose();
  }

  Future<void> _saveEvaluation() async {
    setState(() => _isSaving = true);
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      // ── 1. Fetch teacher name and photo for supervisor_reviews ──
      String teacherName = widget.studentName.isNotEmpty ? 'المدرس' : 'المدرس';
      String? teacherPhotoUrl;
      try {
        final profileRes = await _supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', widget.teacherId)
            .maybeSingle();
        if (profileRes != null) {
          teacherName = profileRes['full_name']?.toString() ?? teacherName;
          teacherPhotoUrl = profileRes['avatar_url']?.toString();
        }
      } catch (_) {}

      try {
        final teacherRes = await _supabase
            .from('teachers')
            .select('full_name, name')
            .eq('id', widget.teacherId)
            .maybeSingle();
        if (teacherRes != null) {
          teacherName = teacherRes['full_name']?.toString() ??
              teacherRes['name']?.toString() ??
              'المدرس';
        }
      } catch (_) {}

      // ── 2. Upsert daily_reports (avoid duplicates for same student+date) ──

      try {
        final existingReport = await _supabase
            .from('daily_reports')
            .select('id, status')
            .eq('student_id', widget.studentId)
            .eq('teacher_id', widget.teacherId)
            .eq('report_date', todayStr)
            .maybeSingle();

        if (existingReport != null) {
          // Update existing report
          await _supabase.from('daily_reports').update({
            'status': isPresent ? 'present' : 'absent',
            'attendance': isPresent,
            'note': _dailyNoteController.text.trim(),
            'ate_meal': ateMeal,
            'took_break': tookBreak,
            'stars': dailyStars,
          }).eq('id', existingReport['id']);

          // Send absence notification if marked absent
          if (!isPresent && existingReport['status'] != 'absent') {
            await _supabase.from('notifications').insert({
              'student_id': widget.studentId,
              'teacher_id': widget.teacherId,
              'title': 'غياب عن الحصة',
              'body': 'تم تسجيل غيابك في حصة الأستاذ/ة $teacherName.',
            });
          }
        } else {
          // Insert new report
          await _supabase.from('daily_reports').insert({
            'student_id': widget.studentId,
            'teacher_id': widget.teacherId,
            'report_date': todayStr,
            'status': isPresent ? 'present' : 'absent',
            'attendance': isPresent,
            'note': _dailyNoteController.text.trim(),
            'ate_meal': ateMeal,
            'took_break': tookBreak,
            'stars': dailyStars,
          });

          // Send attendance notification (present or absent)
          if (!isPresent) {
            await _supabase.from('notifications').insert({
              'student_id': widget.studentId,
              'teacher_id': widget.teacherId,
              'title': 'غياب عن الحصة',
              'body': 'تم تسجيل غيابك في حصة الأستاذ/ة $teacherName.',
            });
          } else {
            // Send present notification with details
            String notifBody = 'تم تسجيل حضورك في حصة الأستاذ/ة $teacherName ✅';
            if (dailyStars > 0) {
              notifBody += '\n⭐ حصلت على $dailyStars نجوم';
            }
            if (_dailyNoteController.text.trim().isNotEmpty) {
              notifBody += '\n📝 ملاحظة: ${_dailyNoteController.text.trim()}';
            }
            
            await _supabase.from('notifications').insert({
              'student_id': widget.studentId,
              'teacher_id': widget.teacherId,
              'title': 'تسجيل حضور',
              'body': notifBody,
            });
          }
        }
      } catch (e) {
        debugPrint('Error saving daily report: $e');
        rethrow;
      }

      // ── 3. Save teacher attendance (if not already logged today) ──
      try {
        final teacherAttRes = await _supabase
            .from('teacher_attendance')
            .select('id')
            .eq('teacher_id', widget.teacherId)
            .gte('created_at', '${todayStr}T00:00:00Z')
            .lte('created_at', '${todayStr}T23:59:59Z');

        if ((teacherAttRes as List).isEmpty) {
          await _supabase.from('teacher_attendance').insert({
            'teacher_id': widget.teacherId,
            'status': 'present',
          });
        }
      } catch (_) {}

      // ── 4. Save student_reviews (teacher note → appears in student notes tab) ──
      final String noteText = _dailyNoteController.text.trim();
      if (noteText.isNotEmpty) {
        try {
          final existingReview = await _supabase
              .from('student_reviews')
              .select('id')
              .eq('student_id', widget.studentId)
              .eq('teacher_name', teacherName)
              .eq('review_date', todayStr)
              .maybeSingle();

          if (existingReview != null) {
            await _supabase.from('student_reviews').update({
              'teacher_name': teacherName,
              'notes': noteText,
              'behavior_rating': dailyStars >= 4
                  ? 'مميز'
                  : dailyStars >= 3
                      ? 'جيد جداً'
                      : dailyStars >= 2
                          ? 'جيد'
                          : 'يحتاج متابعة',
              if (teacherPhotoUrl != null && teacherPhotoUrl.isNotEmpty)
                'teacher_photo_url': teacherPhotoUrl,
            }).eq('id', existingReview['id']);
          } else {
            await _supabase.from('student_reviews').insert({
              'student_id': widget.studentId,
              'review_date': todayStr,
              'teacher_name': teacherName,
              'notes': noteText,
              'behavior_rating': dailyStars >= 4
                  ? 'مميز'
                  : dailyStars >= 3
                      ? 'جيد جداً'
                      : dailyStars >= 2
                          ? 'جيد'
                          : 'يحتاج متابعة',
              if (teacherPhotoUrl != null && teacherPhotoUrl.isNotEmpty)
                'teacher_photo_url': teacherPhotoUrl,
            });
          }
        } catch (e) {
          debugPrint('Error saving supervisor review: $e');
        }
      }

      // ── 5. Save weekly evaluation ──
      try {
        await _supabase.from('weekly_evaluations').insert({
          'student_id': widget.studentId,
          'teacher_id': widget.teacherId,
          'completed_duties': completedWeeklyDuties,
          'completed_lessons': _completedLessonsController.text.trim(),
          'note': _weeklyNoteController.text.trim(),
        });
      } catch (_) {
        // Table might not exist, ignore
      }

      // ── 6. Send Notification to Student ──
      // The notification is already sent above based on attendance status

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ التقييم وإرسال الإشعار بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error saving evaluation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحفظ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFE6E6FA);
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 160,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: textColor),
          label: Text(
            'عودة للقائمة',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Student Info Header
            CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFEEEEEE),
              backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                  ? NetworkImage(widget.photoUrl!)
                  : null,
              child: widget.photoUrl == null || widget.photoUrl!.isEmpty
                  ? Text(
                      widget.initial,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.studentName,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'الفئة العمرية: ${widget.category}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Teacher Info Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFDDD0F7),
                    backgroundImage: widget.teacherAvatarUrl != null &&
                            widget.teacherAvatarUrl!.isNotEmpty
                        ? NetworkImage(widget.teacherAvatarUrl!)
                        : null,
                    child: widget.teacherAvatarUrl == null ||
                            widget.teacherAvatarUrl!.isEmpty
                        ? Text(
                            widget.teacherName.isNotEmpty
                                ? widget.teacherName[0]
                                : 'م',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teacherName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.teacherSubject,
                        style: const TextStyle(
                          color: Color(0xFF724F96),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF724F96),
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Evaluation Card
            _buildDailyEvaluationCard(textColor: textColor, cardColor: cardColor!),
            
            const SizedBox(height: 24),

            // Weekly Evaluation Card
            _buildWeeklyEvaluationCard(textColor: textColor, cardColor: cardColor),
            
            const SizedBox(height: 32),


            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEvaluation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF724F96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyEvaluationCard({required Color textColor, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'التقييم اليومي',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF724F96),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'تسجيل الحضور:',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Absent Button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isPresent = false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: !isPresent ? Colors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: !isPresent ? Colors.red : const Color(0xFFE5E5EA)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isPresent)
                          const Icon(Icons.close, color: Colors.white, size: 20),
                        if (!isPresent) const SizedBox(width: 8),
                        Text(
                          'غائب',
                          style: TextStyle(
                            color: !isPresent ? Colors.white : textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Present Button
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isPresent = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isPresent ? Colors.green : const Color(0xFFE5E5EA)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isPresent)
                          const Icon(Icons.check, color: Colors.white, size: 20),
                        if (isPresent) const SizedBox(width: 8),
                        Text(
                          'حاضر',
                          style: TextStyle(
                            color: isPresent ? Colors.white : textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _dailyNoteController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'ملاحظة',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                    ),
                    contentPadding: const EdgeInsets.all(8),
                  ),
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('تناول الوجبة', style: TextStyle(fontSize: 12)),
                      Checkbox(
                        value: ateMeal,
                        onChanged: (val) => setState(() => ateMeal = val ?? false),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('أخذ الاستراحة', style: TextStyle(fontSize: 12)),
                      Checkbox(
                        value: tookBreak,
                        onChanged: (val) => setState(() => tookBreak = val ?? false),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'التقييم اليومي:',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < dailyStars ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFCC00),
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    dailyStars = index + 1;
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEvaluationCard({required Color textColor, required Color cardColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'التقييم الأسبوعي',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF724F96),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'نسبة الحضور الأسبوعية: $_weeklyAttendanceRate',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'الدروس المنجزة',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _completedLessonsController,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'مثال: الحروف، الأرقام، ألعاب الذاكرة',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('أكمل الواجبات الأسبوعية', style: TextStyle(fontSize: 12, color: textColor)),
              Checkbox(
                value: completedWeeklyDuties,
                onChanged: (val) => setState(() => completedWeeklyDuties = val ?? false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'ملاحظات الأسبوع',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weeklyNoteController,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'متفوق جدا هذا الأسبوع...',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }


}

