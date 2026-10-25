import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1218),
        title: const Text('Settings & Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Audio Preferences',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildSwitchTile('Exclusive Low-Latency Mode', 'Bypasses system audio mixer when supported', true, (_) {}),
          _buildSwitchTile('Automatic Noise Suppression', 'Reduces ambient room hiss before DSP', true, (_) {}),
          _buildSwitchTile('Keep Processing in Background', 'Allows continuous studio monitoring with notification', true, (_) {}),

          const SizedBox(height: 24),
          const Text('Privacy & Compliance',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildLinkTile('Zero Audio Cloud Transmission', 'All microphone audio stays in device RAM', Icons.verified_user_rounded),
          _buildLinkTile('Privacy Policy', 'Review data minimization policy', Icons.policy_rounded),
          _buildLinkTile('Open Source Licenses', 'Google Oboe, Flutter, Apache 2.0', Icons.description_rounded),

          const SizedBox(height: 24),
          const Text('Support & Feedback',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildActionTile(context, 'Submit Diagnostics Report', 'Sends device hardware specs to improve compatibility', Icons.bug_report_rounded),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool val, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF191D26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        value: val,
        activeColor: const Color(0xFF25D366),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLinkTile(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF191D26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF25D366)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF191D26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00B4D8)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diagnostics report submitted to backend.')),
          );
        },
      ),
    );
  }
}
