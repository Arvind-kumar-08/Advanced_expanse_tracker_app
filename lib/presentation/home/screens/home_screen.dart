import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../state/providers/auth_provider.dart';
import '../../../state/providers/transaction_provider.dart';
import '../widgets/balance_summary.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/transaction_list_screen.dart';

/// Home screen with dashboard and transaction list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load transactions on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUserId != null) {
        context.read<TransactionProvider>().loadTransactions();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on bottom nav selection
    switch (index) {
      case 0:
      // Home - already here
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.analytics);
        break;
      case 2:
      // Add transaction - handled by FAB
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
    }
  }

  Future<void> _handleRefresh() async {
    await context.read<TransactionProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.appName),
            if (authProvider.currentUser != null)
              Text(
                'Hi, ${authProvider.currentUser!.name}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          // Sync button
          IconButton(
            icon: transactionProvider.isSyncing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.sync),
            onPressed: transactionProvider.isSyncing
                ? null
                : () async {
              final success = await transactionProvider.syncData();
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? AppStrings.syncSuccess
                        : transactionProvider.errorMessage ??
                        'Sync failed',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: transactionProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
          slivers: [
            // Balance Summary Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BalanceSummary(
                  balance: transactionProvider.balance,
                  income: transactionProvider.totalIncome,
                  expense: transactionProvider.totalExpense,
                ),
              ),
            ),

            // Quick Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: AppStrings.income,
                        amount: transactionProvider.totalIncome,
                        icon: Icons.arrow_upward,
                        isIncome: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardCard(
                        title: AppStrings.expense,
                        amount: transactionProvider.totalExpense,
                        icon: Icons.arrow_downward,
                        isIncome: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.recentTransactions,
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (transactionProvider.transactions.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          // Show all transactions (could navigate to a new screen)
                          _showAllTransactions();
                        },
                        child: const Text(AppStrings.viewAll),
                      ),
                  ],
                ),
              ),
            ),

            // Transactions List
            transactionProvider.transactions.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.noTransactions,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.addYourFirst,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final transaction =
                    transactionProvider.recentTransactions[index];
                    return TransactionListItem(
                      transaction: transaction,
                      onTap: () => _editTransaction(transaction.id),
                      onDelete: () => _deleteTransaction(transaction.id),
                    );
                  },
                  childCount:
                  transactionProvider.recentTransactions.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addTransaction);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _editTransaction(String transactionId) {
    Navigator.pushNamed(
      context,
      AppRoutes.editTransaction,
      arguments: transactionId,
    );
  }

  Future<void> _deleteTransaction(String transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteTransaction),
        content: const Text(AppStrings.deleteConfirm),
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

    if (confirmed == true && mounted) {
      final success = await context
          .read<TransactionProvider>()
          .deleteTransaction(transactionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppStrings.transactionDeleted
                : 'Failed to delete transaction',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showAllTransactions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final transactions = context.read<TransactionProvider>().transactions;
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'All Transactions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return TransactionListItem(
                          transaction: transaction,
                          onTap: () {
                            Navigator.pop(context);
                            _editTransaction(transaction.id);
                          },
                          onDelete: () {
                            Navigator.pop(context);
                            _deleteTransaction(transaction.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}