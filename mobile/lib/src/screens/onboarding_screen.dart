import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_dashboard.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Real-Time Voice Studio',
      'description': 'Transform your voice with ultra low-latency C++17 DSP pitch shifting, robot vocoder, and echo chamber effects.',
      'icon': Icons.tune_rounded,
      'color': const Color(0xFF25D366),
    },
    {
      'title': 'WhatsApp Voice Memos',
      'description': 'Record your transformed voice and send high-fidelity Opus audio notes directly to any WhatsApp conversation with a single tap.',
      'icon': Icons.send_rounded,
      'color': const Color(0xFF00B4D8),
    },
    {
      'title': 'Hardware & Route Diagnostics',
      'description': 'Live audio level VU metering, Bluetooth SCO diagnostics, buffer latency monitoring, and zero-knowledge privacy guarantees.',
      'icon': Icons.security_rounded,
      'color': const Color(0xFF7C5CFC),
    },
  ];

  Future<void> _requestPermissionsAndProceed() async {
    await Permission.microphone.request();
    await Permission.notification.request();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _requestPermissionsAndProceed,
                  child: const Text('SKIP', style: TextStyle(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, idx) {
                    final page = _pages[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: (page['color'] as Color).withOpacity(0.4), width: 2),
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 54,
                            color: page['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page['title'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? const Color(0xFF25D366) : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _requestPermissionsAndProceed();
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'GET STARTED' : 'CONTINUE',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
