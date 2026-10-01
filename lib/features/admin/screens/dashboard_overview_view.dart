import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';
import '../constants/app_strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardOverviewView extends StatefulWidget {
  final AdminProvider provider;

  const DashboardOverviewView({super.key, required this.provider});

  @override
  State<DashboardOverviewView> createState() => _DashboardOverviewViewState();
}

class _DashboardOverviewViewState extends State<DashboardOverviewView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 768;
          final isTablet = constraints.maxWidth > 600;
          
          return StreamBuilder<List<dynamic>>(
            stream: Supabase.instance.client
                .from('complaints')
                .stream(primaryKey: ['id']),
            builder: (context, complaintsSnapshot) {
              final totalComplaints = complaintsSnapshot.hasData ? complaintsSnapshot.data!.length : 0;
              
              return StreamBuilder<List<dynamic>>(
                stream: Supabase.instance.client
                    .from('complaints')
                    .stream(primaryKey: ['id'])
                    .eq('is_read', false),
                builder: (context, unreadSnapshot) {
                  final unreadComplaints = unreadSnapshot.hasData ? unreadSnapshot.data!.length : 0;
                  
                  if (isDesktop) {
                    // Desktop Layout - 4 cards in a row
                    return Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatCard(title: AppStrings.totalStudents, count: '${widget.provider.totalStudents}'),
                          const SizedBox(width: 16),
                          StatCard(title: AppStrings.totalTeachers, count: '${widget.provider.totalTeachers}'),
                          const SizedBox(width: 16),
                          StatCard(title: AppStrings.attendanceRate, count: widget.provider.attendancePercentage),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => widget.provider.setNavIndex(4),
                            child: StatCard(
                              title: AppStrings.complaintsCount,
                              count: '$totalComplaints',
                              subtitle: unreadComplaints > 0 ? '$unreadComplaints ${AppStrings.newComplaint}' : null,
                              color: unreadComplaints > 0 ? Colors.orange : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (isTablet) {
                    // Tablet Layout - 2x2 grid
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: StatCard(title: AppStrings.totalStudents, count: '${widget.provider.totalStudents}')),
                            const SizedBox(width: 16),
                            Expanded(child: StatCard(title: AppStrings.totalTeachers, count: '${widget.provider.totalTeachers}')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: StatCard(title: AppStrings.attendanceRate, count: widget.provider.attendancePercentage)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => widget.provider.setNavIndex(4),
                                child: StatCard(
                                  title: AppStrings.complaintsCount,
                                  count: '$totalComplaints',
                                  subtitle: unreadComplaints > 0 ? '$unreadComplaints ${AppStrings.newComplaint}' : null,
                                  color: unreadComplaints > 0 ? Colors.orange : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Mobile Layout - Single column
                    return Column(
                      children: [
                        StatCard(title: AppStrings.totalStudents, count: '${widget.provider.totalStudents}'),
                        const SizedBox(height: 16),
                        StatCard(title: AppStrings.totalTeachers, count: '${widget.provider.totalTeachers}'),
                        const SizedBox(height: 16),
                        StatCard(title: AppStrings.attendanceRate, count: widget.provider.attendancePercentage),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => widget.provider.setNavIndex(4),
                          child: StatCard(
                            title: AppStrings.complaintsCount,
                            count: '$totalComplaints',
                            subtitle: unreadComplaints > 0 ? '$unreadComplaints ${AppStrings.newComplaint}' : null,
                            color: unreadComplaints > 0 ? Colors.orange : null,
                          ),
                        ),
                      ],
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}