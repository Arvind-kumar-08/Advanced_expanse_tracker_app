import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../state/providers/auth_provider.dart';
import '../../../state/providers/theme_provider.dart';
import '../../../state/providers/transaction_provider.dart';
import '../../../services/pdf_service.dart';
import '../widgets/settings_tile.dart';

/// Settings screen for app configuration and user preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          _buildProfileCard(context, theme, authProvider),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(theme, 'Appearance'),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.dark_mode,
            title: AppStrings.darkMode,
            subtitle: themeProvider.isDarkMode ? 'On' : 'Off',
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader(theme, 'Data Management'),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.sync,
            title: AppStrings.syncData,
            subtitle: _getLastSyncText(transactionProvider),
            onTap: () => _handleSync(context, transactionProvider),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.file_download,
            title: AppStrings.exportReport,
            subtitle: 'Download monthly report as PDF',
            onTap: () => _handleExportPDF(context, transactionProvider),
          ),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader(theme, 'Account'),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle: authProvider.currentUser?.email ?? '',
            onTap: () {
              // Navigate to profile screen (optional)
            },
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.logout,
            title: AppStrings.logout,
            subtitle: 'Sign out of your account',
            textColor: Colors.red,
            onTap: () => _handleLogout(context, authProvider),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(theme, 'About'),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.info_outline,
            title: AppStrings.about,
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              // Navigate to terms of service
            },
          ),
          const SizedBox(height: 32),

          // Danger Zone Section
          _buildSectionHeader(theme, 'Danger Zone'),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            textColor: Colors.red,
            onTap: () => _handleDeleteAccount(context, authProvider),
          ),
        ],
      ),
    );
  }

  /// Build profile card
  Widget _buildProfileCard(
      BuildContext context,
      ThemeData theme,
      AuthProvider authProvider,
      ) {
    final user = authProvider.currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              user?.name.substring(0, 1).toUpperCase() ?? 'U',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.primaryColor,
      ),
    );
  }

  /// Get last sync time text
  String _getLastSyncText(TransactionProvider transactionProvider) {
    final lastSync = transactionProvider.getLastSyncTime();
    if (lastSync == null) {
      return 'Never synced';
    }
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  /// Handle sync
  Future<void> _handleSync(
      BuildContext context,
      TransactionProvider transactionProvider,
      ) async {
    final success = await transactionProvider.syncData();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? AppStrings.syncSuccess
              : transactionProvider.errorMessage ?? 'Sync failed',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  /// Handle export PDF
  Future<void> _handleExportPDF(
      BuildContext context,
      TransactionProvider transactionProvider,
      ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final pdfService = PDFService();
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);

      final transactions = transactionProvider.transactions
          .where((t) =>
      t.date.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          t.date.isBefore(lastDay.add(const Duration(days: 1))))
          .toList();

      await pdfService.generateMonthlyReport(
        transactions: transactions,
        month: now.month,
        year: now.year,
      );

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.exportSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle logout
  Future<void> _handleLogout(
      BuildContext context,
      AuthProvider authProvider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.logout();

      if (!context.mounted) return;

      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  /// Handle delete account
  Future<void> _handleDeleteAccount(
      BuildContext context,
      AuthProvider authProvider,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await authProvider.deleteAccount();

      if (!context.mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to delete account',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet,
        size: 48,
      ),
      children: [
        const Text(
          'A production-level expense tracker app built with Flutter and Firebase.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
              '• Income & Expense tracking\n'
              '• Category-wise analytics\n'
              '• Monthly trends\n'
              '• Offline support\n'
              '• Cloud sync\n'
              '• PDF export',
        ),
      ],
    );
  }
}