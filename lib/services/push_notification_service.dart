import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Runs when a push arrives while the app is closed or in the background.
/// Android shows the notification in the status bar by itself; this only has
/// to make sure Firebase is ready. Must stay a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Push notifications (Firebase Cloud Messaging).
/// The app does not send SMS/text messages anymore: every update to the
/// customer or the admin is a push notification.
///
/// Flow: the app saves this phone's FCM token in the `deviceTokens` collection
/// (with the role and customerId). The Cloud Functions in /functions look the
/// tokens up and send the push when an order is created or its status changes.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  /// Must match the channel created in MainActivity.kt and sent by the Cloud Function.
  static const String channelId = 'ga_laundry_updates';

  final StreamController<RemoteMessage> _foreground = StreamController<RemoteMessage>.broadcast();

  /// Pushes that arrive while the app is open (Android does not show these in the status bar).
  Stream<RemoteMessage> get foreground => _foreground.stream;

  String? _token;
  String? get token => _token;
  bool _started = false;
  String? _registeredToken;

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final fcm = FirebaseMessaging.instance;

      // Android 13+ asks the user for permission here.
      final settings = await fcm.requestPermission(alert: true, badge: true, sound: true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push notifications: permission denied by the user.');
        return;
      }

      _token = await fcm.getToken();
      debugPrint('FCM device token: $_token');

      fcm.onTokenRefresh.listen((newToken) {
        _token = newToken;
        _registeredToken = null; // register again on the next login
      });

      FirebaseMessaging.onMessage.listen(_foreground.add);
    } catch (e) {
      debugPrint('Push notifications could not start: $e');
    }
  }

  /// Links this phone to the logged-in user so the Cloud Function can reach it.
  /// [role] is 'customer' or 'admin'.
  Future<void> registerDevice({required String role, String? customerId}) async {
    try {
      final token = _token ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _token = token;
      await FirebaseFirestore.instance.collection('deviceTokens').doc(token).set({
        'token': token,
        'role': role,
        'customerId': customerId,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _registeredToken = token;
    } catch (e) {
      debugPrint('Could not register the device for push: $e');
    }
  }

  /// Called on logout so this phone stops receiving someone else's pushes.
  Future<void> unregisterDevice() async {
    try {
      final token = _registeredToken ?? _token;
      if (token == null) return;
      await FirebaseFirestore.instance.collection('deviceTokens').doc(token).delete();
      _registeredToken = null;
    } catch (e) {
      debugPrint('Could not unregister the device: $e');
    }
  }
}