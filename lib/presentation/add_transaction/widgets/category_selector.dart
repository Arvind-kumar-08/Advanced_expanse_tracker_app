import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';

/// Widget for selecting transaction category
class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final TransactionType transactionType;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.transactionType,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = CategoryModel.getCategoriesByType(
      transactionType == TransactionType.income,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.category,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final isSelected = selectedCategory == category.name;
            return _buildCategoryChip(
              category: category,
              isSelected: isSelected,
              theme: theme,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required CategoryModel category,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: () => onCategorySelected(category.name),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withOpacity(0.15)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              color: isSelected ? category.color : theme.iconTheme.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? category.color : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}