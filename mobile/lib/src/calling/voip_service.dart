import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../audio/native_audio_bridge.dart';
import '../models/voice_preset.dart';
import 'call_session.dart';

class VoipService {
  static final VoipService instance = VoipService._();
  VoipService._();

  static const String _defaultBaseUrl = 'http://10.0.2.2/api/v1/calling';
  final NativeAudioBridge _audioBridge = NativeAudioBridge.instance;

  CallSession? _currentSession;
  CallSession? get currentSession => _currentSession;

  Timer? _callDurationTimer;
  Timer? _pollingTimer;
  int _lastSignalId = 0;

  final StreamController<CallSession> _sessionController = StreamController<CallSession>.broadcast();
  Stream<CallSession> get sessionStream => _sessionController.stream;

  final StreamController<String> _remotePresetController = StreamController<String>.broadcast();
  Stream<String> get remotePresetStream => _remotePresetController.stream;

  Future<CallSession> createCallRoom({
    required VoicePreset initialPreset,
    String? baseUrl,
  }) async {
    final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}/rooms/create/');
    String roomCode = 'VOX-${DateTime.now().millisecondsSinceEpoch % 1000}';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'preset': initialPreset.id}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        roomCode = data['data']['room']['room_code'];
      }
    } catch (_) {
      // Offline fallback: Use generated room code
    }

    final session = CallSession(
      roomCode: roomCode,
      role: CallRole.host,
      status: CallStatus.waiting,
      activePreset: initialPreset,
      isLoopbackSimulation: false,
    );

    _currentSession = session;
    _startCallTimer();
    _startPolling(baseUrl);
    await _audioBridge.startProcessing(initialPreset);
    _sessionController.add(session);
    return session;
  }

  Future<CallSession> joinCallRoom({
    required String roomCode,
    required VoicePreset initialPreset,
    String? baseUrl,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}/rooms/$cleanCode/join/');

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'peer_id': 'mobile_peer_${DateTime.now().millisecondsSinceEpoch % 1000}'}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    final session = CallSession(
      roomCode: cleanCode,
      role: CallRole.peer,
      status: CallStatus.connected,
      activePreset: initialPreset,
      isLoopbackSimulation: false,
    );

    _currentSession = session;
    _startCallTimer();
    _startPolling(baseUrl);
    await _audioBridge.startProcessing(initialPreset);
    _sessionController.add(session);
    return session;
  }

  Future<CallSession> startSoloSimulationCall({
    required VoicePreset initialPreset,
  }) async {
    final session = CallSession(
      roomCode: 'SOLO-TEST',
      role: CallRole.host,
      status: CallStatus.connected,
      activePreset: initialPreset,
      isLoopbackSimulation: true,
      latencyMs: 18,
    );

    _currentSession = session;
    _startCallTimer();
    await _audioBridge.startProcessing(initialPreset);
    _sessionController.add(session);
    return session;
  }

  Future<void> switchPresetMidCall(VoicePreset preset, {String? baseUrl}) async {
    if (_currentSession == null) return;

    _currentSession!.activePreset = preset;
    await _audioBridge.updateDspParameters(
      pitchShift: preset.pitchShift,
      echoDelayMs: preset.echoDelayMs,
      echoFeedback: preset.echoFeedback,
      robotFrequency: preset.robotFrequency,
    );

    // Notify peer via signaling if not simulation
    if (!_currentSession!.isLoopbackSimulation) {
      _sendSignal('preset_update', {'preset': preset.id}, baseUrl: baseUrl);
    }

    _sessionController.add(_currentSession!);
  }

  Future<void> toggleMute() async {
    if (_currentSession == null) return;
    _currentSession!.isMuted = !_currentSession!.isMuted;
    if (_currentSession!.isMuted) {
      await _audioBridge.stopProcessing();
    } else {
      await _audioBridge.startProcessing(_currentSession!.activePreset);
    }
    _sessionController.add(_currentSession!);
  }

  void toggleSpeakerphone() {
    if (_currentSession == null) return;
    _currentSession!.isSpeakerphone = !_currentSession!.isSpeakerphone;
    _sessionController.add(_currentSession!);
  }

  Future<void> endCall({String? baseUrl}) async {
    if (_currentSession == null) return;

    _currentSession!.status = CallStatus.ended;
    _sessionController.add(_currentSession!);

    _callDurationTimer?.cancel();
    _pollingTimer?.cancel();

    if (!_currentSession!.isLoopbackSimulation) {
      try {
        final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}/rooms/${_currentSession!.roomCode}/end/');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'role': _currentSession!.role.name}),
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    await _audioBridge.stopProcessing();
    _currentSession = null;
  }

  void _startCallTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _currentSession!.status == CallStatus.connected) {
        _currentSession!.durationSeconds++;
        _sessionController.add(_currentSession!);
      }
    });
  }

  void _startPolling(String? baseUrl) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_currentSession == null || _currentSession!.isLoopbackSimulation) return;

      try {
        final role = _currentSession!.role.name;
        final url = Uri.parse(
          '${baseUrl ?? _defaultBaseUrl}/rooms/${_currentSession!.roomCode}/poll/?role=$role&last_id=$_lastSignalId',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          final roomStatus = data['room_status'];

          if (roomStatus == 'connected' && _currentSession!.status == CallStatus.waiting) {
            _currentSession!.status = CallStatus.connected;
            _sessionController.add(_currentSession!);
          } else if (roomStatus == 'ended') {
            await endCall();
            return;
          }

          final signals = data['signals'] as List<dynamic>?;
          if (signals != null && signals.isNotEmpty) {
            for (final sig in signals) {
              final id = sig['id'] as int;
              if (id > _lastSignalId) _lastSignalId = id;

              final type = sig['signal_type'] as String;
              if (type == 'hangup') {
                await endCall();
                return;
              } else if (type == 'preset_update') {
                final newPresetId = sig['payload']?['preset'] as String?;
                if (newPresetId != null) {
                  _remotePresetController.add(newPresetId);
                }
              }
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _sendSignal(String type, Map<String, dynamic> payload, {String? baseUrl}) async {
    if (_currentSession == null || _currentSession!.isLoopbackSimulation) return;
    try {
      final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}/rooms/${_currentSession!.roomCode}/signal/');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_type': _currentSession!.role.name,
          'signal_type': type,
          'payload': payload,
        }),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
