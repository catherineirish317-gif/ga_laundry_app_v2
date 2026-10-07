import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import 'connectivity_service.dart';
import 'firestore_service.dart';
import 'hive_service.dart';

/// The single entry point screens call for every "write" action.
/// Callers never need to know whether the write landed in Firestore
/// or in a Hive pending box — see the Phase 10 handoff note in the
/// roadmap doc.
class SyncService {
  final FirestoreService _firestore;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _sub;

  SyncService({
    FirestoreService? firestoreService,
    ConnectivityService? connectivityService,
  })  : _firestore = firestoreService ?? FirestoreService(),
        _connectivity = connectivityService ?? ConnectivityService();

  /// Call once from main() after Hive/Firebase are initialized.
  /// Listens for connectivity coming back and flushes queued writes.
  void startListening() {
    _sub = _connectivity.onStatusChange.listen((online) {
      if (online) flushPendingQueue();
    });
  }

  void dispose() => _sub?.cancel();

  // ---- Writes (called from screens) ----

  Future<void> submitOrder(LaundryOrder order) async {
    final online = await _connectivity.isOnline();
    if (online) {
      await _firestore.createOrder(order);
    } else {
      order.pendingSync = true;
      await HiveService.pendingOrdersBox.put(order.orderId, order);
    }
  }

  Future<void> submitStatusUpdate(String orderId, String status) async {
    final online = await _connectivity.isOnline();
    if (online) {
      await _firestore.updateOrderStatus(orderId, status);
    } else {
      await HiveService.pendingStatusUpdatesBox.put(
        const Uuid().v4(),
        {'orderId': orderId, 'status': status, 'queuedAt': DateTime.now().toIso8601String()},
      );
    }
  }

  // ---- Sync back on reconnect ----

  /// Pushes queued Hive entries to Firestore in order, then clears them.
  /// Order creation goes first so status updates always have a parent
  /// document to attach to.
  Future<void> flushPendingQueue() async {
    final ordersBox = HiveService.pendingOrdersBox;
    for (final key in ordersBox.keys.toList()) {
      final order = ordersBox.get(key);
      if (order == null) continue;
      await _firestore.createOrder(order);
      await ordersBox.delete(key);
    }

    final statusBox = HiveService.pendingStatusUpdatesBox;
    for (final key in statusBox.keys.toList()) {
      final entry = statusBox.get(key);
      if (entry == null) continue;
      await _firestore.updateOrderStatus(
        entry['orderId'] as String,
        entry['status'] as String,
      );
      await statusBox.delete(key);
    }
    // Note: the push-notification Cloud Functions trigger on the Firestore
    // write itself, so a synced offline order still sends its push here
    // with no extra logic needed (see Phase 7).
  }

  int get pendingCount =>
      HiveService.pendingOrdersBox.length +
          HiveService.pendingStatusUpdatesBox.length;
}