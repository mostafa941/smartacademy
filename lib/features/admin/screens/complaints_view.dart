import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';
import '../../../core/widgets/skeleton_loading.dart';

class ComplaintsView extends StatefulWidget {
  final AdminProvider provider;
  const ComplaintsView({super.key, required this.provider});

  @override
  State<ComplaintsView> createState() => _ComplaintsViewState();
}

class _ComplaintsViewState extends State<ComplaintsView> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('complaints')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _complaints = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب الشكاوي: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SkeletonListLoading();
    }

    if (_complaints.isEmpty) {
      return const Center(
        child: Text('لا توجد شكاوي حالياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'قائمة الشكاوي والمساعدة',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _complaints.length,
              itemBuilder: (context, index) {
                final item = _complaints[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item['name'] ?? 'بدون اسم',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('رقم الهاتف: ${item['phone'] ?? 'غير متوفر'}', style: const TextStyle(color: Colors.blueGrey)),
                        const SizedBox(height: 8),
                        Text(
                          'الشكوى: ${item['complaint'] ?? ''}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.report_problem, color: Colors.orange),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
