import 'package:flutter/material.dart';

class AppStyles {
  static BoxDecoration mainGradientDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const BoxDecoration(
        color: Color(0xFF121212),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade50,
          Colors.white,
          Colors.blue.shade50.withOpacity(0.5),
        ],
      ),
    );
  }
}

