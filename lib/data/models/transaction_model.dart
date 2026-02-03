import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

/// Transaction model for income and expense records
@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final TransactionType type;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? note;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  @HiveField(9)
  final bool isSynced;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  /// Create new transaction
  factory TransactionModel.create({
    required String id,
    required String userId,
    required double amount,
    required String category,
    required TransactionType type,
    required DateTime date,
    String? note,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      amount: amount,
      category: category,
      type: type,
      date: date,
      note: note,
      createdAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'type': type.toString().split('.').last,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create TransactionModel from Firestore Map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: map['date'] != null
          ? DateTime.parse(map['date'])
          : DateTime.now(),
      note: map['note'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      isSynced: true, // Data from Firestore is considered synced
    );
  }

  /// Copy with method for updating fields
  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Mark as synced
  TransactionModel markAsSynced() {
    return copyWith(isSynced: true);
  }

  /// Mark as unsynced (for local changes)
  TransactionModel markAsUnsynced() {
    return copyWith(isSynced: false, updatedAt: DateTime.now());
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, category: $category, type: $type, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

/// Transaction type enum
@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  income,

  @HiveField(1)
  expense,
}