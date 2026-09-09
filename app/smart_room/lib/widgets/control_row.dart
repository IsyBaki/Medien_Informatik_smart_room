import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// Zeigt zwei Buttons (AN/AUS) für ein Gerät. [isOn] bestimmt, welcher der
/// beiden Buttons gerade als "aktiv" hervorgehoben wird.
class ControlRow extends StatelessWidget {
  final String onText;
  final String offText;
  final bool isOn;
  final VoidCallback onPressed;
  final VoidCallback offPressed;

  const ControlRow({
    super.key,
    required this.onText,
    required this.offText,
    required this.isOn,
    required this.onPressed,
    required this.offPressed,
  });

  /// Baut die zwei nebeneinander liegenden AN/AUS-Buttons.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle(Colors.green, active: isOn),
              child: _buttonLabel(onText, isOn),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed: offPressed,
              style: buttonStyle(Colors.red, active: !isOn),
              child: _buttonLabel(offText, !isOn),
            ),
          ),
        ],
      ),
    );
  }

  /// Text mit Symbol davor -- gefüllter Haken, wenn [active], sonst nur ein Kreis.
  Widget _buttonLabel(String text, bool active) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(active ? Icons.check_circle : Icons.circle_outlined, size: 16),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
