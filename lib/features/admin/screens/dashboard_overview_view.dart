import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardOverviewView extends StatefulWidget {
  final AdminProvider provider;

  const DashboardOverviewView({super.key, required this.provider});

  @override
  State<DashboardOverviewView> createState() => _DashboardOverviewViewState();
}

class _DashboardOverviewViewState extends State<DashboardOverviewView> {
  int _complaintsCount = 0;
  int _unreadComplaints = 0;

  @override
  void initState() {
    super.initState();
    _fetchComplaintsCount();
  }

  Future<void> _fetchComplaintsCount() async {
    try {
      final supabase = Supabase.instance.client;
      
      // عدد إجمالي الشكاوى
      final totalResult = await supabase
          .from('complaints')
          .select('id');
      
      // عدد الشكاوى غير المقروءة
      final unreadResult = await supabase
          .from('complaints')
          .select('id')
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _complaintsCount = (totalResult as List).length;
          _unreadComplaints = (unreadResult as List).length;
        });
      }
    } catch (e) {
      debugPrint('خطأ في جلب عدد الشكاوى: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatCard(title: 'إجمالي الطلاب', count: '${widget.provider.totalStudents}'),
            const SizedBox(width: 16),
            StatCard(title: 'المدرسين', count: '${widget.provider.totalTeachers}'),
            const SizedBox(width: 16),
            StatCard(title: 'نسبة الحضور', count: widget.provider.attendancePercentage),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                // الانتقال لصفحة الشكاوى
                widget.provider.setNavIndex(4);
              },
              child: StatCard(
                title: 'الشكاوى',
                count: '$_complaintsCount',
                subtitle: _unreadComplaints > 0 ? '$_unreadComplaints جديد' : null,
                color: _unreadComplaints > 0 ? Colors.orange : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}