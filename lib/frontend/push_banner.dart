import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'models.dart';
import 'state.dart';

/// Shows a push-style alert at the top of the screen when a new notification
/// arrives while the app is open (the same look as a push notification).
/// When the app is closed or in the background, Android shows the real push
/// in the status bar instead.
class PushBannerHost extends StatefulWidget {
  final Widget child;
  const PushBannerHost({super.key, required this.child});

  @override
  State<PushBannerHost> createState() => _PushBannerHostState();
}

class _PushBannerHostState extends State<PushBannerHost> {
  bool _initialized = false;
  String _scope = '';
  String? _lastId;
  AppNotification? _current;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.of(context);

    final List<AppNotification> list = !state.isAuthenticated
        ? const <AppNotification>[]
        : (state.currentRole == UserRole.admin ? state.notifications : state.customerNotifications);
    final String scope = !state.isAuthenticated ? 'none' : state.currentRole.name;
    final AppNotification? top = list.isEmpty ? null : list.first;

    // First build, or somebody logged in/out: just remember what is already there.
    if (!_initialized || scope != _scope) {
      _initialized = true;
      _scope = scope;
      _lastId = top?.id;
      return;
    }

    if (top != null && top.id != _lastId) {
      _lastId = top.id;
      final bool muted = top.type == 'order_update' && !state.pushOrderUpdates;
      if (!top.isRead && !muted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _show(top);
        });
      }
    }
  }

  void _show(AppNotification n) {
    _hideTimer?.cancel();
    setState(() {
      _current = n;
      _visible = true;
    });
    _hideTimer = Timer(const Duration(seconds: 5), _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPad = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          top: _visible ? topPad + 8 : -180,
          left: 12,
          right: 12,
          child: IgnorePointer(
            ignoring: !_visible,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _current == null ? const SizedBox.shrink() : _card(_current!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(AppNotification n) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _hide,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(n.icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "G A LAUNDRY SHOP",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      n.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}