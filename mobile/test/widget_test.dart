import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_voice_changer/main.dart';
import 'package:whatsapp_voice_changer/src/models/voice_preset.dart';

void main() {
  testWidgets('App initializes with splash screen and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const WhatsAppVoiceChangerApp());

    // Verify splash screen branding
    expect(find.text('WhatsApp Voice Changer'), findsOneWidget);
    expect(find.text('Professional Real-Time DSP Audio Studio'), findsOneWidget);
  });

  test('VoicePreset model defaults are properly defined', () {
    final presets = VoicePreset.defaults;
    expect(presets.length, 5);

    final normal = presets.firstWhere((p) => p.id == 'normal');
    expect(normal.pitchShift, 0.0);

    final highPitch = presets.firstWhere((p) => p.id == 'high_pitch');
    expect(highPitch.pitchShift, 5.0);

    final robot = presets.firstWhere((p) => p.id == 'robot');
    expect(robot.robotFrequency, 120.0);

    final echo = presets.firstWhere((p) => p.id == 'echo');
    expect(echo.echoDelayMs, 180);
  });
}
