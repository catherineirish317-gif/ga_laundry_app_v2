import 'package:hive_flutter/hive_flutter.dart';
import '../models/order_model.dart';

/// Box names — keep these constants in one place so every screen
/// references the same string instead of retyping it.
class HiveBoxes {
  static const pendingOrders = 'pending_orders';
  static const pendingStatusUpdates = 'pending_status_updates';
  static const cachedOrders = 'cached_orders';
  static const cachedCustomers = 'cached_customers';
}

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LaundryOrderAdapter());

    await Future.wait([
      Hive.openBox<LaundryOrder>(HiveBoxes.pendingOrders),
      Hive.openBox<Map>(HiveBoxes.pendingStatusUpdates),
      Hive.openBox<Map>(HiveBoxes.cachedOrders),
      Hive.openBox<Map>(HiveBoxes.cachedCustomers),
    ]);
  }

  static Box<LaundryOrder> get pendingOrdersBox =>
      Hive.box<LaundryOrder>(HiveBoxes.pendingOrders);

  static Box<Map> get pendingStatusUpdatesBox =>
      Hive.box<Map>(HiveBoxes.pendingStatusUpdates);

  static Box<Map> get cachedOrdersBox =>
      Hive.box<Map>(HiveBoxes.cachedOrders);

  static Box<Map> get cachedCustomersBox =>
      Hive.box<Map>(HiveBoxes.cachedCustomers);
}
