import 'package:flutter/material.dart';
import '../audio/native_audio_bridge.dart';
import '../models/voice_preset.dart';
import '../widgets/preset_card.dart';
import '../widgets/vu_meter.dart';

class VoiceStudioScreen extends StatefulWidget {
  const VoiceStudioScreen({super.key});

  @override
  State<VoiceStudioScreen> createState() => _VoiceStudioScreenState();
}

class _VoiceStudioScreenState extends State<VoiceStudioScreen> {
  final NativeAudioBridge _audioBridge = NativeAudioBridge.instance;
  VoicePreset _selectedPreset = VoicePreset.defaults.first;

  double _pitchShift = 0.0;
  int _echoDelayMs = 0;
  double _echoFeedback = 0.0;
  double _robotFrequency = 0.0;

  bool _isProcessing = false;
  double _currentLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedPreset = _audioBridge.currentPreset;
    _isProcessing = _audioBridge.isProcessing;

    _pitchShift = _selectedPreset.pitchShift;
    _echoDelayMs = _selectedPreset.echoDelayMs;
    _echoFeedback = _selectedPreset.echoFeedback;
    _robotFrequency = _selectedPreset.robotFrequency;

    _audioBridge.inputLevelStream.listen((lvl) {
      if (mounted) setState(() => _currentLevel = lvl);
    });
  }

  void _applyPreset(VoicePreset preset) {
    setState(() {
      _selectedPreset = preset;
      _pitchShift = preset.pitchShift;
      _echoDelayMs = preset.echoDelayMs;
      _echoFeedback = preset.echoFeedback;
      _robotFrequency = preset.robotFrequency;
    });

    if (_isProcessing) {
      _audioBridge.startProcessing(preset);
    }
  }

  void _onParameterChanged() {
    _audioBridge.updateDspParameters(
      pitchShift: _pitchShift,
      echoDelayMs: _echoDelayMs,
      echoFeedback: _echoFeedback,
      robotFrequency: _robotFrequency,
    );
  }

  Future<void> _toggleProcessing() async {
    if (_isProcessing) {
      await _audioBridge.stopProcessing();
      setState(() {
        _isProcessing = false;
        _currentLevel = 0.0;
      });
    } else {
      final custom = VoicePreset(
        id: 'custom_${_selectedPreset.id}',
        name: _selectedPreset.name,
        description: _selectedPreset.description,
        pitchShift: _pitchShift,
        echoDelayMs: _echoDelayMs,
        echoFeedback: _echoFeedback,
        robotFrequency: _robotFrequency,
        iconName: _selectedPreset.iconName,
      );
      final success = await _audioBridge.startProcessing(custom);
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
        title: const Text('Voice Studio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio Header VU meter
            VuMeterWidget(
              level: _isProcessing ? _currentLevel : 0.0,
              label: 'MICROPHONE REAL-TIME MONITOR',
            ),
            const SizedBox(height: 18),

            // Presets Selection
            const Text(
              'Select Preset',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                  onTap: () => _applyPreset(preset),
                );
              },
            ),

            const SizedBox(height: 24),

            // Fine-Tuning DSP Controls
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
                    'DSP Parameter Tuning',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Pitch Shifter Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pitch Shift', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${_pitchShift.toStringAsFixed(1)} st',
                          style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _pitchShift,
                    min: -12.0,
                    max: 12.0,
                    divisions: 48,
                    activeColor: const Color(0xFF25D366),
                    onChanged: (val) {
                      setState(() => _pitchShift = val);
                      _onParameterChanged();
                    },
                  ),

                  // Echo Delay Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Echo Delay', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('$_echoDelayMs ms',
                          style: const TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _echoDelayMs.toDouble(),
                    min: 0.0,
                    max: 500.0,
                    divisions: 50,
                    activeColor: const Color(0xFF00B4D8),
                    onChanged: (val) {
                      setState(() => _echoDelayMs = val.toInt());
                      _onParameterChanged();
                    },
                  ),

                  // Robot Vocoder Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Robot Modulation', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${_robotFrequency.toInt()} Hz',
                          style: const TextStyle(color: Color(0xFF7C5CFC), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: _robotFrequency,
                    min: 0.0,
                    max: 200.0,
                    divisions: 20,
                    activeColor: const Color(0xFF7C5CFC),
                    onChanged: (val) {
                      setState(() => _robotFrequency = val);
                      _onParameterChanged();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons (Toggle Engine & WhatsApp Export)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isProcessing ? Colors.redAccent.shade700 : const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _toggleProcessing,
                      icon: Icon(_isProcessing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                      label: Text(
                        _isProcessing ? 'STOP DSP' : 'START DSP',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final path = await _audioBridge.exportVoiceNoteToWhatsApp();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(path != null
                                ? 'Exported to WhatsApp: $path'
                                : 'Prepared voice note. Sharing to WhatsApp...'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('SEND TO WA'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
