import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'emoji': '🍌',
      'title': 'Selamat Datang di BanaSnap',
      'desc':
          'Aplikasi AI cerdas untuk mendeteksi apakah pisang Anda masih segar atau sudah busuk. Cukup 1 detik!'
    },
    {
      'emoji': '☀️',
      'title': 'Cahaya yang Tepat',
      'desc':
          'Pastikan foto pisang diambil di tempat yang terang. Hindari bayangan pekat yang menutupi kulit pisang.'
    },
    {
      'emoji': '📏',
      'title': 'Jarak dan Fokus',
      'desc':
          'Posisikan pisang di tengah layar. Jangan terlalu jauh atau terlalu dekat, pastikan seluruh bagian pisang terlihat jelas.'
    },
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgCream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text('Lewati',
                    style: TextStyle(
                        color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.yellowDark.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(_pages[i]['emoji']!,
                                style: const TextStyle(fontSize: 64)),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          _pages[i]['title']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 26,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[i]['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textGrey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == i ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppTheme.yellowDark
                              : AppTheme.yellow.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: AppTheme.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.check
                          : Icons.arrow_forward_ios_rounded,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
