import 'dart:async';
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
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _lastRecordedPath;
  double _currentLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedPreset = _audioBridge.currentPreset;
    _isProcessing = _audioBridge.isProcessing;
    _isRecording = _audioBridge.isRecording;

    _pitchShift = _selectedPreset.pitchShift;
    _echoDelayMs = _selectedPreset.echoDelayMs;
    _echoFeedback = _selectedPreset.echoFeedback;
    _robotFrequency = _selectedPreset.robotFrequency;

    _audioBridge.inputLevelStream.listen((lvl) {
      if (mounted) setState(() => _currentLevel = lvl);
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _recordTimer?.cancel();
      final path = await _audioBridge.stopRecording();
      setState(() {
        _isRecording = false;
        _lastRecordedPath = path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF191D26),
            content: Text('Transformed voice memo captured! Ready to send to WhatsApp.',
                style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold)),
          ),
        );
      }
    } else {
      if (!_isProcessing) {
        await _toggleProcessing();
      }

      await _audioBridge.startRecording();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _lastRecordedPath = null;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _recordSeconds++);
          if (_recordSeconds >= 60) {
            _toggleRecording();
          }
        }
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
              label: _isRecording ? 'RECORDING VOICE MEMO (ACTIVE DSP)' : 'MICROPHONE REAL-TIME MONITOR',
            ),
            const SizedBox(height: 18),

            // Voice Memo Recording & Share Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isRecording
                      ? [const Color(0xFF3B1218), const Color(0xFF1F1116)]
                      : [const Color(0xFF15221B), const Color(0xFF101915)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isRecording ? Colors.redAccent.withOpacity(0.5) : const Color(0xFF25D366).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isRecording ? Icons.fiber_manual_record : Icons.mic_rounded,
                            color: _isRecording ? Colors.redAccent : const Color(0xFF25D366),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRecording ? 'Recording Voice Memo...' : 'WhatsApp Voice Memo Studio',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        _isRecording ? _formatDuration(_recordSeconds) : 'Max 60s',
                        style: TextStyle(
                          color: _isRecording ? Colors.redAccent : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.redAccent : const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _toggleRecording,
                          icon: Icon(_isRecording ? Icons.stop_rounded : Icons.fiber_manual_record),
                          label: Text(_isRecording ? 'STOP RECORDING' : 'RECORD VOICE MEMO',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      if (_lastRecordedPath != null) ...[
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF128C7E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          ),
                          onPressed: () async {
                            final path = await _audioBridge.exportVoiceNoteToWhatsApp(_lastRecordedPath);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(path != null
                                      ? 'Shared to WhatsApp: ${path.split("/").last}'
                                      : 'Preparing voice memo. Opening WhatsApp...'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('SEND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Presets Selection
            const Text(
              'Select Voice Preset',
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
                    'Real-Time DSP Tuning',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Pitch Shifter Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Granular Pitch Shift', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                      const Text('Echo Delay (Delay Line)', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                      const Text('Robot Ring Modulation', style: TextStyle(color: Colors.white70, fontSize: 13)),
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

            const SizedBox(height: 24),

            // Live DSP Toggle Button
            SizedBox(
              width: double.infinity,
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
                  _isProcessing ? 'STOP REAL-TIME MONITOR' : 'START REAL-TIME MONITOR',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

