import 'package:flutter/material.dart';

class AppStyles {
  static BoxDecoration get mainGradientDecoration => BoxDecoration(
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
