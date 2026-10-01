import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import '../models/weekly_report_model.dart';
import '../models/supervisor_review_model.dart';
import '../../../core/widgets/skeleton_loading.dart';

class StudentNotesTab extends StatefulWidget {
  const StudentNotesTab({super.key});

  @override
  State<StudentNotesTab> createState() => _StudentNotesTabState();
}

class _StudentNotesTabState extends State<StudentNotesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      // When switching to weekly tab, load data
      if (_tabController.index == 1) {
        final provider = context.read<StudentProvider>();
        if (provider.weeklyReports.isEmpty && !provider.isLoadingWeekly) {
          provider.fetchWeeklyReports(
              provider.selectedWeek, provider.selectedYear);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear);
    return ((diff.inDays + startOfYear.weekday) / 7).ceil();
  }

  String _formatDate(DateTime date) {
    const days = [
      'Ø§Ù„Ø§Ø«Ù†ÙŠÙ†', 'Ø§Ù„Ø«Ù„Ø§Ø«Ø§Ø¡', 'Ø§Ù„Ø£Ø±Ø¨Ø¹Ø§Ø¡', 'Ø§Ù„Ø®Ù…ÙŠØ³',
      'Ø§Ù„Ø¬Ù…Ø¹Ø©', 'Ø§Ù„Ø³Ø¨Øª', 'Ø§Ù„Ø£Ø­Ø¯'
    ];
    const months = [
      '', 'ÙŠÙ†Ø§ÙŠØ±', 'ÙØ¨Ø±Ø§ÙŠØ±', 'Ù…Ø§Ø±Ø³', 'Ø£Ø¨Ø±ÙŠÙ„', 'Ù…Ø§ÙŠÙˆ', 'ÙŠÙˆÙ†ÙŠÙˆ',
      'ÙŠÙˆÙ„ÙŠÙˆ', 'Ø£ØºØ³Ø·Ø³', 'Ø³Ø¨ØªÙ…Ø¨Ø±', 'Ø£ÙƒØªÙˆØ¨Ø±', 'Ù†ÙˆÙÙ…Ø¨Ø±', 'Ø¯ÙŠØ³Ù…Ø¨Ø±'
    ];
    final dayName = days[date.weekday - 1];
    return '$dayName ${date.day} ${months[date.month]}';
  }

  String _getWeekDateRange(int week, int year) {
    final startOfYear = DateTime(year, 1, 1);
    final startOfWeek = startOfYear.add(Duration(days: (week - 1) * 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    const months = [
      '', 'ÙŠÙ†Ø§ÙŠØ±', 'ÙØ¨Ø±Ø§ÙŠØ±', 'Ù…Ø§Ø±Ø³', 'Ø£Ø¨Ø±ÙŠÙ„', 'Ù…Ø§ÙŠÙˆ', 'ÙŠÙˆÙ†ÙŠÙˆ',
      'ÙŠÙˆÙ„ÙŠÙˆ', 'Ø£ØºØ³Ø·Ø³', 'Ø³Ø¨ØªÙ…Ø¨Ø±', 'Ø£ÙƒØªÙˆØ¨Ø±', 'Ù†ÙˆÙÙ…Ø¨Ø±', 'Ø¯ÙŠØ³Ù…Ø¨Ø±'
    ];
    return '${startOfWeek.day} ${months[startOfWeek.month]} â€“ ${endOfWeek.day} ${months[endOfWeek.month]}';
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Ù…Ù…ÙŠØ²':
        return Colors.green;
      case 'Ø¬ÙŠØ¯ Ø¬Ø¯Ø§Ù‹':
        return const Color(0xFF724F96);
      case 'Ø¬ÙŠØ¯':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // â”€â”€ Date Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickDate(BuildContext ctx, StudentProvider provider) async {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF724F96),
                    onPrimary: Colors.black,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF724F96),
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.changeDate(picked);
    }
  }

  // â”€â”€ Week Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickWeek(BuildContext ctx, StudentProvider provider) async {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFE6E6FA);

    final int currentWeek = _getWeekNumber(DateTime.now());
    final int currentYear = DateTime.now().year;

    int tempWeek = provider.selectedWeek;
    int tempYear = provider.selectedYear;

    await showModalBottomSheet(
      context: ctx,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ø§Ø®ØªØ± Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Year row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: const Color(0xFF724F96),
                        onPressed: () =>
                            setModalState(() => tempYear--),
                      ),
                      Text(
                        '$tempYear',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: tempYear >= currentYear
                            ? Colors.grey
                            : const Color(0xFF724F96),
                        onPressed: tempYear >= currentYear
                            ? null
                            : () => setModalState(() => tempYear++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Week row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        color: tempWeek <= 1 ? Colors.grey : const Color(0xFF724F96),
                        onPressed: tempWeek <= 1
                            ? null
                            : () => setModalState(() => tempWeek--),
                      ),
                      Column(
                        children: [
                          Text(
                            'Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹ $tempWeek',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getWeekDateRange(tempWeek, tempYear),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        color: (tempYear >= currentYear && tempWeek >= currentWeek)
                            ? Colors.grey
                            : const Color(0xFF724F96),
                        onPressed: (tempYear >= currentYear && tempWeek >= currentWeek)
                            ? null
                            : () => setModalState(() => tempWeek++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      provider.changeWeek(tempWeek, tempYear);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF724F96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ø¹Ø±Ø¶ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…Ø§Øª',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final tabBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE6E6FA);

    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Ø§Ù„ØªÙ‚ÙŠÙŠÙ…Ø§Øª',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // â”€â”€ Tab Bar â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: tabBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF724F96),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF724F96).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: textColor.withValues(alpha: 0.5),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'يومية'),
                    Tab(text: 'أسبوعية'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // â”€â”€ Tab Views â”€â”€
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DailyView(
                    onPickDate: _pickDate,
                    formatDate: _formatDate,
                    ratingColor: _ratingColor,
                    textColor: textColor,
                    cardColor: cardColor,
                    isDark: isDark,
                  ),
                  _WeeklyView(
                    onPickWeek: _pickWeek,
                    getWeekDateRange: _getWeekDateRange,
                    textColor: textColor,
                    cardColor: cardColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// DAILY VIEW
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _DailyView extends StatelessWidget {
  final Future<void> Function(BuildContext, StudentProvider) onPickDate;
  final String Function(DateTime) formatDate;
  final Color Function(String) ratingColor;
  final Color textColor;
  final Color cardColor;
  final bool isDark;

  const _DailyView({
    required this.onPickDate,
    required this.formatDate,
    required this.ratingColor,
    required this.textColor,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final dailyReports = provider.dailyReports;
    final reviews = provider.todayReviews;
    final selectedDate = provider.selectedDate;
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    final hasContent = dailyReports.isNotEmpty || reviews.isNotEmpty;
    
    final Set<String> dailyNotes = dailyReports.map((e) => e.note?.trim() ?? '').where((e) => e.isNotEmpty).toSet();
    final filteredReviews = reviews.where((r) => !dailyNotes.contains(r.notes.trim())).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Date Picker Card â”€â”€
          GestureDetector(
            onTap: () => onPickDate(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF724F96),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF724F96).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'ØªØºÙŠÙŠØ±',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isToday ? 'اليوم' : 'تاريخ محدد',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        formatDate(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: provider.isLoading
                ? const SkeletonListLoading(itemCount: 5)
                : !hasContent
                    ? _buildEmpty(textColor)
                    : ListView(
                        children: [
                          // â”€â”€ Daily Stars Cards â”€â”€
                          ...dailyReports.map((daily) => _buildDailyStarsCard(
                                stars: daily.stars,
                                isPresent: daily.isPresent,
                                ateMeal: daily.mealEaten,
                                tookBreak: daily.breakTaken,
                                note: daily.note,
                                teacherName: daily.teacherName,
                                teacherPhotoUrl: daily.teacherPhotoUrl,
                                subject: daily.subject,
                                textColor: textColor,
                                cardColor: cardColor,
                                isDark: isDark,
                              )),

                          // â”€â”€ Supervisor Reviews â”€â”€
                          ...filteredReviews.map((review) => _buildReviewCard(
                                review: review,
                                textColor: textColor,
                                cardColor: cardColor,
                                isDark: isDark,
                                ratingColor: ratingColor,
                              )),

                          const SizedBox(height: 20),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Ù„Ø§ ÙŠÙˆØ¬Ø¯ ØªÙ‚ÙŠÙŠÙ…Ø§Øª Ù„Ù‡Ø°Ø§ اليوم',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر يوماً آخر لعرض التقييمات',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStarsCard({
    required int stars,
    required bool isPresent,
    required bool ateMeal,
    required bool tookBreak,
    required String? note,
    String? teacherName,
    String? teacherPhotoUrl,
    String? subject,
    required Color textColor,
    required Color cardColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Teacher Info Header
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      teacherName ?? 'المدرس',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subject != null && subject.isNotEmpty)
                      Text(
                        subject,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildTeacherAvatar(
                name: teacherName,
                photoUrl: teacherPhotoUrl,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 12),

          // Attendance & Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Attendance badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPresent
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.red.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPresent
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isPresent ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPresent ? 'Ø­Ø§Ø¶Ø±' : 'ØºØ§Ø¦Ø¨',
                      style: TextStyle(
                        color: isPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Row(
                children: [
                  Text(
                    'Ø§Ù„ØªÙ‚ÙŠÙŠÙ… اليومÙŠ',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Color(0xFFFFCC00), size: 22),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stars row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: i < stars
                    ? const Color(0xFFFFCC00)
                    : Colors.grey.shade300,
                size: 36,
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              stars == 0
                  ? 'Ù„Ù… ÙŠØªÙ… Ø§Ù„ØªÙ‚ÙŠÙŠÙ… Ø¨Ø¹Ø¯'
                  : '$stars Ù…Ù† Ù¥ ${_starsLabel(stars)}',
              style: TextStyle(
                color: stars == 0 ? Colors.grey : const Color(0xFFFFCC00),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 10),

          // Meal & Break row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _iconChip(
                icon: tookBreak ? Icons.check_circle : Icons.cancel,
                label: 'Ø§Ù„Ø§Ø³ØªØ±Ø§Ø­Ø©',
                active: tookBreak,
              ),
              Container(
                  width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.3)),
              _iconChip(
                icon: ateMeal ? Icons.check_circle : Icons.cancel,
                label: 'Ø§Ù„ÙˆØ¬Ø¨Ø©',
                active: ateMeal,
              ),
            ],
          ),

          if (note != null && note.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE6E6FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF724F96).withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      note,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13, color: textColor, height: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.notes_rounded,
                      size: 16, color: Color(0xFF724F96)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconChip(
      {required IconData icon, required String label, required bool active}) {
    return Row(
      children: [
        Icon(
          icon,
          color: active ? Colors.green : Colors.grey.shade400,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  String _starsLabel(int stars) {
    switch (stars) {
      case 1:
        return 'â­';
      case 2:
        return 'â­â­';
      case 3:
        return 'â­â­â­';
      case 4:
        return 'â­â­â­â­';
      case 5:
        return 'â­â­â­â­â­ Ù…Ù…ÙŠØ²!';
      default:
        return '';
    }
  }

  Widget _buildReviewCard({
    required SupervisorReviewModel review,
    required Color textColor,
    required Color cardColor,
    required bool isDark,
    required Color Function(String) ratingColor,
  }) {
    final badgeColor = ratingColor(review.behaviorRating);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  review.behaviorRating,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              // Teacher & Subject
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        review.subject,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Ø£. ${review.teacherName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                    backgroundImage: (review.teacherPhotoUrl != null && review.teacherPhotoUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(review.teacherPhotoUrl!)
                        : null,
                    child: (review.teacherPhotoUrl == null || review.teacherPhotoUrl!.isEmpty)
                        ? Icon(Icons.person_rounded, color: textColor, size: 20)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          if (review.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              review.notes,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: textColor, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a coloured avatar circle for a teacher
  Widget _buildTeacherAvatar({String? name, String? photoUrl}) {
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final String initial = (name != null && name.isNotEmpty) ? name.trim()[0] : 'Ù…';

    // Pick a consistent colour based on the initial
    final List<List<Color>> palettes = [
      [const Color(0xFF6B4EFF), const Color(0xFF9B6BFF)],
      [const Color(0xFF724F96), const Color(0xFF34AADC)],
      [const Color(0xFF34C759), const Color(0xFF30D158)],
      [const Color(0xFFFF9500), const Color(0xFFFFCC00)],
      [const Color(0xFFFF2D55), const Color(0xFFFF6B81)],
      [const Color(0xFF5AC8FA), const Color(0xFF724F96)],
      [const Color(0xFFAF52DE), const Color(0xFFDA8FFF)],
    ];
    final colors = palettes[initial.codeUnitAt(0) % palettes.length];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: hasPhoto
          ? ClipOval(child: CachedNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover, width: 44, height: 44))
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WEEKLY VIEW
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _WeeklyView extends StatelessWidget {
  final Future<void> Function(BuildContext, StudentProvider) onPickWeek;
  final String Function(int week, int year) getWeekDateRange;
  final Color textColor;
  final Color cardColor;
  final bool isDark;

  const _WeeklyView({
    required this.onPickWeek,
    required this.getWeekDateRange,
    required this.textColor,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final reports = provider.weeklyReports;
    final week = provider.selectedWeek;
    final year = provider.selectedYear;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // â”€â”€ Week Picker Card â”€â”€
          GestureDetector(
            onTap: () => onPickWeek(context, provider),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B4EFF), Color(0xFF9B6BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.date_range_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'ØªØºÙŠÙŠØ±',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ø§Ù„Ø£Ø³Ø¨ÙˆØ¹ $week - $year',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        getWeekDateRange(week, year),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: provider.isLoadingWeekly
                ? const SkeletonListLoading(itemCount: 4)
                : reports.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        itemCount: reports.length,
                        itemBuilder: (ctx, i) =>
                            _buildWeeklyCard(reports[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_week_rounded,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Ù„Ø§ ÙŠÙˆØ¬Ø¯ ØªÙ‚ÙŠÙŠÙ…Ø§Øª أسبوعية',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ø§Ø®ØªØ± Ø£Ø³Ø¨ÙˆØ¹Ø§Ù‹ Ø¢Ø®Ø± Ù„Ø¹Ø±Ø¶ Ø§Ù„ØªÙ‚ÙŠÙŠÙ…Ø§Øª',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(WeeklyReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Teacher Info Header
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      report.teacherName ?? 'المدرس',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (report.subject != null && report.subject!.isNotEmpty)
                      Text(
                        report.subject!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildTeacherAvatar(
                name: report.teacherName,
                photoUrl: report.teacherPhotoUrl,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Duties badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: report.completedDuties
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: report.completedDuties
                        ? Colors.green.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      report.completedDuties
                          ? Icons.task_alt_rounded
                          : Icons.pending_rounded,
                      color: report.completedDuties
                          ? Colors.green
                          : Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      report.completedDuties
                          ? 'Ø£ØªÙ… Ø§Ù„ÙˆØ§Ø¬Ø¨Ø§Øª'
                          : 'Ù„Ù… ÙŠØªÙ… Ø§Ù„ÙˆØ§Ø¬Ø¨Ø§Øª',
                      style: TextStyle(
                        color: report.completedDuties
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Row(
                children: [
                  Text(
                    'ØªÙ‚Ø±ÙŠØ± Ø£Ø³Ø¨ÙˆØ¹ÙŠ',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4EFF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_view_week_rounded,
                        color: Color(0xFF6B4EFF), size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 10),

          // Completed lessons
          if (report.completedLessons.isNotEmpty &&
              report.completedLessons != 'Ù„Ø§ ÙŠÙˆØ¬Ø¯') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    report.completedLessons,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13, color: textColor, height: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book_rounded,
                    size: 16, color: Color(0xFF6B4EFF)),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Note
          if (report.note.isNotEmpty && report.note != 'Ù„Ø§ ÙŠÙˆØ¬Ø¯')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6B4EFF).withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      report.note,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 13, color: textColor, height: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.notes_rounded,
                      size: 16, color: Color(0xFF6B4EFF)),
                ],
              ),
            ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatReportDate(report.createdAt),
              style:
                  const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReportDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Builds a coloured avatar circle for a teacher
  Widget _buildTeacherAvatar({String? name, String? photoUrl}) {
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final String initial = (name != null && name.isNotEmpty) ? name.trim()[0] : 'Ù…';

    final List<List<Color>> palettes = [
      [const Color(0xFF6B4EFF), const Color(0xFF9B6BFF)],
      [const Color(0xFF724F96), const Color(0xFF34AADC)],
      [const Color(0xFF34C759), const Color(0xFF30D158)],
      [const Color(0xFFFF9500), const Color(0xFFFFCC00)],
      [const Color(0xFFFF2D55), const Color(0xFFFF6B81)],
      [const Color(0xFF5AC8FA), const Color(0xFF724F96)],
      [const Color(0xFFAF52DE), const Color(0xFFDA8FFF)],
    ];
    final colors = palettes[initial.codeUnitAt(0) % palettes.length];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: hasPhoto
          ? ClipOval(
              child: CachedNetworkImage(imageUrl: photoUrl!,
                  fit: BoxFit.cover, width: 44, height: 44))
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
    );
  }
}

