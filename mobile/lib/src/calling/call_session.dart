import '../models/voice_preset.dart';

enum CallRole { host, peer }

enum CallStatus { idle, waiting, ringing, connected, ended }

class CallSession {
  final String roomCode;
  final CallRole role;
  CallStatus status;
  VoicePreset activePreset;
  bool isMuted;
  bool isSpeakerphone;
  int durationSeconds;
  int latencyMs;
  final bool isLoopbackSimulation;

  CallSession({
    required this.roomCode,
    required this.role,
    this.status = CallStatus.waiting,
    required this.activePreset,
    this.isMuted = false,
    this.isSpeakerphone = true,
    this.durationSeconds = 0,
    this.latencyMs = 28,
    this.isLoopbackSimulation = false,
  });

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
