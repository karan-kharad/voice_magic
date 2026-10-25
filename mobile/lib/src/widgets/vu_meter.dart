import 'package:flutter/material.dart';

class VuMeterWidget extends StatelessWidget {
  final double level; // 0.0 to 1.0
  final String label;

  const VuMeterWidget({
    super.key,
    required this.level,
    this.label = 'INPUT LEVEL',
  });

  @override
  Widget build(BuildContext context) {
    final clamped = level.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.grey.shade400,
              ),
            ),
            Text(
              '${(clamped * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: clamped > 0.85 ? Colors.redAccent : Colors.tealAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent.shade400,
                      Colors.amberAccent.shade400,
                      Colors.redAccent.shade400,
                    ],
                    stops: const [0.6, 0.85, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
