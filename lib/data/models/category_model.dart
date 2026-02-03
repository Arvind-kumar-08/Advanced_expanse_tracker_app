import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Category model for transaction categorization
class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });

  /// Get category color from name
  static Color getCategoryColor(String category) {
    return AppColors.categoryColors[category] ?? AppColors.categoryColors['Other']!;
  }

  /// Predefined expense categories
  static const List<CategoryModel> expenseCategories = [
    CategoryModel(
      name: 'Food',
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
    ),
    CategoryModel(
      name: 'Travel',
      icon: Icons.flight,
      color: Color(0xFF4ECDC4),
    ),
    CategoryModel(
      name: 'Rent',
      icon: Icons.home,
      color: Color(0xFFFFBE0B),
    ),
    CategoryModel(
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFFFF006E),
    ),
    CategoryModel(
      name: 'Entertainment',
      icon: Icons.movie,
      color: Color(0xFF8338EC),
    ),
    CategoryModel(
      name: 'Healthcare',
      icon: Icons.medical_services,
      color: Color(0xFF06FFA5),
    ),
    CategoryModel(
      name: 'Education',
      icon: Icons.school,
      color: Color(0xFF3A86FF),
    ),
    CategoryModel(
      name: 'Utilities',
      icon: Icons.lightbulb,
      color: Color(0xFFFB5607),
    ),
    CategoryModel(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF95A5A6),
    ),
  ];

  /// Predefined income categories
  static const List<CategoryModel> incomeCategories = [
    CategoryModel(
      name: 'Salary',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF00D09C),
      isIncome: true,
    ),
    CategoryModel(
      name: 'Freelance',
      icon: Icons.work,
      color: Color(0xFF3A86FF),
      isIncome: true,
    ),
    CategoryModel(
      name: 'Investment',
      icon: Icons.trending_up,
      color: Color(0xFF8338EC),
      isIncome: true,
    ),
    CategoryModel(
      name: 'Business',
      icon: Icons.business,
      color: Color(0xFFFFBE0B),
      isIncome: true,
    ),
    CategoryModel(
      name: 'Gift',
      icon: Icons.card_giftcard,
      color: Color(0xFFFF006E),
      isIncome: true,
    ),
    CategoryModel(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF95A5A6),
      isIncome: true,
    ),
  ];

  /// Get all categories by type
  static List<CategoryModel> getCategoriesByType(bool isIncome) {
    return isIncome ? incomeCategories : expenseCategories;
  }

  /// Get category by name
  static CategoryModel? getCategoryByName(String name, bool isIncome) {
    final categories = getCategoriesByType(isIncome);
    try {
      return categories.firstWhere((cat) => cat.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get icon for category
  static IconData getIconForCategory(String category, bool isIncome) {
    final cat = getCategoryByName(category, isIncome);
    return cat?.icon ?? Icons.more_horiz;
  }

  @override
  String toString() {
    return 'CategoryModel(name: $name, isIncome: $isIncome)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel &&
        other.name == name &&
        other.isIncome == isIncome;
  }

  @override
  int get hashCode {
    return name.hashCode ^ isIncome.hashCode;
  }
}