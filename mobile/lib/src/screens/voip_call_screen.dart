import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../audio/native_audio_bridge.dart';
import '../calling/call_session.dart';
import '../calling/voip_service.dart';
import '../models/voice_preset.dart';
import '../widgets/vu_meter.dart';

class VoipCallScreen extends StatefulWidget {
  final CallSession session;

  const VoipCallScreen({super.key, required this.session});

  @override
  State<VoipCallScreen> createState() => _VoipCallScreenState();
}

class _VoipCallScreenState extends State<VoipCallScreen> with SingleTickerProviderStateMixin {
  final VoipService _voipService = VoipService.instance;
  final NativeAudioBridge _audioBridge = NativeAudioBridge.instance;

  late CallSession _session;
  StreamSubscription<CallSession>? _sessionSub;
  StreamSubscription<double>? _levelSub;
  StreamSubscription<String>? _remotePresetSub;

  double _currentLevel = 0.0;
  String? _remotePresetName;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _session = widget.session;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _sessionSub = _voipService.sessionStream.listen((updated) {
      if (mounted) {
        setState(() => _session = updated);
        if (updated.status == CallStatus.ended) {
          Navigator.of(context).pop();
        }
      }
    });

    _levelSub = _audioBridge.inputLevelStream.listen((lvl) {
      if (mounted) setState(() => _currentLevel = lvl);
    });

    _remotePresetSub = _voipService.remotePresetStream.listen((presetId) {
      if (mounted) {
        final preset = VoicePreset.defaults.firstWhere(
          (p) => p.id == presetId,
          orElse: () => VoicePreset.defaults.first,
        );
        setState(() => _remotePresetName = preset.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E2430),
            content: Text('Remote peer switched voice to: ${preset.name}',
                style: const TextStyle(color: Color(0xFF00B4D8))),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _levelSub?.cancel();
    _remotePresetSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _session.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code ${_session.roomCode} copied to clipboard!'),
        backgroundColor: const Color(0xFF191D26),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _session.status == CallStatus.connected;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => _voipService.endCall(),
        ),
        title: InkWell(
          onTap: _copyRoomCode,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Room: ${_session.roomCode}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 15, color: Colors.grey),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF132B1F) : const Color(0xFF2E2211),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected ? const Color(0xFF25D366).withOpacity(0.4) : Colors.amber.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFF25D366) : Colors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isConnected ? 'HD WebRTC P2P' : 'CONNECTING...',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? const Color(0xFF25D366) : Colors.amber,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Call Duration & Ping Header
            Text(
              isConnected ? _session.formattedDuration : 'Waiting for participant to join...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.white : Colors.white60,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live Voice Transformation Active • ${_session.latencyMs}ms local DSP',
              style: const TextStyle(fontSize: 12, color: Color(0xFF25D366)),
            ),

            const Spacer(),

            // Calling Wave Avatars Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Local User Avatar with Pulse
                Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.08 * (_currentLevel.clamp(0.1, 1.0)));
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF25D366).withOpacity(0.35),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _session.isMuted ? Icons.mic_off_rounded : Icons.person_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('You (Transformed)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _session.activePreset.name,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF00B4D8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                // VoIP Connection Icon
                Icon(
                  Icons.compare_arrows_rounded,
                  color: isConnected ? const Color(0xFF25D366) : Colors.grey,
                  size: 36,
                ),

                // Remote Peer Avatar
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? const Color(0xFF1E2838) : const Color(0xFF141820),
                        border: Border.all(
                          color: isConnected ? const Color(0xFF00B4D8) : Colors.white12,
                          width: 2,
                        ),
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF00B4D8).withOpacity(0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          isConnected ? Icons.headset_mic_rounded : Icons.person_outline_rounded,
                          size: 46,
                          color: isConnected ? Colors.white : Colors.white38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isConnected ? 'Remote Peer' : 'Peer Standby',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isConnected ? Colors.white : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _remotePresetName ?? (isConnected ? 'Hearing Altered Voice' : 'Waiting...'),
                        style: TextStyle(
                          fontSize: 11,
                          color: isConnected ? const Color(0xFF25D366) : Colors.white38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Live Audio Level Monitor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: VuMeterWidget(
                level: _session.isMuted ? 0.0 : _currentLevel,
                label: 'TRANSMITTED ALTERED AUDIO LEVEL',
              ),
            ),

            const Spacer(),

            // Mid-Call Voice Preset Selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MID-CALL VOICE MODIFIER',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.grey),
                      ),
                      Text(
                        'Instant DSP Switch',
                        style: TextStyle(fontSize: 11, color: Color(0xFF25D366), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: VoicePreset.defaults.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final preset = VoicePreset.defaults[index];
                        final isSelected = _session.activePreset.id == preset.id;

                        return ChoiceChip(
                          label: Text(preset.name),
                          selected: isSelected,
                          onSelected: (_) => _voipService.switchPresetMidCall(preset),
                          selectedColor: const Color(0xFF25D366),
                          backgroundColor: const Color(0xFF1E2433),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Call Controls Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _buildCallControlButton(
                    icon: _session.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _session.isMuted ? 'Unmute' : 'Mute',
                    color: _session.isMuted ? Colors.redAccent : Colors.white24,
                    iconColor: Colors.white,
                    onTap: () => _voipService.toggleMute(),
                  ),

                  // End Call Button
                  InkWell(
                    onTap: () => _voipService.endCall(),
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
                    ),
                  ),

                  // Speakerphone Button
                  _buildCallControlButton(
                    icon: _session.isSpeakerphone ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    label: _session.isSpeakerphone ? 'Speaker' : 'Earpiece',
                    color: _session.isSpeakerphone ? const Color(0xFF00B4D8).withOpacity(0.3) : Colors.white24,
                    iconColor: _session.isSpeakerphone ? const Color(0xFF00B4D8) : Colors.white,
                    onTap: () => _voipService.toggleSpeakerphone(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
