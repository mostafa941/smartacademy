import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';

class DateFilterWidget extends StatelessWidget {
  const DateFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2A1B38);
    final searchBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final provider = context.watch<StudentProvider>();
    final selectedDate = provider.selectedDate;

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? const ColorScheme.dark(
                        primary: Color(0xFF724F96),
                        onPrimary: Colors.black,
                        onSurface: Colors.white,
                      )
                    : const ColorScheme.light(
                        primary: Color(0xFF2A1B38),
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != selectedDate) {
          provider.changeDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: searchBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.calendar_month_rounded, color: textColor, size: 22),
            Text(
              '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
