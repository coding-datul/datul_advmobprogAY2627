import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String host = dotenv.env['HOST'] ?? 'https://dummyjson.com';

class AppColors {
  static const Color primary = Color(0xFFF59E0B); // Golden amber / orange
  static const Color primaryDark = Color(0xFFD97706);
  static const Color secondary = Color(0xFF2563EB);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF111827);
  static const Color textDark = Color(0xFFF9FAFB);
  static const Color textMuted = Color(0xFF6B7280);
}
