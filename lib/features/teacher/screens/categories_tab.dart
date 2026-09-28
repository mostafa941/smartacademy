import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/skeleton_loading.dart';

class CategoriesTab extends StatefulWidget {
  final String userId;
  final Function(String?) onCategorySelected;

  const CategoriesTab({
    super.key,
    required this.userId,
    required this.onCategorySelected,
  });

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<String> _stages = [];

  @override
  void initState() {
    super.initState();
    _fetchStages();
  }

  Future<void> _fetchStages() async {
    try {
      final stagesRes = await _supabase
          .from('teacher_stages')
          .select('stages(name)')
          .eq('teacher_id', widget.userId);

      final List<String> fetchedStages = (stagesRes as List)
          .map((e) => e['stages']?['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _stages = fetchedStages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching stages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);

    if (_isLoading) {
      return const SkeletonListLoading(itemCount: 4);
    }

    if (_stages.isEmpty) {
      return Center(
        child: Text(
          'لا توجد فئات مرتبطة بحسابك',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الفئات العمرية التي تدرسها',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _stages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryCard(
                    title: 'جميع الفئات',
                    icon: Icons.all_inclusive,
                    onTap: () => widget.onCategorySelected(null),
                    isDark: isDark,
                    textColor: textColor,
                  );
                }
                final stage = _stages[index - 1];
                return _buildCategoryCard(
                  title: stage,
                  icon: Icons.people_alt,
                  onTap: () => widget.onCategorySelected(stage),
                  isDark: isDark,
                  textColor: textColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
  }) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Arrow on the left (LTR left = RTL right visually after Directionality)
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF724F96).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF724F96)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
