import 'dart:async';
import 'package:flutter/material.dart';
import '../audio/native_audio_bridge.dart';
import '../models/voice_preset.dart';
import '../widgets/vu_meter.dart';
import 'voice_studio_screen.dart';
import 'diagnostics_screen.dart';
import 'subscription_screen.dart';
import 'settings_screen.dart';
import 'compatibility_warning_screen.dart';
import 'voip_lobby_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final NativeAudioBridge _audioBridge = NativeAudioBridge.instance;
  bool _isProcessing = false;
  double _currentLevel = 0.0;
  StreamSubscription<double>? _levelSub;
  VoicePreset _selectedPreset = VoicePreset.defaults.first;

  @override
  void initState() {
    super.initState();
    _isProcessing = _audioBridge.isProcessing;
    _selectedPreset = _audioBridge.currentPreset;

    _levelSub = _audioBridge.inputLevelStream.listen((lvl) {
      if (mounted) setState(() => _currentLevel = lvl);
    });
  }

  @override
  void dispose() {
    _levelSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleProcessing() async {
    if (_isProcessing) {
      await _audioBridge.stopProcessing();
      setState(() {
        _isProcessing = false;
        _currentLevel = 0.0;
      });
    } else {
      final success = await _audioBridge.startProcessing(_selectedPreset);
      setState(() => _isProcessing = success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1218),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.graphic_eq_rounded, color: Color(0xFF25D366)),
            SizedBox(width: 10),
            Text(
              'Voice Changer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
            tooltip: 'Compatibility Notice',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompatibilityWarningScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Master Control Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isProcessing
                      ? [const Color(0xFF1E3A2F), const Color(0xFF14221E)]
                      : [const Color(0xFF1B202A), const Color(0xFF141720)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isProcessing ? const Color(0xFF25D366).withOpacity(0.5) : Colors.white10,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isProcessing ? 'DSP ENGINE ACTIVE' : 'ENGINE STANDBY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: _isProcessing ? const Color(0xFF25D366) : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPreset.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isProcessing,
                        activeColor: const Color(0xFF25D366),
                        onChanged: (_) => _toggleProcessing(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  VuMeterWidget(
                    level: _isProcessing ? _currentLevel : 0.0,
                    label: 'LIVE MICROPHONE LEVEL',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Transparency & Technical Reality Notice
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompatibilityWarningScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF241C10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade700.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.amber.shade400, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Android Security isolates live third-party calls. Use Voice Studio to create WhatsApp Voice Memos directly.',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade200, height: 1.3),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.amber),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // In-App VoIP Live Calling Hero Card (Track B)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoipLobbyScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF142B20), Color(0xFF0F1B15)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF25D366).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF25D366), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'In-App VoIP Live Call',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.bolt_rounded, color: Color(0xFF25D366), size: 16),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Real-time P2P call with live voice modifier',
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF25D366), size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Quick Actions Navigation Grid
            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    title: 'Voice Studio',
                    subtitle: 'DSP tuning & presets',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VoiceStudioScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildActionTile(
                    title: 'Diagnostics',
                    subtitle: 'Audio route & latency',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF00B4D8),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    title: 'Subscriptions',
                    subtitle: 'Feasibility Preview',
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFFFB703),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildActionTile(
                    title: 'WhatsApp Share',
                    subtitle: 'Send Voice Memo',
                    icon: Icons.share_rounded,
                    color: const Color(0xFF7C5CFC),
                    onTap: () async {
                      final path = await _audioBridge.exportVoiceNoteToWhatsApp();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(path != null
                                ? 'Exported voice note to WhatsApp: $path'
                                : 'Select a preset and record to share to WhatsApp.'),
                            backgroundColor: const Color(0xFF1E222D),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
