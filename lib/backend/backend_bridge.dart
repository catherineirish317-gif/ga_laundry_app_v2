import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../frontend/models.dart';
import '../frontend/state.dart';
import '../services/connectivity_service.dart';
import '../services/push_notification_service.dart';

/// Connects the backend to the frontend's AppState without touching the
/// frontend screens:
///  - keeps AppState.isOffline in sync with the real network status, so the
///    partner's OfflineBanner shows up automatically when the phone is offline;
///  - registers this phone for push notifications when somebody logs in (and
///    removes it on logout);
///  - turns a push that arrives while the app is open into an in-app notification.
class BackendBridge extends StatefulWidget {
  final Widget child;
  const BackendBridge({super.key, required this.child});

  @override
  State<BackendBridge> createState() => _BackendBridgeState();
}

class _BackendBridgeState extends State<BackendBridge> {
  final ConnectivityService _connectivity = ConnectivityService();
  StreamSubscription<bool>? _sub;
  StreamSubscription<RemoteMessage>? _pushSub;
  AppState? _state;
  bool _started = false;
  bool _wasAuthenticated = false;
  UserRole? _lastRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final state = AppStateProvider.of(context);
    _state = state;
    _start(state);
    _startPush(state);
  }

  Future<void> _start(AppState state) async {
    try {
      final online = await _connectivity.isOnline();
      state.toggleOffline(!online);
      _sub = _connectivity.onStatusChange.listen(
            (online) => state.toggleOffline(!online),
        onError: (_) {},
      );
    } catch (_) {
      // Plugin unavailable (e.g. in widget tests) - leave the UI as-is.
    }
  }

  void _startPush(AppState state) {
    state.addListener(_onStateChanged);
    _pushSub = PushNotificationService.instance.foreground.listen((message) {
      final n = message.notification;
      state.addPushMessage(
        title: n?.title ?? message.data['title'] ?? 'G A Laundry Shop',
        body: n?.body ?? message.data['body'] ?? '',
        type: message.data['type'] ?? 'order_update',
        orderId: message.data['orderId'],
      );
    });
  }

  /// Registers this phone for push after login, and removes it after logout.
  void _onStateChanged() {
    final state = _state;
    if (state == null) return;
    final bool authed = state.isAuthenticated;
    final UserRole role = state.currentRole;

    if (authed && (!_wasAuthenticated || role != _lastRole)) {
      unawaited(PushNotificationService.instance.registerDevice(
        role: role == UserRole.admin ? 'admin' : 'customer',
        customerId: role == UserRole.admin ? null : state.currentCustomerId,
      ));
    } else if (!authed && _wasAuthenticated) {
      unawaited(PushNotificationService.instance.unregisterDevice());
    }
    _wasAuthenticated = authed;
    _lastRole = role;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pushSub?.cancel();
    _state?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}