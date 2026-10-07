/// Payment Data: Payment ID, Order ID, Payment Method, Amount Paid,
/// Payment Date/Time, Payment Status, Recorded By.
/// Kept as its own collection (separate from the order's paymentStatus
/// field) so partial payments over time are all on record, not just
/// the latest one.
class PaymentRecord {
  final String paymentId;
  final String orderId;
  final String paymentMethod;
  final double amountPaid;
  final DateTime paymentDate;
  final String paymentStatus;
  final String recordedBy;

  PaymentRecord({
    required this.paymentId,
    required this.orderId,
    required this.paymentMethod,
    required this.amountPaid,
    required this.paymentStatus,
    required this.recordedBy,
    DateTime? paymentDate,
  }) : paymentDate = paymentDate ?? DateTime.now();

  factory PaymentRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return PaymentRecord(
      paymentId: id,
      orderId: data['orderId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'Unpaid',
      recordedBy: data['recordedBy'] ?? '',
      paymentDate: (data['paymentDate'] as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'amountPaid': amountPaid,
      'paymentStatus': paymentStatus,
      'recordedBy': recordedBy,
      'paymentDate': paymentDate,
    };
  }
}
