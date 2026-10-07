import 'package:hive/hive.dart';

part 'order_model.g.dart';

/// Field names here follow the Order Data / Laundry Item Data columns
/// from the team's shared data dictionary (Order ID, Customer ID,
/// Queue Number, Total Weight, Total Amount, Payment Status, Order
/// Status, Estimated Completion Time, Special Instructions).
class OrderStatus {
  static const received = 'Received';
  static const sorting = 'Sorting';
  static const washing = 'Washing';
  static const drying = 'Drying';
  static const readyForPickup = 'Ready for Pickup';
  static const claimed = 'Claimed';
}

class PaymentStatus {
  static const unpaid = 'Unpaid';
  static const partiallyPaid = 'Partially Paid';
  static const paid = 'Paid';
}

@HiveType(typeId: 0)
class LaundryOrder extends HiveObject {
  @HiveField(0)
  String orderId;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  String customerName;

  @HiveField(3)
  String category; // maps to Laundry Category Data (e.g. Thin/Regular, Thick/Heavy)

  @HiveField(4)
  double totalWeight;

  @HiveField(5)
  int queueNumber;

  @HiveField(6)
  String orderStatus;

  @HiveField(7)
  String paymentStatus;

  @HiveField(8)
  String paymentMethod;

  @HiveField(9)
  double totalAmount;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  @HiveField(12)
  bool pendingSync;

  @HiveField(13)
  DateTime? estimatedCompletionTime;

  @HiveField(14)
  String? specialInstructions;

  LaundryOrder({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.category,
    required this.totalWeight,
    required this.queueNumber,
    this.orderStatus = OrderStatus.received,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = 'Cash',
    this.totalAmount = 0,
    DateTime? createdAt,
    this.updatedAt,
    this.pendingSync = false,
    this.estimatedCompletionTime,
    this.specialInstructions,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LaundryOrder.fromFirestore(Map<String, dynamic> data, String id) {
    return LaundryOrder(
      orderId: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      category: data['category'] ?? '',
      totalWeight: (data['totalWeight'] ?? 0).toDouble(),
      queueNumber: data['queueNumber'] ?? 0,
      orderStatus: data['orderStatus'] ?? OrderStatus.received,
      paymentStatus: data['paymentStatus'] ?? PaymentStatus.unpaid,
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: data['updatedAt'] as DateTime?,
      estimatedCompletionTime: data['estimatedCompletionTime'] as DateTime?,
      specialInstructions: data['specialInstructions'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'category': category,
      'totalWeight': totalWeight,
      'queueNumber': queueNumber,
      'orderStatus': orderStatus,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
      'estimatedCompletionTime': estimatedCompletionTime,
      'specialInstructions': specialInstructions,
    };
  }
}
