import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';

class HeaderWidget extends StatelessWidget {
  final AdminProvider provider;
  final String todayDate;

  const HeaderWidget({
    super.key,
    required this.provider,
    required this.todayDate,
  });

  String _getTitleByIndex(int index) {
    switch (index) {
      case 0:
        return 'لوحة التحكم الرئيسية';
      case 1:
        return 'إدارة الطلاب';
      case 2:
        return 'إدارة المدرسين';
      case 3:
        return 'الإعدادات';
      default:
        return 'لوحة التحكم';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTitleByIndex(provider.selectedNavIndex),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'التاريخ: $todayDate',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}