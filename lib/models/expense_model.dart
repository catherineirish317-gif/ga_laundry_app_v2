/// Expense Data: Expense ID, Expense Category, Description, Amount,
/// Expense Date, Payment Method, Recorded By, Remarks.
class Expense {
  final String expenseId;
  final String expenseCategory; // e.g. Detergent, Fabric Softener, Water/Electricity, Other
  final String description;
  final double amount;
  final DateTime expenseDate;
  final String paymentMethod;
  final String recordedBy;
  final String? remarks;

  Expense({
    required this.expenseId,
    required this.expenseCategory,
    required this.description,
    required this.amount,
    required this.recordedBy,
    this.paymentMethod = 'Cash',
    DateTime? expenseDate,
    this.remarks,
  }) : expenseDate = expenseDate ?? DateTime.now();

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      expenseId: id,
      expenseCategory: data['expenseCategory'] ?? 'Other',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      recordedBy: data['recordedBy'] ?? '',
      expenseDate: (data['expenseDate'] as DateTime?) ?? DateTime.now(),
      remarks: data['remarks'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expenseCategory': expenseCategory,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'recordedBy': recordedBy,
      'expenseDate': expenseDate,
      'remarks': remarks,
    };
  }
}
