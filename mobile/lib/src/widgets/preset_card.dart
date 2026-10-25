import 'package:flutter/material.dart';
import '../models/voice_preset.dart';

class PresetCardWidget extends StatelessWidget {
  final VoicePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const PresetCardWidget({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIconData(String name) {
    switch (name) {
      case 'arrow_upward':
        return Icons.arrow_upward_rounded;
      case 'arrow_downward':
        return Icons.arrow_downward_rounded;
      case 'smart_toy':
        return Icons.smart_toy_rounded;
      case 'surround_sound':
        return Icons.surround_sound_rounded;
      default:
        return Icons.mic_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? primary : Colors.white10,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? primary.withOpacity(0.12) : const Color(0xFF1E222D),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(preset.iconName),
                  color: isSelected ? Colors.black : Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
