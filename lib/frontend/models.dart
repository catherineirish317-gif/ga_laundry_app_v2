import 'package:flutter/material.dart';

enum UserRole { admin, customer }

enum FabricCategory { thinRegular, thickHeavy }

class BatchRecommendation {
  final String tier;
  final String suggestedWashCycle;
  final String waterTemperature;
  final String detergentAmount;
  final String fabricSoftener;
  final String suggestedWasher;
  final String suggestedDryer;
  final int estDurationMinutes;
  final int recommendedLoads;
  final String notes;

  const BatchRecommendation({
    required this.tier,
    required this.suggestedWashCycle,
    required this.waterTemperature,
    required this.detergentAmount,
    required this.fabricSoftener,
    required this.suggestedWasher,
    required this.suggestedDryer,
    required this.estDurationMinutes,
    required this.recommendedLoads,
    required this.notes,
  });

  factory BatchRecommendation.calculate(double weightKg, FabricCategory category) {
    final isHeavy = category == FabricCategory.thickHeavy;
    if (weightKg <= 3.0) {
      return BatchRecommendation(
        tier: 'Small Load (<=3kg)',
        suggestedWashCycle: isHeavy ? 'Standard Normal' : 'Gentle / Delicate',
        waterTemperature: isHeavy ? 'Warm (40°C)' : 'Cold (30°C)',
        detergentAmount: isHeavy ? '45g (1.5 scoops)' : '35g (1 level scoop)',
        fabricSoftener: '25ml (1 cap)',
        suggestedWasher: 'Washer #1 (7kg Capacity)',
        suggestedDryer: 'Dryer #1 (8kg Commercial)',
        estDurationMinutes: isHeavy ? 45 : 35,
        recommendedLoads: 1,
        notes: isHeavy ? 'Dense fabric load; use medium-high spin.' : 'Light everyday cotton; gentle tumble wash.',
      );
    } else if (weightKg <= 7.0) {
      return BatchRecommendation(
        tier: 'Medium Load (<=7kg)',
        suggestedWashCycle: isHeavy ? 'Heavy Duty / Intense' : 'Standard Normal',
        waterTemperature: isHeavy ? 'Warm (40°C)' : 'Cold (30°C)',
        detergentAmount: isHeavy ? '75g (2.5 scoops)' : '60g (2 scoops)',
        fabricSoftener: '40ml (1.5 caps)',
        suggestedWasher: 'Washer #2 or #3 (10.5kg)',
        suggestedDryer: 'Dryer #2 (11kg)',
        estDurationMinutes: isHeavy ? 52 : 42,
        recommendedLoads: 1,
        notes: isHeavy ? 'Optimum capacity for towels, denim, and blankets.' : 'Standard load; maximum water extraction spin.',
      );
    } else {
      return BatchRecommendation(
        tier: 'Large Load (>7kg)',
        suggestedWashCycle: 'Heavy Duty / Intense',
        waterTemperature: isHeavy ? 'Hot (60°C)' : 'Warm (40°C)',
        detergentAmount: isHeavy ? '110g (3.5 scoops)' : '90g (3 scoops)',
        fabricSoftener: '60ml (2 caps)',
        suggestedWasher: 'Washer #4 (15kg Industrial)',
        suggestedDryer: 'Dryer #3 or #4 (16kg High-Velocity)',
        estDurationMinutes: isHeavy ? 65 : 55,
        recommendedLoads: 2,
        notes: 'High volume. Consider splitting into two loads if bulky.',
      );
    }
  }
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  int totalOrders;
  double totalSpent;
  int loyaltyPoints;
  final String registeredDate;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
    required this.totalOrders,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.registeredDate,
  });
}

class LaundryOrderModel {
  final String id;
  final String queueNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String serviceType;
  final FabricCategory fabricCategory;
  final double weightKg;
  final BatchRecommendation batchRecommendation;
  String status; // 'Received', 'Sorting', 'Washing', 'Drying', 'Ready for Pickup', 'Claimed'
  String paymentStatus; // 'Paid', 'Unpaid'
  String? paymentMethod;
  final double totalAmount;
  final String createdAt;
  final String estimatedReadyTime;
  final String staffNotes;
  bool isOfflineSyncPending;

  LaundryOrderModel({
    required this.id,
    required this.queueNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    required this.fabricCategory,
    required this.weightKg,
    required this.batchRecommendation,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.estimatedReadyTime,
    required this.staffNotes,
    this.isOfflineSyncPending = false,
  });
}

class Order {
  final String id;
  final String customerName;
  final String phone;
  final String category;
  final String service;
  final double total;
  final String paymentMethod;
  final List<String> addons;
  final DateTime timestamp;
  String status;

  Order({
    required this.id,
    required this.customerName,
    required this.phone,
    this.category = 'Regular Clothes',
    required this.service,
    required this.total,
    required this.paymentMethod,
    this.addons = const [],
    required this.timestamp,
    this.status = 'Received',
  });
}

class LaundryMachineModel {
  final String id;
  final String name;
  final String type; // 'Washer', 'Dryer'
  final double capacityKg;
  String status; // 'Available', 'Running', 'Maintenance'
  int? timeRemainingMinutes;

  LaundryMachineModel({
    required this.id,
    required this.name,
    required this.type,
    required this.capacityKg,
    required this.status,
    this.timeRemainingMinutes,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final DateTime timestamp;
  final IconData icon;
  final String type; // 'order_update', 'order_alert', 'admin_request'
  bool isRead;
  final String? relatedOrderId;
  String? adminRequestStatus; // 'pending', 'approved', 'declined'
  final String? applicantName;
  final String? applicantRole;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    DateTime? timestamp,
    required this.icon,
    this.type = 'general',
    this.isRead = false,
    this.relatedOrderId,
    this.adminRequestStatus,
    this.applicantName,
    this.applicantRole,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SystemSecurityLog {
  final String user;
  final String action;
  final String time;
  final String status;
  final DateTime timestamp;

  SystemSecurityLog({
    required this.user,
    required this.action,
    required this.time,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatMessage {
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  ChatMessage({
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isAdmin,
  });
}