import 'package:flutter/material.dart';
import '../calling/voip_service.dart';
import '../models/voice_preset.dart';
import '../widgets/preset_card.dart';
import 'voip_call_screen.dart';

class VoipLobbyScreen extends StatefulWidget {
  const VoipLobbyScreen({super.key});

  @override
  State<VoipLobbyScreen> createState() => _VoipLobbyScreenState();
}

class _VoipLobbyScreenState extends State<VoipLobbyScreen> {
  final VoipService _voipService = VoipService.instance;
  VoicePreset _selectedPreset = VoicePreset.defaults[1]; // High pitch by default
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _startNewCall() async {
    setState(() => _isLoading = true);
    try {
      final session = await _voipService.createCallRoom(initialPreset: _selectedPreset);
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VoipCallScreen(session: session)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating call: $e')),
        );
      }
    }
  }

  Future<void> _joinCall() async {
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character room code.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final session = await _voipService.joinCallRoom(
        roomCode: code,
        initialPreset: _selectedPreset,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VoipCallScreen(session: session)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining call: $e')),
        );
      }
    }
  }

  Future<void> _startSoloTest() async {
    setState(() => _isLoading = true);
    final session = await _voipService.startSoloSimulationCall(initialPreset: _selectedPreset);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VoipCallScreen(session: session)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1218),
        elevation: 0,
        title: const Text('In-App VoIP Calling', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Architectural Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF132B20), Color(0xFF0F1C16)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF25D366), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Live Voice Transformation Calls',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Both caller & remote recipient hear the transformed voice live in real-time. '
                    'Because this call engine is built into our application, Android audio isolation restrictions do not apply!',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Select Initial Voice Preset
            const Text(
              'Select Your In-Call Voice',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: VoicePreset.defaults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final preset = VoicePreset.defaults[idx];
                return PresetCardWidget(
                  preset: preset,
                  isSelected: _selectedPreset.id == preset.id,
                  onTap: () => setState(() => _selectedPreset = preset),
                );
              },
            ),

            const SizedBox(height: 24),

            // Action: Start Call (Host)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _startNewCall,
                icon: const Icon(Icons.add_call),
                label: Text(
                  _isLoading ? 'PREPARING CALL...' : 'START NEW CALL ROOM',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action: Join Call (Peer)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF191D26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Join Existing Call Room',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _roomCodeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                          decoration: InputDecoration(
                            hintText: 'e.g. VOX-492',
                            hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1),
                            filled: true,
                            fillColor: const Color(0xFF10141D),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B4D8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _joinCall,
                        child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action: Solo Call Test
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7C5CFC),
                  side: const BorderSide(color: Color(0xFF7C5CFC)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _startSoloTest,
                icon: const Icon(Icons.hearing_rounded, size: 20),
                label: const Text('TEST LIVE IN-CALL VOICE (SOLO LOOPBACK)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
