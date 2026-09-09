import 'package:flutter/material.dart';

/// Einheitliche Karten-Optik (abgerundet, Schatten) für Kacheln/Boxen.
BoxDecoration boxStyle() {
  return BoxDecoration(
    color: const Color(0xff1e293b),
    borderRadius: BorderRadius.circular(18),
    boxShadow: const [
      BoxShadow(
        color: Colors.black38,
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );
}

// [active] hebt den Button optisch hervor (heller, Rand, Schatten) --
// damit sofort erkennbar ist, welcher Zustand (AN/AUS) gerade aktiv ist.
ButtonStyle buttonStyle(Color color, {bool active = true}) {
  return ElevatedButton.styleFrom(
    backgroundColor: active ? color : color.withValues(alpha: 0.25),
    foregroundColor: active ? Colors.white : Colors.white54,
    elevation: active ? 6 : 0,
    side: active
        ? const BorderSide(color: Colors.white, width: 1.5)
        : BorderSide.none,
    padding: const EdgeInsets.symmetric(
      vertical: 18,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );
}