import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../models/payment_model.dart';
import '../models/inventory_item_model.dart';

/// Thin wrapper around the Firestore collections. Collection and field
/// names follow the team's shared data dictionary so this stays
/// consistent with whatever your teammate builds against the same
/// project.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get customers => _db.collection('customers');
  CollectionReference<Map<String, dynamic>> get services => _db.collection('services');
  CollectionReference<Map<String, dynamic>> get payments => _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get expenses => _db.collection('expenses');
  CollectionReference<Map<String, dynamic>> get inventory => _db.collection('inventory');

  // ---- Orders ----

  Future<void> createOrder(LaundryOrder order) {
    return orders.doc(order.orderId).set(order.toFirestore());
  }

  Future<void> updateOrderStatus(String orderId, String status) {
    return orders.doc(orderId).update({
      'orderStatus': status,
      'updatedAt': DateTime.now(),
    });
  }

  Stream<List<LaundryOrder>> watchOrders() {
    return orders.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => LaundryOrder.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  // ---- Payments (Phase 9) ----

  /// Records a payment AND mirrors the latest status/amount onto the
  /// order itself, so screens that only need the order's current
  /// state don't have to join against the payments collection.
  Future<void> recordPayment(PaymentRecord payment) async {
    await payments.doc(payment.paymentId).set(payment.toFirestore());
    await orders.doc(payment.orderId).update({
      'paymentStatus': payment.paymentStatus,
      'paymentMethod': payment.paymentMethod,
      'totalAmount': payment.amountPaid,
      'updatedAt': DateTime.now(),
    });
  }

  // ---- Expenses (Phase 9) ----

  Future<void> logExpense(Expense expense) {
    return expenses.doc(expense.expenseId).set(expense.toFirestore());
  }

  Stream<List<Expense>> watchExpenses({required DateTime from, required DateTime to}) {
    return expenses
        .where('expenseDate', isGreaterThanOrEqualTo: from)
        .where('expenseDate', isLessThanOrEqualTo: to)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Expense.fromFirestore(d.data(), d.id)).toList());
  }

  // ---- Inventory stock (Phase 9) ----

  Future<void> upsertInventoryItem(InventoryItem item) {
    return inventory.doc(item.inventoryId).set(item.toFirestore());
  }

  Stream<List<InventoryItem>> watchInventory() {
    return inventory
        .snapshots()
        .map((snap) => snap.docs.map((d) => InventoryItem.fromFirestore(d.data(), d.id)).toList());
  }

  // ---- Dashboard math (Phase 11) ----

  /// Net profit = gross sales (paid/partial order totals in range)
  /// minus logged expenses in range.
  Future<double> computeNetProfit({required DateTime from, required DateTime to}) async {
    final orderSnap = await orders
        .where('createdAt', isGreaterThanOrEqualTo: from)
        .where('createdAt', isLessThanOrEqualTo: to)
        .get();

    final grossSales = orderSnap.docs.fold<double>(0, (sum, d) {
      final data = d.data();
      if (data['paymentStatus'] == PaymentStatus.unpaid) return sum;
      return sum + ((data['totalAmount'] ?? 0) as num).toDouble();
    });

    final expenseSnap = await expenses
        .where('expenseDate', isGreaterThanOrEqualTo: from)
        .where('expenseDate', isLessThanOrEqualTo: to)
        .get();

    final totalExpenses = expenseSnap.docs.fold<double>(
      0,
      (sum, d) => sum + ((d.data()['amount'] ?? 0) as num).toDouble(),
    );

    return grossSales - totalExpenses;
  }
}
