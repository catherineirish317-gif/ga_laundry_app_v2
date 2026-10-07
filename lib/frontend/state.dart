import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';

/// One saved sale (money received). Cash is saved when the order is claimed,
/// GCash/PayMaya when the order is placed.
class SalesRecord {
  final DateTime date;
  final double amount;
  final String orderId;
  final String method; // 'Cash', 'GCash', 'PayMaya', ...

  SalesRecord({required this.date, required this.amount, required this.orderId, required this.method});
}

/// A staff member account shown in the admin Staff page.
class StaffAccount {
  final String id;
  String name;
  String role;
  String phone;
  String username;
  bool active;

  StaffAccount({required this.id, required this.name, required this.role, this.phone = '', this.username = '', this.active = true});
}

/// One piece of customer feedback for an order.
class FeedbackEntry {
  final String id;
  final String orderId;
  final String customerName;
  final int rating; // 1-5
  final String comment; // already cleaned (links removed, bad words masked)
  final bool autoFiltered; // true when the system had to clean the comment
  final DateTime date;
  String status; // 'New', 'Reviewed', 'Resolved', 'Hidden'
  String adminReply;

  FeedbackEntry({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.date,
    this.autoFiltered = false,
    this.status = 'New',
    this.adminReply = '',
  });
}

/// An extra supply tracked by hand (alternative detergents, bleaches, stain removers, scent boosters...).
class InventoryItem {
  final String id;
  final String group;
  final String name;
  final String note;
  final String unit;
  double stock;
  double capacity; // "full" stock
  double alertLevel; // low-stock alert when stock is at or below this

  InventoryItem({
    required this.id,
    required this.group,
    required this.name,
    required this.note,
    required this.unit,
    required this.stock,
    required this.capacity,
    required this.alertLevel,
  });

  bool get low => stock <= alertLevel;
}

/// One automatic inventory deduction (made when the admin claims an order).
class InventoryUsage {
  final String orderId;
  final double powderGrams;
  final double softenerMl;
  final DateTime time;

  InventoryUsage({required this.orderId, required this.powderGrams, required this.softenerMl, required this.time});
}

/// One address the customer saved. The first one in the list is the default.
class SavedAddress {
  final String id;
  String label;
  String address;
  SavedAddress({required this.id, required this.label, required this.address});
}

/// One GCash / PayMaya account the customer saved.
class SavedPaymentMethod {
  final String id;
  final String type; // 'GCash' or 'PayMaya'
  final String accountName;
  final String phone;
  SavedPaymentMethod({required this.id, required this.type, required this.accountName, required this.phone});
}

class AppState extends ChangeNotifier {
  // Authentication & Session
  bool _isAuthenticated = false;
  UserRole _currentRole = UserRole.customer;
  String _loggedInName = 'Maria Santos';
  String _loggedInPhone = '0917-823-4591';

  bool get isAuthenticated => _isAuthenticated;
  UserRole get currentRole => _currentRole;
  String get loggedInName => _loggedInName;
  String get loggedInPhone => _loggedInPhone;

  // Offline Mode State
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  // Active navigation tab
  int currentTab = 0;

  // Mock Data: Customers
  final List<CustomerModel> customers = [
    CustomerModel(
      id: 'cust-1',
      name: 'Maria Santos',
      phone: '0917-823-4591',
      address: 'Block 4, Lot 12, Sunrise Subdivision',
      notes: 'Gentle on floral dresses.',
      totalOrders: 14,
      totalSpent: 4250,
      loyaltyPoints: 0,
      registeredDate: '2026-02-10',
    ),
    CustomerModel(
      id: 'cust-2',
      name: 'Kenneth Dela Cruz',
      phone: '0928-554-1290',
      address: 'Unit 302, Vista Residences',
      notes: 'Work uniforms. Fold neatly.',
      totalOrders: 8,
      totalSpent: 2680,
      loyaltyPoints: 8,
      registeredDate: '2026-03-01',
    ),
  ];

  // Mock Data: Orders
  late List<LaundryOrderModel> orders;

  // Mock Data: Machines
  final List<LaundryMachineModel> machines = [
    LaundryMachineModel(id: 'm-w1', name: 'Washer #1 (7kg)', type: 'Washer', capacityKg: 7, status: 'Available'),
    LaundryMachineModel(id: 'm-w2', name: 'Washer #2 (10kg)', type: 'Washer', capacityKg: 10, status: 'Running', timeRemainingMinutes: 18),
    LaundryMachineModel(id: 'm-d1', name: 'Dryer #1 (8kg)', type: 'Dryer', capacityKg: 8, status: 'Available'),
    LaundryMachineModel(id: 'm-d2', name: 'Dryer #2 (11kg)', type: 'Dryer', capacityKg: 11, status: 'Maintenance'),
  ];

  // Editable laundry package rates (admin edits them, the customer order form reads them)
  final Map<String, double> packageRates = {
    'regular': 170.0,
    'whites': 185.0,
    'baby': 185.0,
    'bedding': 200.0,
    'single': 200.0,
    'double': 200.0,
    'denim': 200.0,
    'wash': 60.0,
    'dry': 60.0,
    'fold': 30.0,
    'extraWash': 20.0,
    'extraDetergent': 20.0,
    'extraFabcon': 20.0,
  };

  double rateOf(String key) => packageRates[key] ?? 0.0;

  void updateRate(String key, double value) {
    packageRates[key] = value;
    notifyListeners();
  }

  // ---------- Shop hours (closing-hours notice) ----------
  static const int openHour = 8; // 8 AM
  static const int closeHour = 17; // 5 PM
  static const bool ignoreHours = false; // set to true to test while the shop is "closed"

  /// Open Monday to Saturday, 8 AM to 5 PM. Sundays are drop off only (no online orders).
  bool get isShopOpen {
    if (ignoreHours) return true;
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday) return false;
    return now.hour >= openHour && now.hour < closeHour;
  }

  String get shopClosedMessage {
    if (DateTime.now().weekday == DateTime.sunday) {
      return "Sundays are drop off only. Online orders are not available today. Please come back Monday to Saturday, 8 AM to 5 PM.";
    }
    return "The shop is closed right now. We are open Monday to Saturday, 8 AM to 5 PM (Sundays: drop off only). You can place an order when we open.";
  }

  // ---------- Saved addresses (customer) ----------
  final List<SavedAddress> savedAddresses = [
    SavedAddress(id: 'addr-1', label: 'Home', address: 'Block 4, Lot 12, Sunrise Subdivision'),
  ];

  SavedAddress? get defaultAddress => savedAddresses.isEmpty ? null : savedAddresses.first;

  void addAddress(String label, String address, {bool makeDefault = false}) {
    final a = SavedAddress(id: 'addr-${DateTime.now().microsecondsSinceEpoch}', label: label.trim(), address: address.trim());
    if (makeDefault) {
      savedAddresses.insert(0, a);
    } else {
      savedAddresses.add(a);
    }
    notifyListeners();
  }

  void removeAddress(String id) {
    savedAddresses.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void makeDefaultAddress(String id) {
    final i = savedAddresses.indexWhere((a) => a.id == id);
    if (i <= 0) return;
    savedAddresses.insert(0, savedAddresses.removeAt(i));
    notifyListeners();
  }

  // ---------- Saved payment methods (customer) ----------
  final List<SavedPaymentMethod> savedPaymentMethods = [];

  void addPaymentMethod({required String type, required String accountName, required String phone}) {
    savedPaymentMethods.add(SavedPaymentMethod(
      id: 'pm-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      accountName: accountName.trim(),
      phone: phone.trim(),
    ));
    notifyListeners();
  }

  void removePaymentMethod(String id) {
    savedPaymentMethods.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ---------- Shop QR codes (admin uploads, customers pay with them) ----------
  Uint8List? gcashQr;
  Uint8List? paymayaQr;

  Uint8List? qrFor(String method) => method == 'GCash' ? gcashQr : (method == 'PayMaya' ? paymayaQr : null);

  void setQr(String method, Uint8List? bytes) {
    if (method == 'GCash') gcashQr = bytes;
    if (method == 'PayMaya') paymayaQr = bytes;
    notifyListeners();
  }

  // ---------- Customer feedback ----------
  /// SAMPLE DATA so the feedback filters have something to show in the prototype.
  /// Set to false to start with no feedback.
  static const bool seedSampleFeedback = true;

  static const List<String> feedbackStatuses = ['New', 'Reviewed', 'Resolved', 'Hidden'];
  final List<FeedbackEntry> feedbacks = [];

  static const int maxFeedbackLength = 300;

  static final RegExp _badWords = RegExp(
    r'\b(?:fuck(?:ing|ed|er)?|shit(?:ty)?|bitch|asshole|bastard|putang\s*ina(?:mo)?|puta|tangina(?:mo)?|tang\s*ina|gago|gaga|bobo|ulol|tarantado|tarantada|leche|pakyu)\b',
    caseSensitive: false,
  );
  static final RegExp _links = RegExp(r'(https?://\S+|www\.\S+)', caseSensitive: false);

  /// Cleans a customer comment: trims and collapses spaces, removes links,
  /// masks bad words (like g***) and limits the length.
  static String sanitizeFeedback(String raw) {
    var t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    t = t.replaceAll(_links, '[link removed]');
    t = t.replaceAllMapped(_badWords, (m) {
      final w = m[0]!;
      return w[0] + '*' * (w.length - 1);
    });
    if (t.length > maxFeedbackLength) t = t.substring(0, maxFeedbackLength);
    return t;
  }

  bool hasFeedbackFor(String orderId) => feedbacks.any((f) => f.orderId == orderId);

  FeedbackEntry? feedbackFor(String orderId) {
    for (final f in feedbacks) {
      if (f.orderId == orderId) return f;
    }
    return null;
  }

  int get newFeedbackCount => feedbacks.where((f) => f.status == 'New').length;

  /// Average of all feedback that is not hidden.
  double get averageRating {
    final visible = feedbacks.where((f) => f.status != 'Hidden').toList();
    if (visible.isEmpty) return 0.0;
    return visible.fold(0, (sum, f) => sum + f.rating) / visible.length;
  }

  /// Returns an error message to show to the customer, or null when it was saved.
  String? submitFeedback({
    required String orderId,
    required String customerName,
    required int rating,
    required String comment,
  }) {
    if (rating < 1 || rating > 5) return 'Please tap a star rating first!';
    if (hasFeedbackFor(orderId)) return 'You already sent feedback for this order. Thank you!';

    final cleaned = sanitizeFeedback(comment);
    final bool filtered = _badWords.hasMatch(comment) || _links.hasMatch(comment);

    feedbacks.insert(
      0,
      FeedbackEntry(
        id: 'fb-${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        customerName: customerName,
        rating: rating,
        comment: cleaned,
        autoFiltered: filtered,
        date: DateTime.now(),
      ),
    );

    notifications.insert(
      0,
      AppNotification(
        id: 'fb-n-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Feedback ($rating/5)',
        message: '$customerName left feedback for order $orderId.',
        time: 'Just now',
        icon: Icons.rate_review_rounded,
        type: 'order_alert',
        relatedOrderId: orderId,
      ),
    );
    notifyListeners();
    return null;
  }

  void setFeedbackStatus(String id, String status) {
    final f = feedbacks.firstWhere((e) => e.id == id);
    f.status = status;
    addSecurityLog('Admin John', 'Marked feedback ${f.orderId} as $status', 'Success');
  }

  void replyToFeedback(String id, String reply) {
    final text = reply.trim();
    if (text.isEmpty) return;
    final f = feedbacks.firstWhere((e) => e.id == id);
    f.adminReply = sanitizeFeedback(text);
    if (f.status == 'New') f.status = 'Reviewed';

    // Only notify the customer when this is the logged-in customer's own order.
    if (_customerOrders.any((o) => o.id == f.orderId)) {
      _customerNotifications.insert(
        0,
        AppNotification(
          id: 'cn-fb-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Reply to your feedback',
          message: 'G A Laundry Shop replied: ${f.adminReply}',
          time: 'Just now',
          icon: Icons.reply_rounded,
          type: 'order_update',
        ),
      );
    }
    addSecurityLog('Admin John', 'Replied to feedback ${f.orderId}', 'Success');
  }

  void _seedSampleFeedback() {
    if (!seedSampleFeedback) return;
    final now = DateTime.now();
    feedbacks.addAll([
      FeedbackEntry(id: 'fb-s1', orderId: 'Q-090', customerName: 'Maria Santos', rating: 5, comment: 'Sobrang linis at mabango ng labada, salamat po!', date: now.subtract(const Duration(hours: 3)), status: 'New'),
      FeedbackEntry(id: 'fb-s2', orderId: 'Q-088', customerName: 'Teddy B. Comendador', rating: 3, comment: 'Medyo natagalan po ang pick-up pero okay naman ang service.', date: now.subtract(const Duration(days: 1)), status: 'New'),
      FeedbackEntry(id: 'fb-s3', orderId: 'Q-085', customerName: 'Nolram Gonzalo', rating: 1, comment: 'May butas po yung isang damit ko pagkabalik.', date: now.subtract(const Duration(days: 2)), status: 'Reviewed'),
      FeedbackEntry(id: 'fb-s4', orderId: 'Q-081', customerName: 'Lisa Cambia Comendador', rating: 5, comment: 'Mabilis at mura! Babalik po ulit kami.', date: now.subtract(const Duration(days: 4)), status: 'Resolved', adminReply: 'Salamat po! Hanggang sa muli.'),
      FeedbackEntry(id: 'fb-s5', orderId: 'Q-079', customerName: 'Jhayrenz Rotal', rating: 2, comment: 'G**o naman yung delivery, late na late!', date: now.subtract(const Duration(days: 6)), autoFiltered: true, status: 'New'),
    ]);
  }

  // ---------- Inventory (admin can edit stock and alert levels) ----------
  double detergentStockKg = 18.4;
  double softenerStockL = 12.2;
  double detergentCapacityKg = 25.0; // "full" stock
  double softenerCapacityL = 20.0;
  double detergentAlertKg = 5.0; // low-stock alert when stock is at or below this
  double softenerAlertL = 4.0;

  // Other supplies. Starting stock numbers are placeholders: the admin edits them in the Inventory screen.
  static const List<String> extraInventoryGroups = [
    'Alternative Detergents',
    'Bleaches',
    'Stain Removers & Pre-treaters',
    'Scent Boosters & Sanitizers',
  ];

  final List<InventoryItem> extraInventory = [
    // Alternative Detergents
    InventoryItem(id: 'liquid', group: 'Alternative Detergents', name: 'Liquid Detergent', note: 'Preferred for high-efficiency / front-load washers', unit: 'L', stock: 12, capacity: 20, alertLevel: 4),
    InventoryItem(id: 'eco', group: 'Alternative Detergents', name: 'Eco-Friendly Detergent', note: 'Eco-friendly cleaning solution', unit: 'L', stock: 8, capacity: 15, alertLevel: 3),
    InventoryItem(id: 'wool', group: 'Alternative Detergents', name: 'Wool & Delicate Wash', note: 'For wool and delicate fabrics', unit: 'L', stock: 5, capacity: 10, alertLevel: 2),
    // Bleaches
    InventoryItem(id: 'chlorine', group: 'Bleaches', name: 'Chlorine Bleach', note: 'For white fabrics', unit: 'L', stock: 10, capacity: 20, alertLevel: 4),
    InventoryItem(id: 'oxygen', group: 'Bleaches', name: 'Color-Safe (Oxygen) Bleach', note: 'For colored garments', unit: 'kg', stock: 6, capacity: 10, alertLevel: 2),
    // Stain Removers & Pre-treaters
    InventoryItem(id: 'spotter', group: 'Stain Removers & Pre-treaters', name: 'Solvent-Based Spotter', note: 'Ink, grease and oil stains', unit: 'bottles', stock: 6, capacity: 12, alertLevel: 3),
    InventoryItem(id: 'enzyme', group: 'Stain Removers & Pre-treaters', name: 'Enzymatic Stain Remover', note: 'Protein and food stains', unit: 'L', stock: 5, capacity: 10, alertLevel: 2),
    InventoryItem(id: 'collar', group: 'Stain Removers & Pre-treaters', name: 'Collar & Cuff Spray', note: 'Pre-treat collars, cuffs, rust stains', unit: 'bottles', stock: 8, capacity: 15, alertLevel: 3),
    // Scent Boosters & Sanitizers
    InventoryItem(id: 'disinfectant', group: 'Scent Boosters & Sanitizers', name: 'Laundry Disinfectant', note: 'Kills germs and bacteria', unit: 'L', stock: 8, capacity: 15, alertLevel: 3),
    InventoryItem(id: 'booster', group: 'Scent Boosters & Sanitizers', name: 'In-Wash Scent Booster', note: 'Added to the wash for extra scent', unit: 'kg', stock: 4, capacity: 8, alertLevel: 2),
    InventoryItem(id: 'neutralizer', group: 'Scent Boosters & Sanitizers', name: 'Odor Neutralizer', note: 'For heavy odors', unit: 'L', stock: 5, capacity: 10, alertLevel: 2),
  ];

  List<InventoryItem> get lowExtraItems => extraInventory.where((i) => i.low).toList();

  InventoryItem _extraById(String id) => extraInventory.firstWhere((i) => i.id == id);

  void restockExtra(String id, double amount) {
    final item = _extraById(id);
    final next = item.stock + amount;
    item.stock = next > item.capacity ? item.capacity : next;
    notifyListeners();
  }

  void markExtraFull(String id) {
    final item = _extraById(id);
    item.stock = item.capacity;
    notifyListeners();
  }

  /// Manual use (these supplies are not deducted automatically).
  void useExtra(String id, double amount) {
    final item = _extraById(id);
    final bool wasLow = item.low;
    final next = item.stock - amount;
    item.stock = next < 0 ? 0.0 : next;
    if (!wasLow && item.low) {
      notifications.insert(
        0,
        AppNotification(
          id: 'inv-$id-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Low Stock: ${item.name}',
          message: '${item.name} is down to ${item.stock.toStringAsFixed(1)} ${item.unit}. Time to restock!',
          time: 'Just now',
          icon: Icons.inventory_2_rounded,
          type: 'order_alert',
        ),
      );
    }
    notifyListeners();
  }

  void updateExtra(String id, {double? stock, double? alertLevel, double? capacity}) {
    final item = _extraById(id);
    if (capacity != null) item.capacity = capacity;
    if (stock != null) item.stock = stock;
    if (alertLevel != null) item.alertLevel = alertLevel;
    notifyListeners();
  }

  // ---------- Staff accounts ----------
  final List<StaffAccount> staffAccounts = [
    StaffAccount(id: 'staff-1', name: 'Juan Dela Cruz', role: 'Washing Staff'),
    StaffAccount(id: 'staff-2', name: 'Rina Reyes', role: 'Folding & Packing'),
    StaffAccount(id: 'staff-3', name: 'Kenneth Santos', role: 'Delivery Rider'),
  ];

  void addStaff({required String name, required String role, String phone = '', String username = ''}) {
    staffAccounts.add(StaffAccount(
      id: 'staff-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      role: role,
      phone: phone,
      username: username,
    ));
    notifyListeners();
  }

  void setStaffActive(String id, bool active) {
    staffAccounts.firstWhere((s) => s.id == id).active = active;
    notifyListeners();
  }

  void removeStaff(String id) {
    staffAccounts.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  final List<InventoryUsage> inventoryLog = [];
  final Set<String> _inventoryDeducted = {};

  bool get detergentLow => detergentStockKg <= detergentAlertKg;
  bool get softenerLow => softenerStockL <= softenerAlertL;

  /// Kilos of clothes assumed for one load of each category
  /// (the customer app does not ask for the weight).
  static const Map<String, double> categoryLoadKg = {
    'Regular Clothes': 8.0,
    'Whites (Max 7kg)': 7.0,
    'Baby Clothes (Max 7kg)': 7.0,
    'Beddings / Curtains': 8.0,
    'Single Size Comforter': 5.0,
    'Double Size Comforter': 7.0,
    'Denim, Cargo, Jackets': 6.0,
  };
  static const Set<String> heavyCategories = {
    'Beddings / Curtains',
    'Single Size Comforter',
    'Double Size Comforter',
    'Denim, Cargo, Jackets',
  };

  /// Usage per load: [powder in grams, fabric softener in ml].
  /// Normal clothes: 10 g and 6.25 ml per kg  -> 8 kg = 80 g powder, 50 ml softener.
  /// Heavy fabrics:  12.5 g and 10 ml per kg  -> 8 kg = 100 g powder, 80 ml softener.
  static List<double> usageFor(double kg, {required bool heavy}) {
    return [kg * (heavy ? 12.5 : 10.0), kg * (heavy ? 10.0 : 6.25)];
  }

  void updateInventory({required bool detergent, double? stock, double? alertLevel, double? capacity}) {
    if (detergent) {
      if (capacity != null) detergentCapacityKg = capacity;
      if (stock != null) detergentStockKg = stock;
      if (alertLevel != null) detergentAlertKg = alertLevel;
    } else {
      if (capacity != null) softenerCapacityL = capacity;
      if (stock != null) softenerStockL = stock;
      if (alertLevel != null) softenerAlertL = alertLevel;
    }
    notifyListeners();
  }

  /// Adds newly bought stock (stops at the "full" capacity).
  void restockInventory(bool detergent, double amount) {
    if (detergent) {
      final next = detergentStockKg + amount;
      detergentStockKg = next > detergentCapacityKg ? detergentCapacityKg : next;
    } else {
      final next = softenerStockL + amount;
      softenerStockL = next > softenerCapacityL ? softenerCapacityL : next;
    }
    notifyListeners();
  }

  void markInventoryFull(bool detergent) {
    if (detergent) {
      detergentStockKg = detergentCapacityKg;
    } else {
      softenerStockL = softenerCapacityL;
    }
    notifyListeners();
  }

  /// Called when the admin claims an order in Order Management.
  void _deductInventoryForClaim(String orderId, Order? customerOrder, LaundryOrderModel? adminOrder) {
    final String key = customerOrder?.id ?? adminOrder?.id ?? orderId;
    if (!_inventoryDeducted.add(key)) return; // never deduct twice for the same order

    double powderG = 0;
    double softenerMl = 0;

    if (customerOrder != null) {
      // Dry-only / fold-only orders do not use detergent or softener.
      if (customerOrder.service.contains('Wash')) {
        bool anyMatched = false;
        categoryLoadKg.forEach((name, kg) {
          if (customerOrder.category.contains(name)) {
            anyMatched = true;
            final u = usageFor(kg, heavy: heavyCategories.contains(name));
            powderG += u[0];
            softenerMl += u[1];
          }
        });
        if (!anyMatched) {
          final u = usageFor(categoryLoadKg['Regular Clothes']!, heavy: false);
          powderG += u[0];
          softenerMl += u[1];
        }
        if (customerOrder.addons.contains('Extra Detergent')) powderG *= 2;
        if (customerOrder.addons.contains('Extra Fabcon')) softenerMl *= 2;
      }
    } else if (adminOrder != null) {
      final svc = adminOrder.serviceType;
      if (!svc.contains('Dry Only') && !svc.contains('Fold Only')) {
        final u = usageFor(adminOrder.weightKg, heavy: adminOrder.fabricCategory == FabricCategory.thickHeavy);
        powderG = u[0];
        softenerMl = u[1];
      }
    }

    if (powderG <= 0 && softenerMl <= 0) return;

    final bool detergentWasLow = detergentLow;
    final bool softenerWasLow = softenerLow;
    final double newDetergent = detergentStockKg - powderG / 1000;
    final double newSoftener = softenerStockL - softenerMl / 1000;
    detergentStockKg = newDetergent < 0 ? 0.0 : newDetergent;
    softenerStockL = newSoftener < 0 ? 0.0 : newSoftener;

    inventoryLog.insert(0, InventoryUsage(orderId: key, powderGrams: powderG, softenerMl: softenerMl, time: DateTime.now()));
    if (inventoryLog.length > 30) inventoryLog.removeLast();

    // Alert the admin once, when stock first drops to the alert level.
    if (!detergentWasLow && detergentLow) {
      notifications.insert(
        0,
        AppNotification(
          id: 'inv-d-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Low Stock: Detergent Powder',
          message: 'Detergent powder is down to ${detergentStockKg.toStringAsFixed(2)} kg. Time to restock!',
          time: 'Just now',
          icon: Icons.inventory_2_rounded,
          type: 'order_alert',
        ),
      );
    }
    if (!softenerWasLow && softenerLow) {
      notifications.insert(
        0,
        AppNotification(
          id: 'inv-s-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Low Stock: Fabric Softener',
          message: 'Fabric softener is down to ${softenerStockL.toStringAsFixed(2)} L. Time to restock!',
          time: 'Just now',
          icon: Icons.inventory_2_rounded,
          type: 'order_alert',
        ),
      );
    }
  }

  // Notifications List
  final List<AppNotification> notifications = [];

  AppState() {
    orders = [];
    _seedSampleSalesHistory();
    _seedSampleFeedback();
  }

  // ---------- Sales ledger: every sale is saved with its date ----------
  /// SAMPLE DATA: fills the past ~14 months so the Sales & Revenue Reports filters
  /// (last week / last month / last year) have something to show in the prototype.
  /// Set to false once real sales come from Firestore.
  static const bool seedSampleSalesHistory = true;

  final List<SalesRecord> salesLedger = [];
  final List<DateTime> orderLog = []; // when each order was placed
  final Set<String> _recordedSaleIds = {};

  static DateTime dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime weekStart(DateTime d) => dayStart(d).subtract(Duration(days: d.weekday - 1)); // Monday

  void _seedSampleSalesHistory() {
    if (!seedSampleSalesHistory) return;
    final today = dayStart(DateTime.now());
    for (int d = 1; d <= 420; d++) {
      if (d % 13 == 0) continue; // shop closed that day
      final day = today.subtract(Duration(days: d));
      final int n = 2 + ((d * 7 + d ~/ 3) % 6);
      for (int k = 0; k < n; k++) {
        final when = day.add(Duration(hours: 8 + k));
        salesLedger.add(SalesRecord(
          date: when,
          amount: 170.0 + ((d + k) % 4) * 15.0,
          orderId: 'sample-$d-$k',
          method: (d + k) % 3 == 0 ? 'Cash' : 'GCash',
        ));
        orderLog.add(when);
      }
    }
  }

  /// Saves a sale once per order.
  void recordSale(String orderId, double amount, String method) {
    if (amount <= 0) return;
    if (!_recordedSaleIds.add(orderId)) return;
    salesLedger.add(SalesRecord(date: DateTime.now(), amount: amount, orderId: orderId, method: method));
  }

  /// Range helpers: from start (included) up to end (not included)
  double salesInRange(DateTime start, DateTime end) => salesLedger
      .where((r) => !r.date.isBefore(start) && r.date.isBefore(end))
      .fold(0.0, (sum, r) => sum + r.amount);

  int salesCountInRange(DateTime start, DateTime end) =>
      salesLedger.where((r) => !r.date.isBefore(start) && r.date.isBefore(end)).length;

  double cashSalesInRange(DateTime start, DateTime end) => salesLedger
      .where((r) => !r.date.isBefore(start) && r.date.isBefore(end) && r.method == 'Cash')
      .fold(0.0, (sum, r) => sum + r.amount);

  int ordersPlacedInRange(DateTime start, DateTime end) =>
      orderLog.where((d) => !d.isBefore(start) && d.isBefore(end)).length;

  double get salesThisWeek {
    final start = weekStart(DateTime.now());
    return salesInRange(start, start.add(const Duration(days: 7)));
  }

  int get ordersThisWeek {
    final start = weekStart(DateTime.now());
    return ordersPlacedInRange(start, start.add(const Duration(days: 7)));
  }

  /// Orders placed per weekday (Mon..Sun) in the current week.
  List<int> ordersPerDayThisWeek() {
    final start = weekStart(DateTime.now());
    return List.generate(7, (i) {
      final from = start.add(Duration(days: i));
      return ordersPlacedInRange(from, from.add(const Duration(days: 1)));
    });
  }

  void login(UserRole role, {String? customName, String? customPhone}) {
    _isAuthenticated = true;
    _currentRole = role;
    if (role == UserRole.customer) {
      _loggedInName = customName ?? 'Maria Santos';
      _loggedInPhone = customPhone ?? '0917-823-4591';
    } else {
      _loggedInName = 'Admin John';
      _loggedInPhone = '0999-999-9999';
    }
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    currentTab = 0;
    notifyListeners();
  }

  void toggleOffline(bool val) {
    _isOffline = val;
    notifyListeners();
  }

  void updateTab(int index) {
    currentTab = index;
    notifyListeners();
  }

  LaundryOrderModel createOrder({
    required CustomerModel customer,
    required String serviceType,
    required FabricCategory category,
    required double weightKg,
    required double totalAmount,
    required String paymentStatus,
    String? paymentMethod,
  }) {
    final nextId = 100 + orders.length + 1;
    final qNumber = 'Q-$nextId';
    final recommendation = BatchRecommendation.calculate(weightKg, category);

    final newOrder = LaundryOrderModel(
      id: 'ord-$nextId',
      queueNumber: qNumber,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      serviceType: serviceType,
      fabricCategory: category,
      weightKg: weightKg,
      batchRecommendation: recommendation,
      status: 'Received',
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      createdAt: 'Just now',
      estimatedReadyTime: 'In 2.5 hours',
      staffNotes: 'New order.',
      isOfflineSyncPending: _isOffline,
    );

    orders.insert(0, newOrder);
    orderLog.add(DateTime.now());
    if (paymentStatus == 'Paid') recordSale(newOrder.id, totalAmount, paymentMethod ?? 'Cash');

    // Update customer stats
    customer.totalOrders += 1;
    customer.totalSpent += totalAmount;

    notifyListeners();
    return newOrder;
  }

  // Customer Specific Getters & Helpers
  String get currentFullName => _loggedInName;
  String get currentPhone => _loggedInPhone;
  String get currentEmail => 'maria.santos@gmail.com';
  String get currentAddress => 'Block 4, Lot 12, Sunrise Subdivision';
  String get currentUsername => 'maria_santos';
  String? get currentCustomerId => 'cust-1';

  // Loyalty stamps: 1 claimed order = 1 stamp. 10/10 stamps = 1 free laundry.
  static const int stampsForFreeLaundry = 10;
  int _customerLoyaltyPoints = 0;
  int get customerLoyaltyPoints => _customerLoyaltyPoints;
  bool get hasFreeLaundry => _customerLoyaltyPoints >= stampsForFreeLaundry;

  /// Called after a Free Laundry order is placed: the card goes back to 0/10.
  void redeemFreeLaundry() {
    if (!hasFreeLaundry) return;
    _customerLoyaltyPoints = 0;
    for (final c in customers) {
      if (c.phone == _loggedInPhone) c.loyaltyPoints = 0;
    }
    notifyListeners();
  }

  // Initial Customer Orders (Starts clean for new customer session)
  final List<Order> _customerOrders = [];

  List<Order> get customerOrders => _customerOrders;

  Order? get activeOrder {
    try {
      return _customerOrders.firstWhere((o) => o.status != 'Claimed');
    } catch (_) {
      return null;
    }
  }

  void addOrder(Order newOrder) {
    _customerOrders.insert(0, newOrder);

    // Also create matching LaundryOrderModel for Admin Queue
    final lOrder = LaundryOrderModel(
      id: newOrder.id,
      queueNumber: newOrder.id,
      customerId: 'cust-1',
      customerName: newOrder.customerName,
      customerPhone: newOrder.phone,
      serviceType: newOrder.service,
      fabricCategory: FabricCategory.thinRegular,
      weightKg: 5.0,
      batchRecommendation: BatchRecommendation.calculate(5.0, FabricCategory.thinRegular),
      status: newOrder.status,
      paymentStatus: newOrder.paymentMethod == 'Cash' ? 'Unpaid' : 'Paid',
      paymentMethod: newOrder.paymentMethod,
      totalAmount: newOrder.total,
      createdAt: 'Just now',
      estimatedReadyTime: '30-45 mins',
      staffNotes: 'New customer order.',
    );
    orders.insert(0, lOrder);
    orderLog.add(DateTime.now());
    // GCash/PayMaya are saved right away; cash is saved when the order is claimed.
    if (newOrder.paymentMethod != 'Cash') recordSale(newOrder.id, newOrder.total, newOrder.paymentMethod);

    // Push Customer Notification
    _customerNotifications.insert(
      0,
      AppNotification(
        id: 'cn-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Order Received!',
        message: 'Thank you for choosing G A Laundry Shop! Your order ${newOrder.id} has been received. Please wait for further notifications as our staff process your laundry.',
        time: 'Just now',
        icon: Icons.local_laundry_service_rounded,
        type: 'order_update',
        relatedOrderId: newOrder.id,
      ),
    );

    // Push Admin Notification (Order Placed)
    notifications.insert(
      0,
      AppNotification(
        id: 'an-${DateTime.now().millisecondsSinceEpoch}',
        title: 'New Customer Order Placed!',
        message: 'New order ${newOrder.id} placed by ${newOrder.customerName} - ${newOrder.category} (₱${newOrder.total.toStringAsFixed(2)}).',
        time: 'Just now',
        icon: Icons.shopping_basket_rounded,
        type: 'order_alert',
        relatedOrderId: newOrder.id,
      ),
    );

    // Log Security Activity
    addSecurityLog(
      newOrder.customerName,
      "Placed Order #${newOrder.id} (₱${newOrder.total.toStringAsFixed(2)})",
      "Verified",
    );

    notifyListeners();
  }

  // System Security Logs State
  final List<SystemSecurityLog> _securityLogs = [
    SystemSecurityLog(user: 'Admin John', action: 'System Login', time: '8:00 AM', status: 'Success'),
    SystemSecurityLog(user: 'Maria Santos', action: 'Customer Sign In', time: '8:15 AM', status: 'Verified'),
  ];

  List<SystemSecurityLog> get securityLogs => _securityLogs;

  void addSecurityLog(String user, String action, String status) {
    final now = DateTime.now();
    final timeStr = "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
    _securityLogs.insert(0, SystemSecurityLog(user: user, action: action, time: timeStr, status: status));
    notifyListeners();
  }

  // Admin Account Approval Request Methods
  void submitAdminRegistrationRequest({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String role,
  }) {
    final reqId = 'an-req-${DateTime.now().millisecondsSinceEpoch}';
    notifications.insert(
      0,
      AppNotification(
        id: reqId,
        title: 'New Admin Account Request!',
        message: '$name ($role - username: @$username) is requesting Admin Account Verification & Approval.',
        time: 'Just now',
        icon: Icons.admin_panel_settings_rounded,
        type: 'admin_request',
        adminRequestStatus: 'pending',
        applicantName: name,
        applicantRole: role,
      ),
    );

    addSecurityLog("System", "Admin Reg Request by $name ($role)", "Pending");
    notifyListeners();
  }

  void approveAdminRequest(String notifId) {
    for (var n in notifications) {
      if (n.id == notifId) {
        n.adminRequestStatus = 'approved';
        n.isRead = true;
        addSecurityLog("Admin John", "APPROVED admin request for ${n.applicantName ?? 'User'}", "Approved");
        break;
      }
    }
    notifyListeners();
  }

  void declineAdminRequest(String notifId) {
    for (var n in notifications) {
      if (n.id == notifId) {
        n.adminRequestStatus = 'declined';
        n.isRead = true;
        addSecurityLog("Admin John", "DECLINED admin request for ${n.applicantName ?? 'User'}", "Declined");
        break;
      }
    }
    notifyListeners();
  }

  final List<AppNotification> _customerNotifications = [
    AppNotification(
      id: 'cn-welcome',
      title: 'Welcome to G A Laundry Shop!',
      message: 'Place your first laundry order to track your progress in real-time and earn loyalty points!',
      time: 'Just now',
      icon: Icons.card_giftcard_rounded,
      type: 'general',
    ),
  ];

  List<AppNotification> get customerNotifications => _customerNotifications;

  int get unreadCustomerCount => _customerNotifications.where((n) => !n.isRead).length;

  void markNotificationAsRead(String id) {
    for (var n in _customerNotifications) {
      if (n.id == id) {
        n.isRead = true;
        break;
      }
    }
    for (var n in notifications) {
      if (n.id == id) {
        n.isRead = true;
        break;
      }
    }
    notifyListeners();
  }

  void markAllNotificationsAsRead(UserRole role) {
    if (role == UserRole.admin) {
      for (var n in notifications) {
        n.isRead = true;
      }
    } else {
      for (var n in _customerNotifications) {
        n.isRead = true;
      }
    }
    notifyListeners();
  }

  void initRealtimeSync(String name) {
    // Sync setup stub
  }

  int version = 0;

  @override
  void notifyListeners() {
    version++;
    super.notifyListeners();
  }

  void updateOrderStatus(String orderId, String newStatus) {
    LaundryOrderModel? matchedAdminOrder;
    for (var o in orders) {
      if (o.id == orderId || o.queueNumber == orderId || o.id.replaceAll('ord-', '') == orderId.replaceAll('Q-', '')) {
        o.status = newStatus;
        matchedAdminOrder = o;
        if (newStatus == 'Claimed') {
          // cash is paid on claim -> save the sale
          if (o.paymentStatus != 'Paid') recordSale(o.id, o.totalAmount, o.paymentMethod ?? 'Cash');
          o.paymentStatus = 'Paid';
        }
        break;
      }
    }
    Order? matchedCustomerOrder;
    for (var o in _customerOrders) {
      if (o.id == orderId || o.id.replaceAll('Q-', '') == orderId.replaceAll('Q-', '')) {
        o.status = newStatus;
        matchedCustomerOrder = o;
        break;
      }
    }

    // Automated Dual Notification Trigger
    if (newStatus == 'In Process') {
      // Order claimed by the admin -> use up detergent powder and fabric softener
      _deductInventoryForClaim(orderId, matchedCustomerOrder, matchedAdminOrder);
      _customerNotifications.insert(
        0,
        AppNotification(
          id: 'cn-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Order In Process',
          message: 'Your laundry order $orderId is now IN PROCESS! Machine washing and drying cycle running.',
          time: 'Just now',
          icon: Icons.water_drop_rounded,
          type: 'order_update',
          relatedOrderId: orderId,
        ),
      );
      addSecurityLog("Admin John", "Updated $orderId status to In Process", "Success");
    } else if (newStatus == 'Ready to Claim' || newStatus == 'Ready for Pickup') {
      _customerNotifications.insert(
        0,
        AppNotification(
          id: 'cn-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Order Ready to Claim! 🎉',
          message: 'Your laundry order $orderId is READY TO CLAIM! Present your Digital Claim Stub at G A Laundry Shop.',
          time: 'Just now',
          icon: Icons.check_circle_rounded,
          type: 'order_update',
          relatedOrderId: orderId,
        ),
      );
      addSecurityLog("Admin John", "Updated $orderId status to Ready to Claim", "Success");
    } else if (newStatus == 'Claimed') {
      // 1 stamp per claimed order (free laundry orders do not earn a stamp).
      final bool isFreeOrder = matchedCustomerOrder?.paymentMethod == 'Loyalty Reward';
      final bool earnsStamp = matchedCustomerOrder != null && !isFreeOrder && _customerLoyaltyPoints < stampsForFreeLaundry;
      if (earnsStamp) _customerLoyaltyPoints += 1;
      // Keep the admin's Customer Directory in step with the customer's card.
      if (!isFreeOrder && matchedAdminOrder != null) {
        final String adminCustomerId = matchedAdminOrder.customerId;
        final String adminCustomerPhone = matchedAdminOrder.customerPhone;
        for (final c in customers) {
          if (c.id == adminCustomerId || c.phone == adminCustomerPhone) {
            if (c.loyaltyPoints < stampsForFreeLaundry) c.loyaltyPoints += 1;
            break;
          }
        }
      }
      final String stampNote = earnsStamp
          ? (hasFreeLaundry
          ? ' Loyalty card complete: 10/10! You can now claim a FREE laundry.'
          : ' You earned 1 loyalty stamp ($_customerLoyaltyPoints/10).')
          : '';
      _customerNotifications.insert(
        0,
        AppNotification(
          id: 'cn-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Order Completed & Claimed! ✅',
          message: 'Thank you for washing with G A Laundry Shop! Order $orderId has been claimed.$stampNote',
          time: 'Just now',
          icon: Icons.verified_rounded,
          type: 'order_update',
          relatedOrderId: orderId,
        ),
      );
      // Admin Notification on Claim
      notifications.insert(
        0,
        AppNotification(
          id: 'an-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Order Claimed & Completed!',
          message: 'Order $orderId marked as CLAIMED by customer. Payment verified.',
          time: 'Just now',
          icon: Icons.task_alt_rounded,
          type: 'order_alert',
          relatedOrderId: orderId,
        ),
      );
      addSecurityLog("Admin John", "Order $orderId marked as Claimed & Completed", "Verified");
    }

    notifyListeners();
  }

  // ---------- Push notifications (no SMS/text messages anymore) ----------
  bool pushOrderUpdates = true; // Notification Settings: order status updates
  bool pushPromos = true; // Notification Settings: promotions & announcements

  void setPushPreference({bool? orderUpdates, bool? promos}) {
    if (orderUpdates != null) pushOrderUpdates = orderUpdates;
    if (promos != null) pushPromos = promos;
    notifyListeners();
  }

  /// A push that arrived from the server while the app is open.
  void addPushMessage({required String title, required String body, String type = 'order_update', String? orderId}) {
    final n = AppNotification(
      id: 'push-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: body,
      time: 'Just now',
      icon: type == 'order_alert' ? Icons.notifications_active_rounded : Icons.local_laundry_service_rounded,
      type: type,
      relatedOrderId: orderId,
    );
    if (_currentRole == UserRole.admin) {
      notifications.insert(0, n);
    } else {
      _customerNotifications.insert(0, n);
    }
    notifyListeners();
  }

  // Admin Analytics & Financial Metrics
  double get todaySales {
    final start = dayStart(DateTime.now());
    return salesInRange(start, start.add(const Duration(days: 1)));
  }

  int getCountByStatus(String status) {
    return orders.where((o) => o.status == status || (status == 'Ready' && o.status == 'Ready for Pickup') || (status == 'Ready to Claim' && o.status == 'Ready to Claim')).length;
  }

  int get unreadAdminCount => notifications.where((n) => !n.isRead).length;

  final List<ChatMessage> _messages = [
    ChatMessage(
      senderName: "Customer Maria",
      message: "Hi Admin! What time is the shop open today?",
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isAdmin: false,
    ),
    ChatMessage(
      senderName: "Admin John",
      message: "We are open daily from 7:00 AM to 8:00 PM!",
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      isAdmin: true,
    ),
  ];

  List<ChatMessage> get messages => _messages;

  void sendMessage(ChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  /// Sales for each weekday of the current week (Mon..Sun), from the saved sales.
  Map<String, double> getSalesPerDay() {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final start = weekStart(DateTime.now());
    final result = <String, double>{};
    for (int i = 0; i < 7; i++) {
      final from = start.add(Duration(days: i));
      result[names[i]] = salesInRange(from, from.add(const Duration(days: 1)));
    }
    return result;
  }
}

class AppStateProvider extends StatelessWidget {
  final AppState state;
  final Widget child;

  const AppStateProvider({super.key, required this.state, required this.child});

  static AppState of(BuildContext context) {
    final _InheritedAppState? result = context.dependOnInheritedWidgetOfExactType<_InheritedAppState>();
    return result!.state;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return _InheritedAppState(
          state: state,
          version: state.version,
          child: child,
        );
      },
    );
  }
}

class _InheritedAppState extends InheritedWidget {
  final AppState state;
  final int version;

  const _InheritedAppState({
    required this.state,
    required this.version,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedAppState oldWidget) => version != oldWidget.version;
}