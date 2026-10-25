import 'package:flutter/material.dart';

class CompatibilityWarningScreen extends StatelessWidget {
  const CompatibilityWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1218),
        title: const Text('Technical Transparency', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF271B14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.amber.shade600),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded, size: 28, color: Colors.amber.shade400),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Android Security & Audio Isolation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Standard Android devices strictly isolate audio capture between applications. '
                    'Third-party applications like WhatsApp capture directly from the device physical microphone hardware. '
                    'Android OS security boundaries and AudioPolicyManager prevent any unprivileged app from hijacking or replacing another app’s microphone input in real time.',
                    style: TextStyle(fontSize: 13, color: Colors.amber.shade100, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What Works Real-Time vs What Is Isolated',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 14),
            _buildFeatureComparison(
              'WhatsApp Voice Memos & Audio Notes',
              'Transformed audio is encoded in high-quality Opus and exported directly into WhatsApp conversations.',
              true,
            ),
            _buildFeatureComparison(
              'Local Voice Monitoring & Preview',
              'Real-time low-latency (<30ms) C++17 DSP through headphones or external speakers.',
              true,
            ),
            _buildFeatureComparison(
              'App-Owned VoIP Calling',
              'Full live real-time voice changer calls between users inside the application.',
              true,
            ),
            _buildFeatureComparison(
              'Live WhatsApp In-Call Audio Replacement',
              'Blocked by Android audio sandbox. Apps that claim to do this without root are only playing local speaker monitoring.',
              false,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(String title, String desc, bool isSupported) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF191D26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSupported ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isSupported ? const Color(0xFF25D366) : Colors.redAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
