import 'package:flutter/material.dart';

/// App-wide color constants for light and dark themes
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5848E8);
  static const Color primaryLight = Color(0xFF9D97FF);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF2D3436);
  static const Color textPrimaryDark = Color(0xFFECF0F1);
  static const Color textSecondaryLight = Color(0xFF636E72);
  static const Color textSecondaryDark = Color(0xFFB2BEC3);

  // Transaction Type Colors
  static const Color income = Color(0xFF00D09C);
  static const Color expense = Color(0xFFFF6B6B);

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF6B6B),
    'Travel': Color(0xFF4ECDC4),
    'Rent': Color(0xFFFFBE0B),
    'Salary': Color(0xFF00D09C),
    'Shopping': Color(0xFFFF006E),
    'Entertainment': Color(0xFF8338EC),
    'Healthcare': Color(0xFF06FFA5),
    'Education': Color(0xFF3A86FF),
    'Utilities': Color(0xFFFB5607),
    'Other': Color(0xFF95A5A6),
  };

  // Status Colors
  static const Color success = Color(0xFF00D09C);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFBE0B);
  static const Color info = Color(0xFF3A86FF);

  // Border Colors
  static const Color borderLight = Color(0xFFDFE6E9);
  static const Color borderDark = Color(0xFF2D3436);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x3A000000);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF9D97FF),
  ];

  static const List<Color> incomeGradient = [
    Color(0xFF00D09C),
    Color(0xFF00F5A0),
  ];

  static const List<Color> expenseGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];
}