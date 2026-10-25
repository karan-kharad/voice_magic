class VoicePreset {
  final String id;
  final String name;
  final String description;
  final double pitchShift; // Semitones: -12.0 to +12.0
  final int echoDelayMs; // 0 to 500 ms
  final double echoFeedback; // 0.0 to 0.8
  final double robotFrequency; // 0.0 (off) or 50.0 to 200.0 Hz
  final String iconName;

  const VoicePreset({
    required this.id,
    required this.name,
    required this.description,
    this.pitchShift = 0.0,
    this.echoDelayMs = 0,
    this.echoFeedback = 0.0,
    this.robotFrequency = 0.0,
    required this.iconName,
  });

  static const List<VoicePreset> defaults = [
    VoicePreset(
      id: 'normal',
      name: 'Normal Voice',
      description: 'Clean, unprocessed pass-through audio with noise reduction.',
      pitchShift: 0.0,
      echoDelayMs: 0,
      echoFeedback: 0.0,
      robotFrequency: 0.0,
      iconName: 'mic',
    ),
    VoicePreset(
      id: 'high_pitch',
      name: 'Higher Pitch',
      description: 'Crisp +5 semitones pitch increase for an animated, cartoon effect.',
      pitchShift: 5.0,
      echoDelayMs: 0,
      echoFeedback: 0.0,
      robotFrequency: 0.0,
      iconName: 'arrow_upward',
    ),
    VoicePreset(
      id: 'low_pitch',
      name: 'Lower Pitch',
      description: 'Deep -6 semitones bass resonance for an authoritative, cinematic voice.',
      pitchShift: -6.0,
      echoDelayMs: 0,
      echoFeedback: 0.0,
      robotFrequency: 0.0,
      iconName: 'arrow_downward',
    ),
    VoicePreset(
      id: 'robot',
      name: 'Robot Style',
      description: 'Harmonic ring-modulation vocoder at 120Hz carrier frequency.',
      pitchShift: -1.0,
      echoDelayMs: 15,
      echoFeedback: 0.2,
      robotFrequency: 120.0,
      iconName: 'smart_toy',
    ),
    VoicePreset(
      id: 'echo',
      name: 'Echo Chamber',
      description: 'Multi-tap stereo echo with 180ms delay and 45% feedback resonance.',
      pitchShift: 0.0,
      echoDelayMs: 180,
      echoFeedback: 0.45,
      robotFrequency: 0.0,
      iconName: 'surround_sound',
    ),
  ];
}
