import 'package:flutter/material.dart';
import '../../auth/screens/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      topText: 'أهلاً بك',
      bottomText: null,
      bottomSubText: null,
      imagePath: 'assets/images/onboard-1.png',
      isCircleImage: false,
    ),
    _OnboardingData(
      topText: 'حضانة سمارت',
      bottomText: null,
      bottomSubText: null,
      imagePath: 'assets/images/onboard-2.png',
      isCircleImage: true,
    ),
    _OnboardingData(
      topText: null,
      bottomText: 'ابنك معانا هيتعلم و ينمو',
      bottomSubText: 'و هنحافظ على نشاطه',
      imagePath: 'assets/images/onboard-3.png',
      isCircleImage: true,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Logo
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Text(
                  'SMART',
                  style: TextStyle(
                    color: Color(0xFF2A1B38),
                    fontSize: 45,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'smart_font',
                    letterSpacing: 2,
                  ),
                ),
                Positioned(
                  top: -15,
                  right: -60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: const Color(0xFF9B6BFF),
                        size: 120,
                      ),
                      const Text(
                        'SMART',
                        style: TextStyle(
                          color: Color(0xFF2A1B38),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'smart_font',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageWidget(data: _pages[index]);
                },
              ),
            ),
            // Next Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF724F96),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'next',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String? topText;
  final String? bottomText;
  final String? bottomSubText;
  final String imagePath;
  final bool isCircleImage;

  _OnboardingData({
    this.topText,
    this.bottomText,
    this.bottomSubText,
    required this.imagePath,
    required this.isCircleImage,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPageWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data.topText != null) ...[
            Text(
              data.topText!,
              style: const TextStyle(
                color: Color(0xFF2A1B38),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Raw Image Display
          Image.asset(
            data.imagePath,
            width: 320,
            height: 320,
            fit: BoxFit.contain,
          ),

          if (data.bottomText != null) ...[
            const SizedBox(height: 30),
            Text(
              data.bottomText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2A1B38),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (data.bottomSubText != null) ...[
              const SizedBox(height: 8),
              Text(
                data.bottomSubText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2A1B38),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
