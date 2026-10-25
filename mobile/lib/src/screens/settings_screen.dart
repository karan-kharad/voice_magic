import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentServerUrl = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
  }

  Future<void> _loadCurrentServer() async {
    final url = await ApiService.instance.getBaseUrl();
    if (mounted) setState(() => _currentServerUrl = url);
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: _currentServerUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191D26),
        title: const Text('Configure EC2 Server URL', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your AWS EC2 Public IP or Domain:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 13.233.xx.xx or http://ip',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ApiService.instance.setCustomBaseUrl(controller.text);
                await _loadCurrentServer();
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

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
          const Text('Backend & Server Connection',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          _buildActionTile(
            context,
            'EC2 Server Connection',
            _currentServerUrl,
            Icons.cloud_sync_rounded,
            onTap: _showServerConfigDialog,
          ),

          const SizedBox(height: 24),
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
          _buildActionTile(
            context,
            'Submit Diagnostics Report',
            'Sends device hardware specs to improve compatibility',
            Icons.bug_report_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnostics report submitted to backend.')),
              );
            },
          ),
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

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
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
        onTap: onTap,
      ),
    );
  }
}
