/// Inventory Data: Inventory ID, Item Name, Item Category, Quantity,
/// Unit, Reorder Level, Current Stock, Status.
/// This tracks stock on hand (detergent, fabric softener, plastic bags,
/// etc.) — separate from Expense Data, which records the money spent.
class InventoryItem {
  final String inventoryId;
  final String itemName;
  final String itemCategory;
  final double quantity;
  final String unit; // e.g. L, kg, pcs
  final double reorderLevel;
  final double currentStock;
  final String status; // In Stock, Low Stock, Out of Stock

  InventoryItem({
    required this.inventoryId,
    required this.itemName,
    required this.itemCategory,
    required this.quantity,
    required this.unit,
    required this.reorderLevel,
    required this.currentStock,
    String? status,
  }) : status = status ?? _deriveStatus(currentStock, reorderLevel);

  static String _deriveStatus(double currentStock, double reorderLevel) {
    if (currentStock <= 0) return 'Out of Stock';
    if (currentStock <= reorderLevel) return 'Low Stock';
    return 'In Stock';
  }

  factory InventoryItem.fromFirestore(Map<String, dynamic> data, String id) {
    final currentStock = (data['currentStock'] ?? 0).toDouble();
    final reorderLevel = (data['reorderLevel'] ?? 0).toDouble();
    return InventoryItem(
      inventoryId: id,
      itemName: data['itemName'] ?? '',
      itemCategory: data['itemCategory'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'pcs',
      reorderLevel: reorderLevel,
      currentStock: currentStock,
      status: data['status'] ?? _deriveStatus(currentStock, reorderLevel),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemName': itemName,
      'itemCategory': itemCategory,
      'quantity': quantity,
      'unit': unit,
      'reorderLevel': reorderLevel,
      'currentStock': currentStock,
      'status': status,
    };
  }
}
