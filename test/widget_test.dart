import 'package:flutter_test/flutter_test.dart';
import 'package:advance_expanse_tracker_app/core/utils/validators.dart';
import 'package:advance_expanse_tracker_app/core/utils/date_formatter.dart';
import 'package:advance_expanse_tracker_app/data/models/transaction_model.dart';
import 'package:advance_expanse_tracker_app/data/models/category_model.dart';

void main() {
  group('Validators Tests', () {
    test('Email validation - valid email', () {
      expect(Validators.validateEmail('test@example.com'), null);
    });

    test('Email validation - invalid email', () {
      expect(Validators.validateEmail('invalid-email'), isNotNull);
    });

    test('Email validation - empty email', () {
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('Password validation - valid password', () {
      expect(Validators.validatePassword('password123'), null);
    });

    test('Password validation - too short', () {
      expect(Validators.validatePassword('123'), isNotNull);
    });

    test('Amount validation - valid amount', () {
      expect(Validators.validateAmount('100.50'), null);
    });

    test('Amount validation - invalid amount', () {
      expect(Validators.validateAmount('abc'), isNotNull);
    });

    test('Amount validation - zero amount', () {
      expect(Validators.validateAmount('0'), isNotNull);
    });

    test('Amount validation - negative amount', () {
      expect(Validators.validateAmount('-10'), isNotNull);
    });
  });

  group('DateFormatter Tests', () {
    test('Format date correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(DateFormatter.formatDate(date), 'Jan 15, 2024');
    });

    test('Format month year correctly', () {
      final date = DateTime(2024, 1, 15);
      expect(DateFormatter.formatMonthYear(date), 'Jan 2024');
    });

    test('Check if date is today', () {
      final today = DateTime.now();
      expect(DateFormatter.isToday(today), true);
    });

    test('Get month name correctly', () {
      expect(DateFormatter.getMonthName(1), 'January');
      expect(DateFormatter.getMonthName(12), 'December');
    });

    test('Get short month name correctly', () {
      expect(DateFormatter.getShortMonthName(1), 'Jan');
      expect(DateFormatter.getShortMonthName(12), 'Dec');
    });
  });

  group('TransactionModel Tests', () {
    test('Create transaction model', () {
      final transaction = TransactionModel.create(
        id: 'test-id',
        userId: 'user-123',
        amount: 100.0,
        category: 'Food',
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      expect(transaction.id, 'test-id');
      expect(transaction.amount, 100.0);
      expect(transaction.category, 'Food');
      expect(transaction.type, TransactionType.expense);
      expect(transaction.isSynced, false);
    });

    test('Mark transaction as synced', () {
      final transaction = TransactionModel.create(
        id: 'test-id',
        userId: 'user-123',
        amount: 100.0,
        category: 'Food',
        type: TransactionType.expense,
        date: DateTime.now(),
      );

      expect(transaction.isSynced, false);

      final syncedTransaction = transaction.markAsSynced();
      expect(syncedTransaction.isSynced, true);
    });

    test('Transaction to map and from map', () {
      final transaction = TransactionModel.create(
        id: 'test-id',
        userId: 'user-123',
        amount: 100.0,
        category: 'Food',
        type: TransactionType.expense,
        date: DateTime(2024, 1, 15),
        note: 'Test note',
      );

      final map = transaction.toMap();
      final fromMap = TransactionModel.fromMap(map);

      expect(fromMap.id, transaction.id);
      expect(fromMap.amount, transaction.amount);
      expect(fromMap.category, transaction.category);
      expect(fromMap.note, transaction.note);
    });
  });

  group('CategoryModel Tests', () {
    test('Get expense categories', () {
      final categories = CategoryModel.expenseCategories;
      expect(categories.isNotEmpty, true);
      expect(categories.any((cat) => cat.name == 'Food'), true);
    });

    test('Get income categories', () {
      final categories = CategoryModel.incomeCategories;
      expect(categories.isNotEmpty, true);
      expect(categories.any((cat) => cat.name == 'Salary'), true);
    });

    test('Get category by name', () {
      final category = CategoryModel.getCategoryByName('Food', false);
      expect(category, isNotNull);
      expect(category!.name, 'Food');
    });

    test('Get category color', () {
      final color = CategoryModel.getCategoryColor('Food');
      expect(color, isNotNull);
    });
  });
}