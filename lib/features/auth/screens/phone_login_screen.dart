import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import '../services/session_service.dart';
import '../widgets/complaint_dialog.dart';

class PhoneLoginScreen extends StatefulWidget {
  final String role; // 'teacher' or 'student'

  const PhoneLoginScreen({super.key, required this.role});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String get _roleLabel => widget.role == 'teacher' ? 'المدرس' : 'الطالب';
  String get _phoneLabel =>
      widget.role == 'teacher' ? 'ادخل رقم الهاتف' : 'ادخل رقم هاتف ولي الأمر';
  String get _phoneHint => 'ex: 01000000000';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phone = _phoneController.text.trim();

    try {
      final supabase = Supabase.instance.client;

      String userId = '';
      String userName = '';
      bool found = false;

      if (widget.role == 'teacher') {
        // المدرس: البحث في جدول profiles برقم هاتفه
        final List<dynamic> result = await supabase
            .from('profiles')
            .select()
            .eq('phone', phone)
            .eq('role', 'teacher')
            .limit(1);

        if (result.isNotEmpty) {
          found = true;
          userId = result.first['id'].toString();
          userName = result.first['full_name'] ?? 'مدرس';
        }
      } else {
        // الطالب: البحث في جدول students برقم هاتف ولي الأمر
        final List<dynamic> result = await supabase
            .from('students')
            .select()
            .eq('parent_phone', phone)
            .limit(1);

        if (result.isNotEmpty) {
          found = true;
          userId = result.first['id'].toString();
          userName = result.first['full_name'] ?? 'طالب';
        }
      }

      if (!mounted) return;

      if (!found) {
        _showError(widget.role == 'teacher'
            ? 'رقم الهاتف غير مسجل كمدرس في النظام'
            : 'رقم هاتف ولي الأمر غير موجود في النظام');
      } else {
        // حفظ بيانات الجلسة لتذكر المستخدم في المرة القادمة
        await SessionService.saveSession(
          userId: userId,
          userName: userName,
          role: widget.role,
          phone: phone,
        );

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userId: userId,
              userName: userName,
              role: widget.role,
            ),
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      _showError('خطأ في الاتصال: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _showError('حدث خطأ غير متوقع، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // زر الرجوع
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                    ),
                    child: const Icon(Icons.arrow_back, size: 25),
                  ),
                ),

                const SizedBox(height: 20),

                // SMART Logo
                const Text(
                  'SMART',
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'smart_font',
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 28),

                // Welcome text
                const Text(
                  'أهلاً بك في حضانة سمارت الذكي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'من فضلك ادخل رقم هاتفك للبدء :',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 50),

                // Phone label
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _phoneLabel,
                    style: const TextStyle(
                      color: Color(0xFF2A1B38),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Phone input
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2A1B38),
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      hintText: _phoneHint,
                      hintStyle: TextStyle(
                        color: const Color(0xFF2A1B38).withOpacity(0.4),
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF724F96),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'الرجاء إدخال رقم الهاتف';
                      }
                      if (val.trim().length < 10) {
                        return 'رقم الهاتف يجب أن يكون 10 أرقام على الأقل';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 36),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF724F96),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor:
                          const Color(0xFF724F96).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Help text
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
      ),
    );
  }
}
