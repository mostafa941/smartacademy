import 'package:flutter/material.dart';
import 'phone_login_screen.dart';
import '../widgets/complaint_dialog.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _confirmSelection() {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار دور للبدء', textAlign: TextAlign.center),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhoneLoginScreen(role: _selectedRole!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6E6FA),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: const Color(0xFFE6E6FA),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // زر الرجوع
            
          
              // Header Logo
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Text(
                    'SMART',
                    style: TextStyle(
                      color: Color(0xFF2A1B38),
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'smart_font',
                      letterSpacing: 2,
                    ),
                  ),
                  Positioned(
                    top: -30,
                    right: -55,
                    child: Transform.rotate(
                      angle: 0.25,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFF724F96),
                            size: 65,
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: const Text(
                              'SMART',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'أهلاً بك في حضانة سمارت اكاديمي',
                style: TextStyle(
                  color: Color(0xFF2A1B38),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'من فضلك اختر دورك للبدء :',
                style: TextStyle(
                  color: Color(0xFF2A1B38),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              
              // Grid of roles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: [
                    _RoleCard(
                      title: 'مدرس',
                      subtitle: 'لإدارة الصفوف و المناهج',
                      imagePath: 'assets/images/teacher_img.png',
                      backgroundColor: const Color(0xFFC0F4A4),
                      isSelected: _selectedRole == 'teacher',
                      onTap: () => _onRoleSelected('teacher'),
                    ),
                    _RoleCard(
                      title: 'طالب/طالبة',
                      subtitle: 'للوصول الى المدرس و الانشطة',
                      imagePath: 'assets/images/student_img.png',
                      backgroundColor: const Color(0xFFDECAAE),
                      isSelected: _selectedRole == 'student',
                      onTap: () => _onRoleSelected('student'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Confirm Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF724F96),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'تأكيد الاختيار',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Help Text
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ComplaintDialog(),
                  );
                },
                child: const Text(
                  'تحتاج مساعدة ؟',
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A1B38) : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2A1B38).withAlpha(51),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported_rounded,
                size: 56,
                color: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2A1B38),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2A1B38),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
