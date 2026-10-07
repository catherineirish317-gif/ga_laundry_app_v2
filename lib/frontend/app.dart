import 'package:flutter/material.dart';
import 'state.dart';
import 'app_colors.dart';
import 'push_banner.dart';
import 'screens.dart';
import '../backend/backend_bridge.dart'; // BACKEND HOOK

class GALaundryAppContainer extends StatefulWidget {
  const GALaundryAppContainer({super.key});

  @override
  State<GALaundryAppContainer> createState() {
    return _GALaundryAppContainerState();
  }
}

class _GALaundryAppContainerState extends State<GALaundryAppContainer> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  /// One theme for the whole app (customer and admin), using the logo colors.
  ThemeData _buildTheme() {
    const Color primary = AppColors.primary;
    const Color accent = AppColors.accent;
    const Color background = AppColors.background;
    const Color ink = AppColors.ink;

    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        tertiary: AppColors.pink,
        surface: background,
        onSurface: ink,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      chipTheme: const ChipThemeData(
        selectedColor: primary,
        backgroundColor: AppColors.aqua,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      state: _appState,
      child: MaterialApp(
        title: 'G A Laundry Shop',
        debugShowCheckedModeBanner: false,
        builder: (context, child) => BackendBridge(child: PushBannerHost(child: child ?? const SizedBox.shrink())), // BACKEND HOOK
        theme: _buildTheme(),
        home: const RootSessionView(),
        routes: {
          '/customer_home': (context) => const CustomerHomeScreen(),
          '/login': (context) => const AuthSelectionScreen(),
          '/signup': (context) => const SignupScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          '/account_details': (context) => const AccountDetailsScreen(),
          '/saved_addresses': (context) => const SavedAddressesScreen(),
          '/payment_methods': (context) => const PaymentMethodsScreen(),
          '/rewards_redemption': (context) => const RewardsRedemptionScreen(),
          '/notification_settings': (context) => const NotificationSettingsScreen(),
          '/admin_signup': (context) => const AdminSignupScreen(),
          '/admin_forgot_password': (context) => const AdminForgotPasswordScreen(),
        },
      ),
    );
  }
}

class RootSessionView extends StatefulWidget {
  const RootSessionView({super.key});

  @override
  State<RootSessionView> createState() => _RootSessionViewState();
}

class _RootSessionViewState extends State<RootSessionView> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        if (_showSplash) {
          return SplashScreen(
            onFinish: () {
              setState(() {
                _showSplash = false;
              });
            },
          );
        }
        return state.isAuthenticated ? const MainPortalShell() : const AuthSelectionScreen();
      },
    );
  }
}