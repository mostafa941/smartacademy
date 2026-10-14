import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';

class TeacherEvaluationsModal extends StatefulWidget {
  final AdminProvider provider;
  final dynamic studentId;
  final String studentName;

  const TeacherEvaluationsModal({
    super.key,
    required this.provider,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<TeacherEvaluationsModal> createState() => _TeacherEvaluationsModalState();
}

class _TeacherEvaluationsModalState extends State<TeacherEvaluationsModal> {
  bool _isLoading = false;
  late List<Map<String, dynamic>> _evaluations;

  @override
  void initState() {
    super.initState();
    _evaluations = widget.provider.getStudentTeacherEvaluations(widget.studentId);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('daily_reports')
          .select('''
            *,
            profiles:teacher_id (
              id,
              full_name,
              avatar_url,
              teacher_subjects (
                subjects ( name )
              )
            )
          ''')
          .eq('student_id', widget.studentId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> list = [];
      for (final r in (res as List)) {
        final profile = r['profiles'] as Map<String, dynamic>? ?? {};
        final String teacherName = profile['full_name'] ?? 'مدرس غير محدد';
        final String? avatarUrl = profile['avatar_url'];
        final subjectsList = profile['teacher_subjects'] as List? ?? [];
        final List<String> subjectNames = subjectsList
            .map((s) => s['subjects']?['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        final String subject = subjectNames.isNotEmpty ? subjectNames.join(', ') : 'غير محدد';
        final String note = (r['note'] ?? '').toString().trim();
        final int stars = r['stars'] is int
            ? r['stars']
            : int.tryParse(r['stars']?.toString() ?? '0') ?? 0;
        final String date = (r['report_date'] ?? r['date'] ?? r['created_at'] ?? '')
            .toString()
            .split('T')
            .first;
        final bool isPresent = r['attendance'] == true || r['status'] == 'present';

        list.add({
          'report_id': r['id'],
          'teacher_id': r['teacher_id'],
          'teacher_name': teacherName,
          'teacher_avatar': avatarUrl,
          'subject': subject,
          'note': note.isNotEmpty ? note : 'بدون ملاحظات',
          'stars': stars,
          'date': date,
          'is_present': isPresent,
          'ate_meal': r['ate_meal'],
          'took_break': r['took_break'],
          'raw': r,
        });
      }

      if (mounted) {
        setState(() {
          _evaluations = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching evaluations in modal: $e');
      if (mounted) {
        final fallback = await widget.provider.fetchStudentEvaluations(widget.studentId);
        if (mounted) {
          setState(() {
            _evaluations = fallback;
            _isLoading = false;
          });
        }
      }
    }
  }

  Color _getAvatarBgColor(String name) {
    final colors = [
      const Color(0xFF724F96),
      const Color(0xFF4A6572),
      const Color(0xFF2E7D32),
      const Color(0xFFD84315),
      const Color(0xFF00838F),
      const Color(0xFF6A1B9A),
      const Color(0xFF1565C0),
    ];
    if (name.isEmpty) return colors.first;
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 10,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 650,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF724F96),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'تقييمات وملاحظات المدرسين',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'للطالب: ${widget.studentName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Loading Bar ──
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFEADBFA),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF724F96)),
                minHeight: 3,
              ),

            // ── Content ──
            Flexible(
              child: _evaluations.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      shrinkWrap: true,
                      itemCount: _evaluations.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildEvaluationCard(_evaluations[index]);
                      },
                    ),
            ),

            // ── Footer ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إجمالي التقييمات: ${_evaluations.length}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF724F96),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'لا توجد تقييمات مسجلة حتى الآن',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'عندما يقوم المدرسون بتقييم هذا الطالب في الحصص ستظهر ملاحظاتهم وموادهم هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(Map<String, dynamic> eval) {
    final String teacherName = eval['teacher_name'] ?? 'مدرس غير محدد';
    final String initial = teacherName.trim().isNotEmpty ? teacherName.trim()[0] : 'م';
    final String? avatarUrl = eval['teacher_avatar'];
    final String subject = eval['subject'] ?? 'غير محدد';
    final String note = eval['note'] ?? '';
    final int stars = eval['stars'] ?? 0;
    final String date = eval['date'] ?? '';
    final bool isPresent = eval['is_present'] == true;
    final bool? ateMeal = eval['ate_meal'];
    final bool? tookBreak = eval['took_break'];

    final Color avatarBg = _getAvatarBgColor(teacherName);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Teacher Avatar + Name + Subject + Date + Attendance ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: Status badge & Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPresent ? Colors.green.shade300 : Colors.red.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 13,
                          color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPresent ? 'حاضر' : 'غائب',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const Spacer(),

              // Right side: Teacher Info & Circle Avatar
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            teacherName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subject badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF724F96).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF724F96).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF724F96)),
                                const SizedBox(width: 4),
                                Text(
                                  'المادة: $subject',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF724F96),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Teacher Photo or Initial inside a Circle Avatar
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: avatarBg,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Row 2: Star Rating & Activity Chips ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Extra activity chips
              Row(
                children: [
                  if (ateMeal == true)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant, size: 12, color: Colors.orange.shade800),
                          const SizedBox(width: 3),
                          Text('تناول الوجبة', style: TextStyle(fontSize: 10, color: Colors.orange.shade800)),
                        ],
                      ),
                    ),
                  if (tookBreak == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee, size: 12, color: Colors.blue.shade800),
                          const SizedBox(width: 3),
                          Text('استراحة', style: TextStyle(fontSize: 10, color: Colors.blue.shade800)),
                        ],
                      ),
                    ),
                ],
              ),

              // Star Rating
              Row(
                children: [
                  Text(
                    stars > 0 ? '$stars / 5' : 'بدون تقييم نجوم',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stars > 0 ? Colors.amber.shade900 : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: List.generate(5, (starIdx) {
                      final bool isFilled = starIdx < stars;
                      return Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFilled ? Colors.amber : Colors.grey.shade300,
                        size: 18,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 3: Teacher Note Bubble ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBFA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  size: 18,
                  color: Color(0xFF724F96),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.isNotEmpty ? note : 'لا توجد ملاحظات إضافية من المدرس.',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: note.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: note.isNotEmpty ? Colors.black87 : Colors.grey.shade600,
                      fontStyle: note.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
