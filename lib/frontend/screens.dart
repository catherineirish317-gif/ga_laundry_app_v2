import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'app_colors.dart';
import '../services/push_notification_service.dart';
import 'state.dart';
import 'payment_address_screens.dart';
export 'payment_address_screens.dart';
import 'receipt_pdf.dart';

// --- SHARED WIDGETS ---

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    if (!appState.isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Offline Mode: Orders stored in local Hive queue',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Keeps phone-style screens readable on tablets by limiting how wide they get.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 700});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

// --- ANIMATION & INTERACTION WIDGETS ---

class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0 - widget.scaleFactor,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onTap != null) widget.onTap!();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class FadeAndSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double slideOffset;
  final Duration delay;

  const FadeAndSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.slideOffset = 20.0,
    this.delay = Duration.zero,
  });

  @override
  State<FadeAndSlide> createState() => _FadeAndSlideState();
}

class _FadeAndSlideState extends State<FadeAndSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class AnimatedPulseBadge extends StatefulWidget {
  final Color color;
  final double size;
  const AnimatedPulseBadge({super.key, this.color = AppColors.success, this.size = 8.0});

  @override
  State<AnimatedPulseBadge> createState() => _AnimatedPulseBadgeState();
}

class _AnimatedPulseBadgeState extends State<AnimatedPulseBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: widget.size * 1.8,
            height: widget.size * 1.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.35),
            ),
          ),
        ),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ],
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  Map<String, dynamic> _getBadgeStyle() {
    switch (status) {
      case 'In Progress':
      case 'Washing':
      case 'Drying':
      case 'Sorting':
        return {
          'bg': AppColors.primarySoft,
          'border': AppColors.aqua,
          'text': AppColors.primary,
          'icon': Icons.sync_rounded,
        };
      case 'Ready':
      case 'Ready for Pickup':
      case 'Completed':
      case 'Claimed':
        return {
          'bg': const Color(0xFFD1FAE5),
          'border': const Color(0xFFA7F3D0),
          'text': AppColors.success,
          'icon': Icons.check_circle_rounded,
        };
      case 'Pending':
      case 'Received':
        return {
          'bg': const Color(0xFFFEF3C7),
          'border': const Color(0xFFFDE68A),
          'text': AppColors.warning,
          'icon': Icons.hourglass_top_rounded,
        };
      default:
        return {
          'bg': const Color(0xFFF1F5F9),
          'border': AppColors.border,
          'text': const Color(0xFF475569),
          'icon': Icons.info_outline_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getBadgeStyle();
    final Color bg = style['bg'] as Color;
    final Color border = style['border'] as Color;
    final Color text = style['text'] as Color;
    final IconData icon = style['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// --- 1. SPLASH SCREEN ---
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100, left: -100,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))]),
                      child: const Icon(Icons.local_laundry_service_rounded, size: 96, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('G A LAUNDRY SHOP', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.2)),
                  const Text('Fresh Clothes, Happier You!', style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: widget.onFinish,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Get Started', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, color: Colors.white)]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. AUTH SELECTION ---
class AuthSelectionScreen extends StatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  bool _isAdminMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isAdminMode ? AppColors.ink : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Admin Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _isAdminMode ? Colors.white : AppColors.primary)),
            const SizedBox(width: 4),
            Switch(
              value: _isAdminMode, activeThumbColor: _isAdminMode ? AppColors.accent : AppColors.primary,
              onChanged: (val) => setState(() => _isAdminMode = val),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _isAdminMode ? const AdminLoginView() : const CustomerLoginView(),
      ),
    );
  }
}

class CustomerLoginView extends StatefulWidget {
  const CustomerLoginView({super.key});
  @override
  State<CustomerLoginView> createState() => _CustomerLoginViewState();
}

class _CustomerLoginViewState extends State<CustomerLoginView> {
  final TextEditingController _identifierController = TextEditingController(text: '0917-823-4591');
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    const accentColor = AppColors.primary;
    final state = AppStateProvider.of(context);

    return Stack(
      children: [
        // Background Decorative Circles
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.06),
            ),
          ),
        ),

        // Main Content
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Header Logo Icon
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_laundry_service_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "G A LAUNDRY SHOP",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: brandColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Smart & Premium Laundry Service",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.07),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(color: brandColor.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          _identifierController,
                          Icons.person_outline_rounded,
                          "Username",
                        ),
                        const SizedBox(height: 18),
                        _buildTextField(
                          _passwordController,
                          Icons.lock_outline_rounded,
                          "Password",
                          obscureText: true,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => const ForgotPasswordScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => state.login(UserRole.customer, customPhone: _identifierController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: brandColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade200)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "OR CONTINUE WITH",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade200)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _socialIconButton(context, Icons.g_mobiledata_rounded, AppColors.danger, "Google", () => state.login(UserRole.customer)),
                            _socialIconButton(context, Icons.facebook_rounded, const Color(0xFF1877F2), "Facebook", () => state.login(UserRole.customer)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  // Registration Link Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _socialIconButton(BuildContext context, IconData icon, Color color, String platform, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            )
          ],
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

// --- SIGNUP SCREEN ---
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _currentStep = 0; // 0: Form, 1: Email OTP
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? "Create Account" : "Verify Email OTP",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _currentStep == 0 ? _buildSignupForm(brandColor) : _buildOtpVerification(brandColor),
    );
  }

  Widget _buildSignupForm(Color brandColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: "Personal Information",
              icon: Icons.person_pin_rounded,
              brandColor: brandColor,
              children: [
                _buildInputField(firstNameController, "First Name", Icons.person_outline),
                const SizedBox(height: 14),
                _buildInputField(middleNameController, "Middle Name (Optional)", Icons.person_outline),
                const SizedBox(height: 14),
                _buildInputField(lastNameController, "Last Name", Icons.person_outline),
                const SizedBox(height: 14),
                _buildInputField(phoneController, "Phone Number", Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildInputField(emailController, "Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildInputField(addressController, "Home / Delivery Address", Icons.location_on_outlined),
              ],
            ),
            const SizedBox(height: 25),
            _buildSectionCard(
              title: "Account Security",
              icon: Icons.shield_outlined,
              brandColor: brandColor,
              children: [
                _buildInputField(usernameController, "Username", Icons.alternate_email_rounded),
                const SizedBox(height: 14),
                _buildInputField(passwordController, "Password", Icons.lock_outline_rounded, obscureText: true),
              ],
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSendingOtp ? null : _submitSignupForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSendingOtp
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SEND VERIFICATION OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _submitSignupForm() async {
    if (firstNameController.text.isEmpty) firstNameController.text = "Prototype";
    if (lastNameController.text.isEmpty) lastNameController.text = "User";
    if (phoneController.text.isEmpty) phoneController.text = "09123456789";
    if (emailController.text.isEmpty) emailController.text = "prototype@laundry.com";
    if (addressController.text.isEmpty) addressController.text = "General Santos City";
    if (usernameController.text.isEmpty) usernameController.text = "prototype_user";
    if (passwordController.text.isEmpty) passwordController.text = "password123";

    setState(() => _isSendingOtp = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isSendingOtp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("6-digit verification code sent! (Use code e.g. 123456)"),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() => _currentStep = 1);
    }
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Color brandColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: brandColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandColor)),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOtpVerification(Color brandColor) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 55, color: AppColors.primary),
          ),
          const SizedBox(height: 25),
          const Text("Verify Email OTP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 10),
          Text(
            "We've sent a 6-digit verification code to\n${emailController.text}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 35),
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 14, color: AppColors.primary),
            decoration: InputDecoration(
              counterText: "",
              hintText: "000000",
              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 10),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resent new OTP code to your email!")));
            },
            child: const Text("Resend OTP Code", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isVerifyingOtp ? null : _verifyAndCreateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isVerifyingOtp
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("VERIFY & CREATE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  void _verifyAndCreateAccount() async {
    setState(() => _isVerifyingOtp = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isVerifyingOtp = false);

    if (mounted) {
      final state = AppStateProvider.of(context);
      final phone = phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '0917-823-4591';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully! Welcome to G A Laundry."),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
      state.login(UserRole.customer, customPhone: phone);
    }
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// --- FORGOT PASSWORD SCREEN ---
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 0; // 0: Select Method, 1: Enter Info, 2: Enter OTP, 3: New Password
  String _selectedMethod = "Email";
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _infoController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              _buildStepProgressIndicator(brandColor),
              const SizedBox(height: 25),
              Expanded(child: _buildStepContent(brandColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepProgressIndicator(Color brandColor) {
    return Row(
      children: List.generate(4, (index) {
        bool isDone = index <= _currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 4,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(Color brandColor) {
    switch (_currentStep) {
      case 0:
        return _buildMethodSelection(brandColor);
      case 1:
        return _buildInfoEntry(brandColor);
      case 2:
        return _buildOtpEntry(brandColor);
      case 3:
        return _buildNewPasswordEntry(brandColor);
      default:
        return Container();
    }
  }

  Widget _buildMethodSelection(Color brandColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Reset via Email", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text("We'll send a verification code to your registered email address.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 25),
        _methodTile("Email", "Send code to registered email address", Icons.email_outlined, brandColor),
        const Spacer(),
        _nextButton(() => setState(() => _currentStep = 1), label: "CONTINUE", brandColor: brandColor),
      ],
    );
  }

  Widget _methodTile(String method, String subtitle, IconData icon, Color brandColor) {
    bool isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoEntry(Color brandColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Enter your $_selectedMethod", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text("We will send a 4-digit verification code to your $_selectedMethod.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 25),
        TextField(
          controller: _infoController,
          decoration: InputDecoration(
            hintText: _selectedMethod == "Email" ? "your.email@example.com" : "09XX XXX XXXX",
            prefixIcon: Icon(_selectedMethod == "Email" ? Icons.email_outlined : Icons.phone_android_outlined, color: brandColor),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const Spacer(),
        _nextButton(_sendResetCode, label: "SEND VERIFICATION CODE", brandColor: brandColor),
      ],
    );
  }

  void _sendResetCode() async {
    if (_infoController.text.trim().isEmpty) {
      _infoController.text = _selectedMethod == "Email" ? "prototype@laundry.com" : "0917-823-4591";
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("4-digit code sent! (Use code e.g. 1234)"),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() => _currentStep = 2);
    }
  }

  Widget _buildOtpEntry(Color brandColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Verify Security Code", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text("Enter the 4-digit code sent to your $_selectedMethod.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 30),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 18, color: AppColors.primary),
          maxLength: 4,
          decoration: InputDecoration(
            counterText: "",
            hintText: "0000",
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resent 4-digit code!")));
            },
            child: const Text("Resend Code", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ),
        const Spacer(),
        _nextButton(() {
          if (_otpController.text.trim().isEmpty) {
            _otpController.text = "1234";
          }
          setState(() => _currentStep = 3);
        }, label: "VERIFY CODE", brandColor: brandColor),
      ],
    );
  }

  Widget _buildNewPasswordEntry(Color brandColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Set New Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text("Create a strong new password for your account.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 25),
        _passField(_newPassController, "New Password", brandColor),
        const SizedBox(height: 15),
        _passField(_confirmPassController, "Confirm Password", brandColor),
        const Spacer(),
        _nextButton(_handlePasswordReset, label: "RESET & SAVE PASSWORD", brandColor: brandColor),
      ],
    );
  }

  void _handlePasswordReset() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully! You can now log in."),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _passField(TextEditingController controller, String hint, Color brandColor) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.lock_outline_rounded, color: brandColor),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _nextButton(VoidCallback onPressed, {required String label, required Color brandColor}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}

class AdminLoginView extends StatefulWidget {
  const AdminLoginView({super.key});
  @override
  State<AdminLoginView> createState() => _AdminLoginViewState();
}

class _AdminLoginViewState extends State<AdminLoginView> {
  final TextEditingController _usernameController = TextEditingController(text: 'admin_john');
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    const accentColor = AppColors.primary;
    final state = AppStateProvider.of(context);

    return Stack(
      children: [
        // Background Decorative Circles
        Positioned(
          top: -80,
          left: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.06),
            ),
          ),
        ),

        // Main Content
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Header Logo Icon
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.ink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "G A LAUNDRY CONTROL",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: brandColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Management & Admin Sign In",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: brandColor.withValues(alpha: 0.07),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border.all(color: brandColor.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          _usernameController,
                          Icons.person_outline_rounded,
                          "Admin Username",
                        ),
                        const SizedBox(height: 18),
                        _buildTextField(
                          _passwordController,
                          Icons.lock_outline_rounded,
                          "Security Password",
                          obscureText: true,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => const AdminForgotPasswordScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => state.login(UserRole.admin),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandColor,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: brandColor.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Access Dashboard",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  // Registration Link Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Need an admin account?",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const AdminSignupScreen()),
                          );
                        },
                        child: const Text(
                          "Register Admin",
                          style: TextStyle(
                            color: brandColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// --- ADMIN SIGNUP SCREEN (STRICT WITH MANUAL APPROVAL NOTE) ---
class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController roleController = TextEditingController(text: "Shift Supervisor");
  final TextEditingController passwordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    roleController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Register Admin Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STRICT APPROVAL NOTICE BANNER
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.shade400, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield, color: AppColors.warning, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "STRICT ADMIN APPROVAL REQUIRED",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.warning, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "All admin account registrations require manual verification and approval by the Shop Owner / Main Admin before access is granted.",
                          style: TextStyle(fontSize: 12, color: AppColors.warning, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionCard(
              title: "Administrator Credentials",
              brandColor: brandColor,
              children: [
                _field(nameController, "Full Name", Icons.person_outline),
                const SizedBox(height: 14),
                _field(emailController, "Work Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(phoneController, "Mobile Phone Number", Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _field(usernameController, "Desired Admin Username", Icons.alternate_email_rounded),
                const SizedBox(height: 14),
                _field(roleController, "Admin Role (e.g. Supervisor, Cashier)", Icons.badge_outlined),
                const SizedBox(height: 14),
                _field(passwordController, "Security Password", Icons.lock_outline_rounded, obscureText: true),
              ],
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAdminRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                  "SUBMIT REGISTRATION FOR APPROVAL",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _submitAdminRegistration() async {
    final state = AppStateProvider.of(context);
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _isSubmitting = false);

    state.submitAdminRegistrationRequest(
      name: nameController.text.isNotEmpty ? nameController.text : "Supervisor John",
      email: emailController.text.isNotEmpty ? emailController.text : "supervisor@galaundry.com",
      phone: phoneController.text.isNotEmpty ? phoneController.text : "0928-188-6235",
      username: usernameController.text.isNotEmpty ? usernameController.text : "john_supervisor",
      role: roleController.text.isNotEmpty ? roleController.text : "Shift Supervisor",
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Text("Request Pending Approval", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Your Admin Registration Request (#ADM-REQ-1082) has been submitted successfully!\n\nIt is currently PENDING APPROVAL by the Shop Owner / Main Admin. You will receive a push notification once your account is activated.",
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("UNDERSTOOD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
  }

  Widget _buildSectionCard({required String title, required Color brandColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: brandColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandColor)),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// --- ADMIN FORGOT PASSWORD SCREEN ---
class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() => _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  int _currentStep = 0;
  String _selectedMethod = "Email";
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _infoController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Reset Admin Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Row(
                children: List.generate(4, (index) {
                  bool isDone = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 25),
              Expanded(child: _buildStepContent(brandColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(Color brandColor) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Reset via Email", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text("We'll send a verification code to your registered email address.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 25),
            _tile("Email", "Send security code to admin email", Icons.email_outlined, brandColor),
            const Spacer(),
            _btn(() => setState(() => _currentStep = 1), "CONTINUE", brandColor),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter Admin $_selectedMethod", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text("We will send a 4-digit verification code to your $_selectedMethod.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 25),
            TextField(
              controller: _infoController,
              decoration: InputDecoration(
                hintText: _selectedMethod == "Email" ? "admin@galaundry.com" : "0999-999-9999",
                prefixIcon: Icon(_selectedMethod == "Email" ? Icons.email_outlined : Icons.phone_android_outlined, color: brandColor),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const Spacer(),
            _btn(() async {
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("4-digit code sent! (Use 1234)")));
                setState(() => _currentStep = 2);
              }
            }, "SEND VERIFICATION CODE", brandColor),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Verify Security Code", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text("Enter the 4-digit code sent to your $_selectedMethod.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 18, color: AppColors.primary),
              maxLength: 4,
              decoration: InputDecoration(
                counterText: "",
                hintText: "0000",
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const Spacer(),
            _btn(() => setState(() => _currentStep = 3), "VERIFY CODE", brandColor),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Set New Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text("Create a strong new password for your admin account.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 25),
            TextField(
              controller: _newPassController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "New Security Password",
                prefixIcon: Icon(Icons.lock_outline_rounded, color: brandColor),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Confirm New Password",
                prefixIcon: Icon(Icons.lock_outline_rounded, color: brandColor),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
            const Spacer(),
            _btn(() async {
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin Password updated successfully!")));
                Navigator.pop(context);
              }
            }, "RESET & SAVE PASSWORD", brandColor),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _tile(String method, String subtitle, IconData icon, Color brandColor) {
    bool isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _btn(VoidCallback onPressed, String label, Color brandColor) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- ADMIN SCREEN DEFINITIONS ---

class CustomerDirectoryScreen extends StatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  State<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends State<CustomerDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final customers = state.customers.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Customer Directory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search customer name or phone...",
                prefixIcon: const Icon(Icons.search_rounded, color: brandColor),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final c = customers[index];
                return BouncingWidget(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)),
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.05),
                    child: ListTile(
                      onTap: () => _showCustomerDetails(context, c),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(c.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
                      subtitle: Text("${c.phone} • Orders: ${c.totalOrders}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, CustomerModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text(c.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text("Customer ID: ${c.id}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _infoRow("Phone Number", c.phone),
            _infoRow("Home Address", c.address),
            _infoRow("Total Orders", "${c.totalOrders}"),
            _infoRow("Total Spent", "₱${c.totalSpent.toStringAsFixed(2)}"),
            _infoRow("Loyalty Stamps", "${c.loyaltyPoints}/10"),
            _infoRow("Special Notes", c.notes.isNotEmpty ? c.notes : "None"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("CLOSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  String _logFilter = 'All';

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final appState = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Financial Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatGrid(appState),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Sales Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                TextButton(onPressed: () => _showWeeklyReport(context), child: const Text("Past Reports")),
              ],
            ),
            const SizedBox(height: 15),
            _buildRealChart(appState),
            const SizedBox(height: 30),
            const Text("Inventory Alert", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandColor)),
            const SizedBox(height: 15),
            _buildInventoryList(appState),
            const SizedBox(height: 30),
            const Text("System Security Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandColor)),
            const SizedBox(height: 15),
            _buildSystemLogs(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(AppState appState) {
    double expenses = 450.00;
    double netProfit = appState.todaySales - expenses;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _statCard(context, "Today's Sales", "₱${appState.todaySales.toStringAsFixed(2)}", Icons.payments_rounded, AppColors.primary),
        _statCard(context, "Fixed Expenses", "₱${expenses.toStringAsFixed(2)}", Icons.receipt_long_rounded, AppColors.danger),
        _statCard(context, "Pending Orders", "${appState.getCountByStatus('Received')}", Icons.pending_actions_rounded, AppColors.warning),
        _statCard(context, "Net Profit", "₱${netProfit < 0 ? 0 : netProfit.toStringAsFixed(2)}", Icons.trending_up_rounded, AppColors.success),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Viewing detailed report for $label...")),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealChart(AppState appState) {
    final salesMap = appState.getSalesPerDay();
    final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    double maxSales = 0;
    salesMap.forEach((k, v) {
      if (v > maxSales) maxSales = v;
    });
    if (maxSales == 0) maxSales = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                double value = salesMap[day] ?? 0;
                double barHeight = (value / maxSales) * 150;
                if (barHeight < 5 && value > 0) barHeight = 5;

                return _bar(barHeight, day, value);
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "This Week: ₱${appState.salesThisWeek.toStringAsFixed(2)}   •   Today (saved): ₱${appState.todaySales.toStringAsFixed(2)}",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height, String day, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value > 0)
          Text("₱${value.toInt()}", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 5),
        Container(
          width: 18,
          height: height > 0 ? height : 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showWeeklyReport(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoricalReportScreen())
    );
  }

  Widget _buildSystemLogs(AppState appState) {
    final all = appState.securityLogs;
    bool isSuccess(SystemSecurityLog l) => l.status == 'Success' || l.status == 'Verified' || l.status == 'Approved';
    bool isDeclined(SystemSecurityLog l) => l.status == 'Declined';

    final logs = all.where((l) {
      switch (_logFilter) {
        case 'Success':
          return isSuccess(l);
        case 'Declined':
          return isDeclined(l);
        case 'Pending':
          return !isSuccess(l) && !isDeclined(l);
        default:
          return true;
      }
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink))),
              Text("${logs.length} of ${all.length}", style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Success', 'Pending', 'Declined'].map((f) {
                final bool selected = _logFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.primary)),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _logFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text("No logs match this filter.", style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            ...logs.take(50).map((log) {
              final bool ok = isSuccess(log);
              final bool bad = isDeclined(log);
              final Color color = ok ? AppColors.success : (bad ? AppColors.danger : AppColors.warning);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User: ${log.user}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text(log.action, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(log.time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(log.status, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInventoryList(AppState appState) {
    final items = [
      {'name': 'Detergent Powder', 'stock': appState.detergentStockKg, 'unit': 'kg', 'alert': appState.detergentAlertKg, 'low': appState.detergentLow},
      {'name': 'Fabric Softener', 'stock': appState.softenerStockL, 'unit': 'L', 'alert': appState.softenerAlertL, 'low': appState.softenerLow},
      ...appState.lowExtraItems.map((i) => {'name': i.name, 'stock': i.stock, 'unit': i.unit, 'alert': i.alertLevel, 'low': true}),
    ];

    return Column(
      children: items.map((item) {
        final bool isLow = item['low'] as bool;
        final String unit = item['unit'] as String;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminInventoryScreen()),
              );
            },
            leading: CircleAvatar(
              backgroundColor: isLow ? Colors.red.shade50 : AppColors.primarySoft,
              child: Icon(Icons.inventory, color: isLow ? AppColors.danger : AppColors.primary, size: 20),
            ),
            title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              "Stock: ${(item['stock'] as double).toStringAsFixed(2)}$unit | Alert at: ${(item['alert'] as double).toStringAsFixed(1)}$unit",
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              isLow ? 'Low Stock' : 'Normal',
              style: TextStyle(color: isLow ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- INVENTORY STOCK & ALERTS ---
class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  static const Color _brandColor = AppColors.primary;

  String _qty(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final lowNames = <String>[
      if (state.detergentLow) "Detergent Powder",
      if (state.softenerLow) "Fabric Softener",
      ...state.lowExtraItems.map((i) => i.name),
    ];

    final bool wide = MediaQuery.of(context).size.width >= 840;
    final List<Widget> bannerW = <Widget>[
      if (lowNames.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Time to restock: ${lowNames.join(' and ')}.",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ),
    ];
    final List<Widget> mainW = <Widget>[
      _itemCard(
        context,
        state,
        isDetergent: true,
        name: "Detergent Powder",
        unit: "kg",
        icon: Icons.sanitizer_rounded,
        stock: state.detergentStockKg,
        capacity: state.detergentCapacityKg,
        alertLevel: state.detergentAlertKg,
        low: state.detergentLow,
      ),
      _itemCard(
        context,
        state,
        isDetergent: false,
        name: "Fabric Softener",
        unit: "L",
        icon: Icons.local_florist_rounded,
        stock: state.softenerStockL,
        capacity: state.softenerCapacityL,
        alertLevel: state.softenerAlertL,
        low: state.softenerLow,
      ),
    ];
    final List<Widget> othersW = <Widget>[
      const SizedBox(height: 8),
      const Text("Other Supplies", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandColor)),
      const SizedBox(height: 4),
      const Text(
        "These are tracked by hand: use Restock, Use, Mark Full or Edit. Only detergent powder and fabric softener are deducted automatically.",
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 14),
      ...AppState.extraInventoryGroups.expand((group) {
        final items = state.extraInventory.where((i) => i.group == group).toList();
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Row(
              children: [
                Icon(_groupIcon(group), color: _brandColor, size: 20),
                const SizedBox(width: 8),
                Text(group, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
              ],
            ),
          ),
          ...items.map((i) => _extraItemCard(context, state, i)),
          const SizedBox(height: 6),
        ];
      }),
    ];
    final List<Widget> restW = <Widget>[
      const SizedBox(height: 8),
      const Text("Automatic Deduction", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandColor)),
      const SizedBox(height: 4),
      const Text(
        "When you claim an order in Order Management, the detergent powder and fabric softener are deducted automatically per laundry category.",
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      _guideCard(),
      const SizedBox(height: 22),
      const Text("Recent Usage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandColor)),
      const SizedBox(height: 12),
      if (state.inventoryLog.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("No deductions yet. Claim an order to see usage here.", style: TextStyle(color: Colors.grey, fontSize: 12))),
        )
      else
        ...state.inventoryLog.take(15).map((u) => _usageTile(u)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Inventory Stock & Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: wide
      // Tablet: main supplies + usage on the left, other supplies on the right
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [...bannerW, ...mainW, ...restW],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
              children: othersW,
            ),
          ),
        ],
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [...bannerW, ...mainW, ...othersW, ...restW],
      ),
    );
  }

  Widget _itemCard(
      BuildContext context,
      AppState state, {
        required bool isDetergent,
        required String name,
        required String unit,
        required IconData icon,
        required double stock,
        required double capacity,
        required double alertLevel,
        required bool low,
      }) {
    final bool out = stock <= 0;
    final Color statusColor = out || low ? AppColors.danger : AppColors.success;
    final String statusText = out ? "OUT OF STOCK" : (low ? "LOW STOCK" : "STOCK OK");
    final double fraction = capacity > 0 ? (stock / capacity).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: low ? const Color(0xFFFECACA) : AppColors.border),
        boxShadow: [BoxShadow(color: _brandColor.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _brandColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: _brandColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "${_qty(stock)} $unit", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: statusColor)),
                TextSpan(text: "  of ${_qty(capacity)} $unit (full)", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text("Alert when stock is at or below ${_qty(alertLevel)} $unit", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _restockDialog(context, state, isDetergent, name, unit),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text("Restock", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  state.markInventoryFull(isDetergent);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name is now full (${_qty(capacity)} $unit).")));
                },
                icon: const Icon(Icons.battery_full_rounded, size: 18),
                label: const Text("Mark Full", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _editDialog(context, state, isDetergent, name, unit),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("Edit Stock & Alert", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brandColor,
                  side: const BorderSide(color: _brandColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Bleaches':
        return Icons.cleaning_services_rounded;
      case 'Stain Removers & Pre-treaters':
        return Icons.format_color_reset_rounded;
      case 'Scent Boosters & Sanitizers':
        return Icons.spa_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  Widget _extraItemCard(BuildContext context, AppState state, InventoryItem item) {
    final bool out = item.stock <= 0;
    final bool low = item.low;
    final Color statusColor = out || low ? AppColors.danger : AppColors.success;
    final String statusText = out ? "OUT" : (low ? "LOW" : "OK");
    final double fraction = item.capacity > 0 ? (item.stock / item.capacity).clamp(0.0, 1.0).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: low ? const Color(0xFFFECACA) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(item.note, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: "${_qty(item.stock)} ${item.unit}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: statusColor)),
                TextSpan(text: "  of ${_qty(item.capacity)} ${item.unit}  •  alert at ${_qty(item.alertLevel)}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: fraction, minHeight: 8, backgroundColor: const Color(0xFFF1F5F9), color: statusColor),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _amountDialog(
                  context,
                  title: "Restock ${item.name}",
                  label: "Amount added",
                  unit: item.unit,
                  confirm: "ADD STOCK",
                  onConfirm: (v) {
                    state.restockExtra(item.id, v);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${_qty(v)} ${item.unit} to ${item.name}.")));
                  },
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text("Restock", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () => _amountDialog(
                  context,
                  title: "Use ${item.name}",
                  label: "Amount used",
                  unit: item.unit,
                  confirm: "DEDUCT",
                  onConfirm: (v) {
                    state.useExtra(item.id, v);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deducted ${_qty(v)} ${item.unit} from ${item.name}.")));
                  },
                ),
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                label: const Text("Use", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () {
                  state.markExtraFull(item.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} is now full.")));
                },
                icon: const Icon(Icons.battery_full_rounded, size: 16),
                label: const Text("Full", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: () => _extraEditDialog(context, state, item),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text("Edit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _amountDialog(
      BuildContext context, {
        required String title,
        required String label,
        required String unit,
        required String confirm,
        required void Function(double) onConfirm,
      }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: unit),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an amount greater than 0.")));
                return;
              }
              Navigator.pop(ctx);
              onConfirm(v);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            child: Text(confirm),
          ),
        ],
      ),
    );
  }

  void _extraEditDialog(BuildContext context, AppState state, InventoryItem item) {
    final stockC = TextEditingController(text: _qty(item.stock));
    final alertC = TextEditingController(text: _qty(item.alertLevel));
    final capC = TextEditingController(text: _qty(item.capacity));

    Widget field(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: item.unit),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit ${item.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(stockC, "Stock now"),
              field(alertC, "Alert when stock is at or below"),
              field(capC, "Full stock (100%)"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final stock = double.tryParse(stockC.text.trim());
              final alertLevel = double.tryParse(alertC.text.trim());
              final capacity = double.tryParse(capC.text.trim());
              String? error;
              if (stock == null || alertLevel == null || capacity == null) {
                error = "Please fill in all three numbers.";
              } else if (stock < 0 || alertLevel < 0 || capacity <= 0) {
                error = "Numbers cannot be negative and full stock must be above 0.";
              } else if (stock > capacity) {
                error = "Stock cannot be more than the full stock.";
              } else if (alertLevel > capacity) {
                error = "The alert level cannot be more than the full stock.";
              }
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              state.updateExtra(item.id, stock: stock, alertLevel: alertLevel, capacity: capacity);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${item.name} updated.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Widget _guideCard() {
    final rows = AppState.categoryLoadKg.entries.map((e) {
      final bool heavy = AppState.heavyCategories.contains(e.key);
      final u = AppState.usageFor(e.value, heavy: heavy);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text("${e.key} (${_qty(e.value)} kg)", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
            Expanded(flex: 2, child: Text("${_qty(u[0])} g", textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))),
            Expanded(flex: 2, child: Text("${_qty(u[1])} ml", textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 5, child: Text("Per load", style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Powder", textAlign: TextAlign.end, style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Softener", textAlign: TextAlign.end, style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 14),
          ...rows,
          const SizedBox(height: 6),
          const Text(
            "Each selected category counts as one load. Extra Detergent / Extra Fabcon add-ons double the powder / softener. Dry Only and Fold Only orders use none.",
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _usageTile(InventoryUsage u) {
    final t = u.time;
    final String time = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${u.orderId}: -${_qty(u.powderGrams)} g powder, -${_qty(u.softenerMl)} ml softener",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  void _restockDialog(BuildContext context, AppState state, bool isDetergent, String name, String unit) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Restock $name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: "Amount added", suffixText: unit),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v == null || v <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an amount greater than 0.")));
                return;
              }
              state.restockInventory(isDetergent, v);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${_qty(v)} $unit to $name.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            child: const Text("ADD STOCK"),
          ),
        ],
      ),
    );
  }

  void _editDialog(BuildContext context, AppState state, bool isDetergent, String name, String unit) {
    final stockC = TextEditingController(text: _qty(isDetergent ? state.detergentStockKg : state.softenerStockL));
    final alertC = TextEditingController(text: _qty(isDetergent ? state.detergentAlertKg : state.softenerAlertL));
    final capC = TextEditingController(text: _qty(isDetergent ? state.detergentCapacityKg : state.softenerCapacityL));

    Widget field(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: unit),
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit $name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(stockC, "Stock now"),
              field(alertC, "Alert when stock is at or below"),
              field(capC, "Full stock (100%)"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final stock = double.tryParse(stockC.text.trim());
              final alertLevel = double.tryParse(alertC.text.trim());
              final capacity = double.tryParse(capC.text.trim());
              String? error;
              if (stock == null || alertLevel == null || capacity == null) {
                error = "Please fill in all three numbers.";
              } else if (stock < 0 || alertLevel < 0 || capacity <= 0) {
                error = "Numbers cannot be negative and full stock must be above 0.";
              } else if (stock > capacity) {
                error = "Stock cannot be more than the full stock.";
              } else if (alertLevel > capacity) {
                error = "The alert level cannot be more than the full stock.";
              }
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              state.updateInventory(detergent: isDetergent, stock: stock, alertLevel: alertLevel, capacity: capacity);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name updated.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOMER FEEDBACK (ADMIN) ---
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  static const Color _brandColor = AppColors.primary;
  static const List<String> _months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

  String _statusFilter = 'All';
  int _ratingFilter = 0; // 0 = all ratings
  String _query = '';
  final TextEditingController _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'New':
        return AppColors.warning;
      case 'Reviewed':
        return AppColors.primary;
      case 'Resolved':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _fmtDate(DateTime d) {
    final int h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    return "${_months[d.month - 1]} ${d.day}, ${d.year} • $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final q = _query.toLowerCase();
    final filtered = state.feedbacks.where((f) {
      if (_statusFilter != 'All' && f.status != _statusFilter) return false;
      if (_ratingFilter != 0 && f.rating != _ratingFilter) return false;
      if (q.isNotEmpty && !(f.customerName.toLowerCase().contains(q) || f.comment.toLowerCase().contains(q) || f.orderId.toLowerCase().contains(q))) return false;
      return true;
    }).toList();

    int countFor(String status) => status == 'All' ? state.feedbacks.length : state.feedbacks.where((f) => f.status == status).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Customer Feedback", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _summaryTile("Average Rating", state.feedbacks.isEmpty ? "-" : "${state.averageRating.toStringAsFixed(1)} ★", AppColors.warning)),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryTile("Total Feedback", "${state.feedbacks.length}", _brandColor)),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryTile("New", "${state.newFeedbackCount}", AppColors.danger)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchC,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: "Search customer, order ID or comment...",
                      prefixIcon: const Icon(Icons.search_rounded, color: _brandColor),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("STATUS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', ...AppState.feedbackStatuses].map((st) {
                        final bool selected = _statusFilter == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text("$st (${countFor(st)})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : _brandColor)),
                            selected: selected,
                            selectedColor: _brandColor,
                            backgroundColor: Colors.grey.shade100,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _statusFilter = st),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("RATING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [0, 5, 4, 3, 2, 1].map((r) {
                        final bool selected = _ratingFilter == r;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(r == 0 ? "All stars" : "$r ★", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : AppColors.warning)),
                            selected: selected,
                            selectedColor: AppColors.warning,
                            backgroundColor: Colors.grey.shade100,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _ratingFilter = r),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: filtered.isEmpty
                  ? _emptyState(state.feedbacks.isEmpty)
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _feedbackCard(state, filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _emptyState(bool noFeedbackAtAll) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          Text(noFeedbackAtAll ? "No feedback yet." : "No feedback matches these filters.", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          if (!noFeedbackAtAll)
            TextButton(
              onPressed: () => setState(() {
                _statusFilter = 'All';
                _ratingFilter = 0;
                _query = '';
                _searchC.clear();
              }),
              child: const Text("Clear filters"),
            ),
        ],
      ),
    );
  }

  Widget _feedbackCard(AppState state, FeedbackEntry f) {
    final Color sc = _statusColor(f.status);
    final bool hidden = f.status == 'Hidden';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: f.status == 'New' ? const Color(0xFFFED7AA) : AppColors.border),
        boxShadow: [BoxShadow(color: _brandColor.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(i < f.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(f.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sc)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("${f.customerName} • ${f.orderId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
          Text(_fmtDate(f.date), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          if (hidden)
            const Text("Hidden by admin. Tap Show to see this feedback again.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted))
          else
            Text(f.comment.isEmpty ? "(No comment, rating only)" : f.comment, style: TextStyle(fontSize: 13, height: 1.4, color: f.comment.isEmpty ? AppColors.textMuted : AppColors.ink)),
          if (f.autoFiltered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 12, color: AppColors.danger),
                  SizedBox(width: 4),
                  Text("Auto-filtered: bad words or links were removed", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.danger)),
                ],
              ),
            ),
          ],
          if (f.adminReply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
              child: Text("Shop reply: ${f.adminReply}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              if (f.status == 'New')
                TextButton.icon(
                  onPressed: () => setState(() => state.setFeedbackStatus(f.id, 'Reviewed')),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text("Mark Reviewed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              if (f.status != 'Resolved' && !hidden)
                TextButton.icon(
                  onPressed: () => setState(() => state.setFeedbackStatus(f.id, 'Resolved')),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text("Resolve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              if (!hidden)
                TextButton.icon(
                  onPressed: () => _replyDialog(state, f),
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(f.adminReply.isEmpty ? "Reply" : "Edit Reply", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              TextButton.icon(
                onPressed: () => setState(() => state.setFeedbackStatus(f.id, hidden ? 'Reviewed' : 'Hidden')),
                icon: Icon(hidden ? Icons.visibility_rounded : Icons.visibility_off_outlined, size: 16),
                label: Text(hidden ? "Show" : "Hide", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(foregroundColor: hidden ? _brandColor : AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _replyDialog(AppState state, FeedbackEntry f) {
    final controller = TextEditingController(text: f.adminReply);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reply to ${f.customerName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: AppState.maxFeedbackLength,
          decoration: const InputDecoration(hintText: "Write a short, polite reply..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please type a reply first.")));
                return;
              }
              setState(() => state.replyToFeedback(f.id, controller.text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reply saved.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white),
            child: const Text("SEND REPLY"),
          ),
        ],
      ),
    );
  }
}

class StaffAttendanceMonitoring extends StatefulWidget {
  const StaffAttendanceMonitoring({super.key});

  @override
  State<StaffAttendanceMonitoring> createState() => _StaffAttendanceMonitoringState();
}

class _StaffAttendanceMonitoringState extends State<StaffAttendanceMonitoring> {
  static const Color _brandColor = AppColors.primary;

  final List<Map<String, dynamic>> _staff = [
    {'name': 'Juan Dela Cruz', 'role': 'Washing Staff', 'username': 'juan_dc', 'phone': '', 'active': true},
    {'name': 'Rina Reyes', 'role': 'Folding & Packing', 'username': 'rina_r', 'phone': '', 'active': true},
    {'name': 'Kenneth Santos', 'role': 'Delivery Rider', 'username': 'kenneth_s', 'phone': '', 'active': true},
  ];

  void _showStaffDetails(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text((s['name'] as String)[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brandColor)),
                        Text(s['role'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _detailRow("Username", s['username'] as String),
              _detailRow("Phone", (s['phone'] as String).isEmpty ? "Not set" : s['phone'] as String),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Account active", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: s['active'] as bool,
                activeThumbColor: AppColors.success,
                onChanged: (v) {
                  setSheet(() => s['active'] = v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _brandColor)),
        ],
      ),
    );
  }

  void _addStaff() {
    final nameC = TextEditingController();
    final roleC = TextEditingController();
    final userC = TextEditingController();
    final phoneC = TextEditingController();

    Widget field(TextEditingController c, String label, {TextInputType? type}) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, keyboardType: type, decoration: InputDecoration(labelText: label)),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Staff Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(nameC, "Full name"),
              field(roleC, "Role (e.g. Washing Staff)"),
              field(userC, "Username"),
              field(phoneC, "Phone (optional)", type: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (nameC.text.trim().isEmpty || roleC.text.trim().isEmpty || userC.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name, role and username are required.")));
                return;
              }
              setState(() {
                _staff.add({
                  'name': nameC.text.trim(),
                  'role': roleC.text.trim(),
                  'username': userC.text.trim(),
                  'phone': phoneC.text.trim(),
                  'active': true,
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${nameC.text.trim()} was added to Staff.")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Staff", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaff,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text("Add Staff", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        children: [
          Text("Staff Accounts (${_staff.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandColor)),
          const SizedBox(height: 15),
          ..._staff.map((s) {
            final bool active = s['active'] as bool;
            return BouncingWidget(
              onTap: () => _showStaffDetails(s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text("${s['role']} • @${s['username']}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (active ? AppColors.success : Colors.grey).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        active ? "ACTIVE" : "INACTIVE",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? AppColors.success : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class HistoricalReportScreen extends StatefulWidget {
  const HistoricalReportScreen({super.key});

  @override
  State<HistoricalReportScreen> createState() => _HistoricalReportScreenState();
}

class _HistoricalReportScreenState extends State<HistoricalReportScreen> {
  static const Color _brandColor = AppColors.primary;
  static const List<String> _periods = ["This Week", "Last Week", "This Month", "Last Month", "This Year", "Last Year"];
  static const List<String> _months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  static const List<String> _weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  String _period = "This Week";

  /// Start (included) and end (not included) of the selected period.
  List<DateTime> _range() {
    final now = DateTime.now();
    final thisWeek = AppState.weekStart(now);
    switch (_period) {
      case "Last Week":
        return [thisWeek.subtract(const Duration(days: 7)), thisWeek];
      case "This Month":
        return [DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1)];
      case "Last Month":
        return [DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 1)];
      case "This Year":
        return [DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1)];
      case "Last Year":
        return [DateTime(now.year - 1, 1, 1), DateTime(now.year, 1, 1)];
      default:
        return [thisWeek, thisWeek.add(const Duration(days: 7))];
    }
  }

  String _peso(double v) => "₱${v.toStringAsFixed(2)}";

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final range = _range();
    final start = range[0];
    final end = range[1];
    final now = DateTime.now();
    final bool byMonth = _period == "This Year" || _period == "Last Year";

    // Breakdown rows (days, or months for yearly reports), newest first. Future dates are skipped.
    final rows = <Map<String, dynamic>>[];
    if (byMonth) {
      for (int m = 0; m < 12; m++) {
        final from = DateTime(start.year, m + 1, 1);
        final to = DateTime(start.year, m + 2, 1);
        if (from.isAfter(now)) continue;
        rows.add({'label': "${_months[m]} ${start.year}", 'sales': state.salesInRange(from, to), 'count': state.salesCountInRange(from, to)});
      }
    } else {
      DateTime day = start;
      while (day.isBefore(end)) {
        if (!day.isAfter(now)) {
          final next = day.add(const Duration(days: 1));
          rows.add({
            'label': "${_weekdays[day.weekday - 1]}, ${_months[day.month - 1].substring(0, 3)} ${day.day}",
            'sales': state.salesInRange(day, next),
            'count': state.salesCountInRange(day, next),
          });
        }
        day = day.add(const Duration(days: 1));
      }
    }
    final sortedRows = rows.reversed.toList(); // newest first

    final double totalSales = state.salesInRange(start, end);
    final int totalOrders = state.salesCountInRange(start, end);
    final double cashSales = state.cashSalesInRange(start, end);
    final double onlineSales = totalSales - cashSales;
    final double average = totalOrders > 0 ? totalSales / totalOrders : 0.0;
    double maxSales = 0;
    String bestLabel = "-";
    for (final r in rows) {
      if ((r['sales'] as double) > maxSales) {
        maxSales = r['sales'] as double;
        bestLabel = r['label'] as String;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Sales & Revenue Reports", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _periods.map((p) {
                  final bool selected = _period == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : _brandColor)),
                      selected: selected,
                      selectedColor: _brandColor,
                      backgroundColor: Colors.grey.shade100,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _period = p),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _reportTile("$_period Sales", _peso(totalSales), "$totalOrders paid order${totalOrders == 1 ? '' : 's'}", AppColors.success),
                Row(
                  children: [
                    Expanded(child: _smallTile("Average / Order", _peso(average), AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _smallTile(byMonth ? "Best Month" : "Best Day", bestLabel, AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _smallTile("Cash", _peso(cashSales), const Color(0xFF475569))),
                    const SizedBox(width: 12),
                    Expanded(child: _smallTile("GCash / PayMaya", _peso(onlineSales), const Color(0xFF9333EA))),
                  ],
                ),
                const SizedBox(height: 22),
                Text(byMonth ? "Monthly Breakdown" : "Daily Breakdown", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _brandColor)),
                const SizedBox(height: 4),
                const Text("Newest first", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                if (sortedRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("No sales recorded for this period.", style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...sortedRows.map((r) => _breakdownRow(r['label'] as String, r['sales'] as double, r['count'] as int, maxSales)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, double sales, int count, double maxSales) {
    final double fraction = maxSales > 0 ? sales / maxSales : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink))),
              Text(_peso(sales), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text("$count order${count == 1 ? '' : 's'}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallTile(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _reportTile(String title, String amount, String subtitle, Color color) {
    return BouncingWidget(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(amount, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class AdminLaundryPackagesScreen extends StatelessWidget {
  const AdminLaundryPackagesScreen({super.key});

  void _showEditRateDialog(BuildContext context, AppState state, String title, String key) {
    final controller = TextEditingController(text: _formatRate(state.rateOf(key)));
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Edit Rate", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "New price",
                  prefixText: "₱ ",
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  setDialogState(() => errorText = "Enter a valid price greater than 0");
                  return;
                }
                state.updateRate(key, value);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$title is now ₱${_formatRate(value)}")),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text("SAVE"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final packages = [
      {'title': 'Full Package (Regular Clothes)', 'desc': 'Wash, Dry & Fold • Max 8kg (Free Detergent & FabCon)', 'key': 'regular', 'icon': Icons.local_laundry_service_rounded},
      {'title': 'Individual Wash Only', 'desc': 'Machine wash cycle per load', 'key': 'wash', 'icon': Icons.water_drop_rounded},
      {'title': 'Individual Dry Only', 'desc': 'Heat commercial drying per load', 'key': 'dry', 'icon': Icons.wb_sunny_rounded},
      {'title': 'Individual Fold Only', 'desc': 'Neatly folded & packed', 'key': 'fold', 'icon': Icons.dry_cleaning_rounded},
      {'title': 'Whites (Extras)', 'desc': 'White clothes • Max 7kg', 'key': 'whites', 'icon': Icons.color_lens_outlined},
      {'title': 'Baby Clothes (Extras)', 'desc': 'Max 7kg with gentle baby detergent', 'key': 'baby', 'icon': Icons.child_care_rounded},
      {'title': 'Beddings & Curtains', 'desc': 'Bedsheets, Blankets, Towels • Max 8kg', 'key': 'bedding', 'icon': Icons.bed_rounded},
      {'title': 'Single Size Comforter', 'desc': '1-2 pcs per load', 'key': 'single', 'icon': Icons.hotel_rounded},
      {'title': 'Double Size Comforter', 'desc': '1 pc per load', 'key': 'double', 'icon': Icons.king_bed_rounded},
      {'title': 'Denim, Cargo, Jackets, Sweaters', 'desc': 'Heavy fabrics • Max 6kg', 'key': 'denim', 'icon': Icons.layers_rounded},
      {'title': 'Add-on: Extra Wash Cycle', 'desc': 'Additional 15-min wash cycle • charged once per order', 'key': 'extraWash', 'icon': Icons.sync_rounded},
      {'title': 'Add-on: Extra Detergent', 'desc': 'Extra Ariel Commercial Liquid Detergent • once per order', 'key': 'extraDetergent', 'icon': Icons.sanitizer_rounded},
      {'title': 'Add-on: Extra Fabcon', 'desc': 'Extra Downy Floral Softener • once per order', 'key': 'extraFabcon', 'icon': Icons.local_florist_rounded},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Laundry Packages & Rates", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final p = packages[index];
          return BouncingWidget(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: brandColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(p['icon'] as IconData, color: brandColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                        const SizedBox(height: 3),
                        Text(p['desc'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text("₱${_formatRate(AppStateProvider.of(context).rateOf(p['key'] as String))}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showEditRateDialog(
                      context,
                      AppStateProvider.of(context),
                      p['title'] as String,
                      p['key'] as String,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandColor,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Edit Rate", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String? _activeThreadName; // Null = Inbox view, non-null = Chatting with customer
  String _searchQuery = "";
  final ScrollController _scrollController = ScrollController();

  // Mock Customer Chat Threads
  final List<Map<String, dynamic>> _threads = [
    {
      'id': 'cust-1',
      'name': 'Maria Santos',
      'avatarColor': AppColors.primary,
      'lastMsg': 'Hi Admin! What time is the shop open today?',
      'time': '12m',
      'unread': true,
      'isOnline': true,
      'messages': [
        {'sender': 'Maria Santos', 'text': 'Hi Admin! What time is the shop open today?', 'isUser': true, 'time': '10:15 AM'},
        {'sender': 'Admin John', 'text': 'We are open daily from 7:00 AM to 8:00 PM!', 'isUser': false, 'time': '10:18 AM'},
        {'sender': 'Maria Santos', 'text': 'Salamat po! Pa-check din po ng order status ko #Q-101.', 'isUser': true, 'time': '10:20 AM'},
      ],
    },
    {
      'id': 'cust-2',
      'name': 'Teddy B. Comendador',
      'avatarColor': AppColors.success,
      'lastMsg': 'Teddy sent a photo.',
      'time': '15w',
      'unread': true,
      'isOnline': true,
      'messages': [
        {'sender': 'Teddy B. Comendador', 'text': 'Hi Admin, may special instruction po ako sa barong tagalog.', 'isUser': true, 'time': '8:30 AM'},
        {'sender': 'Teddy B. Comendador', 'text': 'Teddy sent a photo.', 'isUser': true, 'time': '8:32 AM'},
        {'sender': 'Admin John', 'text': 'Sige po Sir Teddy, hand-wash & gentle care po natin.', 'isUser': false, 'time': '8:35 AM'},
      ],
    },
    {
      'id': 'cust-3',
      'name': 'PATHFIT4 - SPORTS - BSCS',
      'avatarColor': AppColors.success,
      'lastMsg': 'Tristan Tibunsay left the group.',
      'time': '16w',
      'unread': true,
      'isOnline': false,
      'messages': [
        {'sender': 'Tristan Tibunsay', 'text': 'Magpapa-wash po kami ng sports uniforms (20 sets).', 'isUser': true, 'time': '2:00 PM'},
        {'sender': 'Admin John', 'text': 'May 10% team discount po tayo para sa bulk orders!', 'isUser': false, 'time': '2:05 PM'},
      ],
    },
    {
      'id': 'cust-4',
      'name': 'BOMX - BOM Rangsit',
      'avatarColor': AppColors.danger,
      'lastMsg': 'Bossing baka may i-upgrade ka n...',
      'time': '19w',
      'unread': false,
      'isOnline': false,
      'messages': [
        {'sender': 'BOMX', 'text': 'Bossing baka may i-upgrade ka na laundry equipment?', 'isUser': true, 'time': '11:00 AM'},
      ],
    },
    {
      'id': 'cust-5',
      'name': 'Nolram Gonzalo',
      'avatarColor': const Color(0xFF8B5CF6),
      'lastMsg': 'Inquire lang po ng comforter rate.',
      'time': '21w',
      'unread': false,
      'isOnline': false,
      'messages': [
        {'sender': 'Nolram Gonzalo', 'text': 'Inquire lang po ng comforter rate.', 'isUser': true, 'time': '4:12 PM'},
        {'sender': 'Admin John', 'text': '₱200/pc po para sa double size comforter.', 'isUser': false, 'time': '4:15 PM'},
      ],
    },
    {
      'id': 'cust-6',
      'name': 'Leonne Ylizze Ongtangco',
      'avatarColor': AppColors.primary,
      'lastMsg': 'bahay',
      'time': '24w',
      'unread': true,
      'isOnline': false,
      'messages': [
        {'sender': 'Leonne Ylizze', 'text': 'Saan po pwedeng i-drop off?', 'isUser': true, 'time': '1:20 PM'},
        {'sender': 'Admin John', 'text': 'Sa main branch po sa Sunrise Subdivision.', 'isUser': false, 'time': '1:22 PM'},
        {'sender': 'Leonne Ylizze', 'text': 'bahay', 'isUser': true, 'time': '1:25 PM'},
      ],
    },
    {
      'id': 'cust-7',
      'name': 'Jhayrenz Rotal',
      'avatarColor': const Color(0xFFEA580C),
      'lastMsg': 'Oo',
      'time': '24w',
      'unread': false,
      'isOnline': false,
      'messages': [
        {'sender': 'Jhayrenz Rotal', 'text': 'Available po ba ngayon?', 'isUser': true, 'time': '9:00 AM'},
        {'sender': 'Admin John', 'text': 'Opo, open po kami hanggang 8pm.', 'isUser': false, 'time': '9:02 AM'},
        {'sender': 'Jhayrenz Rotal', 'text': 'Oo', 'isUser': true, 'time': '9:03 AM'},
      ],
    },
    {
      'id': 'cust-8',
      'name': 'Lisa Cambia Comendador',
      'avatarColor': AppColors.ink,
      'lastMsg': 'lance si mama',
      'time': '25w',
      'unread': true,
      'isOnline': true,
      'messages': [
        {'sender': 'Lisa Cambia', 'text': 'lance si mama', 'isUser': true, 'time': '7:30 PM'},
        {'sender': 'Admin John', 'text': 'Opo Ma, na-receive ko na po laundry natin.', 'isUser': false, 'time': '7:32 PM'},
      ],
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedThreadData {
    if (_activeThreadName == null) return null;
    try {
      return _threads.firstWhere((t) => t['name'] == _activeThreadName);
    } catch (_) {
      return _threads.first;
    }
  }

  List<Map<String, dynamic>> get _filteredThreads {
    final q = _searchQuery.toLowerCase();
    return _threads.where((t) {
      final name = (t['name'] as String).toLowerCase();
      final msg = (t['lastMsg'] as String).toLowerCase();
      return name.contains(q) || msg.contains(q);
    }).toList();
  }

  void _openThread(Map<String, dynamic> t) {
    setState(() {
      _activeThreadName = t['name'] as String;
      t['unread'] = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeThreadName == null) return;

    final thread = _selectedThreadData;
    if (thread != null) {
      setState(() {
        (thread['messages'] as List).add({
          'sender': 'Admin John',
          'text': text,
          'isUser': false,
          'time': "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        });
        thread['lastMsg'] = text;
        thread['time'] = 'Just now';
        thread['unread'] = false;
      });
      _messageController.clear();
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    // Tablet / landscape: Messenger-style two panes (users on the left, chat on the right).
    // Phone: inbox first, then the conversation.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) return _buildWideLayout(brandColor);
        if (_activeThreadName != null) return _buildConversationView(brandColor);
        return _buildInboxView(brandColor);
      },
    );
  }

  // --- SHARED PIECES ---
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: "Search customer messages...",
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildThreadList(List<Map<String, dynamic>> filtered, {bool highlightSelected = false}) {
    if (filtered.isEmpty) {
      return const Center(child: Text("No messages found.", style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        final bool isUnread = t['unread'] as bool;
        final bool isOnline = t['isOnline'] as bool;
        final bool isSelected = highlightSelected && t['name'] == _activeThreadName;

        return BouncingWidget(
          onTap: () => _openThread(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySoft : (isUnread ? AppColors.primarySoft : Colors.transparent),
              border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: t['avatarColor'] as Color,
                      child: Text(
                        (t['name'] as String)[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    if (isOnline)
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: AnimatedPulseBadge(color: AppColors.success, size: 8),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['name'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t['lastMsg'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                color: isUnread ? AppColors.primary : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            " • ${t['time']}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerContent(Map<String, dynamic> thread) {
    final bool isOnline = thread['isOnline'] as bool;
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text((thread['name'] as String)[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (isOnline)
              const Positioned(
                right: 0,
                bottom: 0,
                child: AnimatedPulseBadge(color: AppColors.success, size: 6),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thread['name'] as String,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                isOnline ? "Active now" : "Offline",
                style: TextStyle(fontSize: 11, color: isOnline ? const Color(0xFF86EFAC) : Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messagesList(Map<String, dynamic> thread) {
    final List messages = thread['messages'] as List;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxBubble = constraints.maxWidth * 0.7;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index] as Map<String, dynamic>;
            final isCustomer = msg['isUser'] as bool;

            return Align(
              alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isCustomer) ...[
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: thread['avatarColor'] as Color,
                        child: Text((thread['name'] as String)[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      constraints: BoxConstraints(maxWidth: maxBubble),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isCustomer
                            ? null
                            : const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        color: isCustomer ? Colors.white : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isCustomer ? 4 : 20),
                          bottomRight: Radius.circular(isCustomer ? 20 : 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isCustomer ? Colors.black : AppColors.primary).withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          Text(
                            msg['text'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: isCustomer ? AppColors.ink : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'] as String,
                            style: TextStyle(fontSize: 9, color: isCustomer ? AppColors.textMuted : Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Aa",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          BouncingWidget(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // --- TABLET / LANDSCAPE: users in a column on the left, conversation on the right ---
  Widget _buildWideLayout(Color brandColor) {
    final thread = _selectedThreadData;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Messenger Chats", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 340,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildSearchBar(),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(child: _buildThreadList(_filteredThreads, highlightSelected: true)),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: thread == null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.chat_bubble_outline_rounded, size: 50, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  const Text("Select a conversation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text("Choose a customer on the left to start chatting.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            )
                : Column(
              children: [
                Container(
                  color: brandColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: _headerContent(thread),
                ),
                Expanded(child: _messagesList(thread)),
                _inputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PHONE: MESSENGER INBOX VIEW ---
  Widget _buildInboxView(Color brandColor) {
    final online = _threads.where((t) => t['isOnline'] as bool).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Messenger Chats", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),

          // Active customers row
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: online.length,
              itemBuilder: (context, index) {
                final t = online[index];
                return GestureDetector(
                  onTap: () => _openThread(t),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: t['avatarColor'] as Color,
                              child: Text((t['name'] as String)[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: AnimatedPulseBadge(color: AppColors.success, size: 8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (t['name'] as String).split(' ')[0],
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          Expanded(child: _buildThreadList(_filteredThreads)),
        ],
      ),
    );
  }

  // --- PHONE: CONVERSATION VIEW ---
  Widget _buildConversationView(Color brandColor) {
    final thread = _selectedThreadData!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => setState(() => _activeThreadName = null),
        ),
        title: _headerContent(thread),
        actions: [
          IconButton(icon: const Icon(Icons.phone_rounded, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam_rounded, size: 22), onPressed: () {}),
          IconButton(icon: const Icon(Icons.info_outline_rounded, size: 22), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _messagesList(thread)),
          _inputBar(),
        ],
      ),
    );
  }
}

// --- ADMIN ORDER & PAYMENT HISTORY RECORD SCREEN ---
class AdminHistoryRecordScreen extends StatefulWidget {
  const AdminHistoryRecordScreen({super.key});

  @override
  State<AdminHistoryRecordScreen> createState() => _AdminHistoryRecordScreenState();
}

class _AdminHistoryRecordScreenState extends State<AdminHistoryRecordScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _paymentFilter = "All";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final orders = state.orders;

    final filteredOrders = orders.where((o) {
      // Cash orders are only recorded once claimed; GCash/PayMaya are recorded right away.
      final bool isRecorded = (o.paymentMethod ?? 'Cash') != 'Cash' || o.status == 'Claimed';
      if (!isRecorded) return false;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = o.customerName.toLowerCase().contains(q) ||
          o.queueNumber.toLowerCase().contains(q) ||
          o.customerPhone.contains(q);
      final matchesFilter = _paymentFilter == "All" ||
          (_paymentFilter == "Paid" && o.paymentStatus == "Paid") ||
          (_paymentFilter == "Cash" && o.paymentMethod == "Cash") ||
          (_paymentFilter == "GCash" && o.paymentMethod == "GCash") ||
          (_paymentFilter == "PayMaya" && o.paymentMethod == "PayMaya");
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Order & Payment History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search by customer name, order ID, or phone...",
                    prefixIcon: const Icon(Icons.search, color: brandColor),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Paid", "Cash", "GCash", "PayMaya"].map((filter) {
                      bool isSelected = _paymentFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : brandColor)),
                          selected: isSelected,
                          selectedColor: brandColor,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) => setState(() => _paymentFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Orders & Payment History List
          Expanded(
            child: filteredOrders.isEmpty
                ? _buildEmptyHistoryState()
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final o = filteredOrders[index];
                return _buildHistoryRecordCard(context, o, brandColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 55, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text("No order history records found.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text("Completed or placed user orders will appear here.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHistoryRecordCard(BuildContext context, LaundryOrderModel order, Color brandColor) {
    // Green once the order is claimed; amber while it is still in process.
    final bool isClaimed = order.status == 'Claimed';
    final Color statusColor = isClaimed ? AppColors.success : AppColors.warning;
    String payRef = "PAY-${order.queueNumber.replaceAll('Q-', '')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: () => _showRecordDetailsModal(context, order, payRef),
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isClaimed ? Icons.receipt_long_rounded : Icons.pending_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.queueNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandColor)),
              Text("₱${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${order.customerName} • ${order.customerPhone}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${order.serviceType} (${order.paymentMethod ?? 'Cash'})", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isClaimed ? "Claimed" : "In Process",
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ),
      ),
    );
  }

  void _showRecordDetailsModal(BuildContext context, LaundryOrderModel order, String payRef) {
    const brandColor = AppColors.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Order & Payment Record", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandColor)),
            const SizedBox(height: 4),
            Text("Full transaction history and order details.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 20),

            _infoRow("Order Queue ID", order.queueNumber),
            _infoRow("Payment Transaction Ref", payRef),
            _infoRow("Customer Name", order.customerName),
            _infoRow("Contact Phone", order.customerPhone),
            _infoRow("Service Package", order.serviceType),
            _infoRow("Fabric Weight", "${order.weightKg.toStringAsFixed(1)} kg"),
            _infoRow("Payment Method", "${order.paymentMethod ?? 'Cash'} (${order.paymentStatus})"),
            _infoRow("Created Date/Time", order.createdAt),
            _infoRow("Current Status", order.status),
            if (order.staffNotes.isNotEmpty) _infoRow("Staff Record Notes", order.staffNotes),

            const Spacer(),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL PAID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandColor)),
                Text("₱${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await shareReceiptPdf(
                            orderId: order.queueNumber,
                            customerName: order.customerName,
                            phone: order.customerPhone,
                            details: [
                              MapEntry('Service Package', order.serviceType),
                              MapEntry('Fabric Weight', "${order.weightKg.toStringAsFixed(1)} kg"),
                              MapEntry('Status', order.status),
                              MapEntry('Payment Ref', payRef),
                            ],
                            total: order.totalAmount,
                            paymentMethod: order.paymentMethod ?? 'Cash',
                            paymentStatus: order.paymentStatus,
                            dateText: order.createdAt,
                          );
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not create the receipt. Please try again.")),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("RECEIPT PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brandColor,
                        side: const BorderSide(color: brandColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text("CLOSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// --- MAIN SHELLS ---

class MainPortalShell extends StatelessWidget {
  const MainPortalShell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    return state.currentRole == UserRole.admin ? const AdminShell() : const CustomerShell();
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedDrawerIndex = 0;
  bool _persistentSidebar = false; // true on tablets: sidebar stays open on the left

  final List<Widget> _adminScreens = [
    const AdminDashboardScreen(),
    const AdminOrdersScreen(),
    const CustomerDirectoryScreen(),
    const AdminHistoryRecordScreen(),
    const ManagerDashboard(),
    const HistoricalReportScreen(),
    const StaffAttendanceMonitoring(),
    const AdminLaundryPackagesScreen(),
    const AdminChatScreen(),
    const AdminProfileScreen(),
    const AdminInventoryScreen(),
    const AdminFeedbackScreen(),
    const AdminPaymentQrScreen(),
  ];

  final List<String> _screenTitles = const [
    "Dashboard Operations",
    "Order Queue & Board",
    "Customer Directory",
    "Order & Payment History",
    "Financial Analytics",
    "Sales & Revenue Reports",
    "Staff",
    "Laundry Packages & Rates",
    "Customer Live Chat",
    "Admin Profile",
    "Inventory Stock & Alerts",
    "Customer Feedback",
    "Payment QR Codes",
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    const brandColor = AppColors.primary;
    final bool wide = MediaQuery.of(context).size.width >= 1000;
    _persistentSidebar = wide;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !wide,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "G A LAUNDRY ADMIN",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            Text(
              "Admin • ${_screenTitles[_selectedDrawerIndex]}",
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                if (state.messages.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '${state.messages.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminChatScreen()),
              );
            },
            tooltip: "Customer Live Chat",
          ),
          IconButton(
            icon: Badge(
              label: Text("${state.unreadAdminCount}"),
              isLabelVisible: state.unreadAdminCount > 0,
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNotificationsScreen()),
              );
            },
            tooltip: "Notifications",
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: _sidebarContent(context, state)),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) SizedBox(width: 270, child: _sidebarContent(context, state)),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(child: IndexedStack(index: _selectedDrawerIndex, children: _adminScreens)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarContent(BuildContext context, AppState state) {
    return Material(
      color: AppColors.ink,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings_rounded, size: 32, color: AppColors.primary),
              ),
            ),
            accountName: Text(state.loggedInName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: const Text("admin@galaundry.com • System Owner", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              children: [
                _drawerHeader("OPERATIONS"),
                _drawerTile(0, Icons.grid_view_rounded, "Dashboard Operations"),
                _drawerTile(1, Icons.receipt_long_rounded, "Order Queue & Board"),
                _drawerTile(2, Icons.people_alt_rounded, "Customer Directory"),
                _drawerTile(3, Icons.history_edu_rounded, "Order & Payment History"),
                _drawerTile(10, Icons.warehouse_rounded, "Inventory Stock & Alerts"),

                const Divider(color: Colors.white24, height: 25),
                _drawerHeader("FINANCIALS & REPORTS"),
                _drawerTile(4, Icons.analytics_rounded, "Financial Analytics"),
                _drawerTile(5, Icons.assessment_rounded, "Sales & Revenue Reports"),
                _drawerTile(6, Icons.badge_rounded, "Staff"),

                const Divider(color: Colors.white24, height: 25),
                _drawerHeader("PACKAGES & CHAT"),
                _drawerTile(7, Icons.inventory_2_rounded, "Laundry Packages & Rates"),
                _drawerTile(8, Icons.chat_bubble_rounded, "Customer Live Chat"),
                _drawerTile(11, Icons.rate_review_rounded, "Customer Feedback"),
                _drawerTile(12, Icons.qr_code_2_rounded, "Payment QR Codes"),

                const Divider(color: Colors.white24, height: 25),
                _drawerHeader("SETTINGS"),
                _drawerTile(9, Icons.person_rounded, "Admin Profile"),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
                  title: const Text("Logout Admin", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                  onTap: () {
                    if (!_persistentSidebar) Navigator.pop(context);
                    state.logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _drawerTile(int index, IconData icon, String title) {
    bool isSelected = _selectedDrawerIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        tileColor: isSelected ? AppColors.accent.withValues(alpha: 0.18) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? AppColors.accent : Colors.white70, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        onTap: () {
          setState(() => _selectedDrawerIndex = index);
          if (!_persistentSidebar) Navigator.pop(context);
        },
      ),
    );
  }
}



class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key});
  @override
  Widget build(BuildContext context) {
    return const CustomerHomeScreen();
  }
}

// --- ADMIN SCREENS ---

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final revenue = state.orders.where((o) => o.paymentStatus == 'Paid').fold(0.0, (sum, o) => sum + o.totalAmount);
    final bool wide = MediaQuery.of(context).size.width >= 720;

    final Widget chart = FadeAndSlide(
      delay: const Duration(milliseconds: 150),
      child: _buildOrdersOverviewChart(state),
    );
    final List<Widget> stock = [
      const Text('Inventory Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
      const SizedBox(height: 12),
      _buildStockItem('Detergent (Ariel Commercial)', state.detergentStockKg, state.detergentCapacityKg, AppColors.primary),
      const SizedBox(height: 10),
      _buildStockItem('Softener (Downy Floral)', state.softenerStockL, state.softenerCapacityL, AppColors.accent),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeAndSlide(
            child: _buildAdminStatGrid(context, state, revenue, wide: wide),
          ),
          const SizedBox(height: 20),
          if (wide)
          // Tablet: chart on the left, inventory on the right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: chart),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: stock)),
              ],
            )
          else ...[
            chart,
            const SizedBox(height: 24),
            ...stock,
          ],
        ],
      ),
    );
  }

  Widget _buildAdminStatGrid(BuildContext context, AppState state, double revenue, {bool wide = false}) {
    final totalOrders = state.orders.length;
    final pending = state.orders.where((o) => o.status != 'Claimed' && o.status != 'Ready').length;
    final completed = state.orders.where((o) => o.status == 'Claimed' || o.status == 'Ready').length;
    final revAmount = state.todaySales; // today's saved sales

    final List<Widget> row1 = [
      Expanded(
        child: _buildRichMetricWidget(
          title: "Total Orders",
          value: "$totalOrders",
          badgeText: "${state.ordersThisWeek} this week",
          badgeColor: AppColors.success,
          icon: Icons.local_laundry_service_rounded,
          iconBgColor: AppColors.primary,
          bgGradient: const LinearGradient(
            colors: [AppColors.primarySoft, AppColors.primarySoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppColors.aqua,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildRichMetricWidget(
          title: "Today's Revenue",
          value: "₱${revAmount.toStringAsFixed(0)}",
          badgeText: "₱${state.salesThisWeek.toStringAsFixed(0)} this week",
          badgeColor: AppColors.success,
          icon: Icons.account_balance_wallet_rounded,
          iconBgColor: AppColors.success,
          bgGradient: const LinearGradient(
            colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: const Color(0xFFA7F3D0),
        ),
      ),
    ];
    final List<Widget> row2 = [
      Expanded(
        child: _buildRichMetricWidget(
          title: "Pending Orders",
          value: "$pending",
          badgeText: "In Queue",
          badgeColor: AppColors.warning,
          icon: Icons.hourglass_top_rounded,
          iconBgColor: AppColors.warning,
          bgGradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: const Color(0xFFFED7AA),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildRichMetricWidget(
          title: "Completed Orders",
          value: "$completed",
          badgeText: "Ready & Claimed",
          badgeColor: AppColors.primary,
          icon: Icons.check_circle_rounded,
          iconBgColor: AppColors.primary,
          bgGradient: const LinearGradient(
            colors: [AppColors.primarySoft, AppColors.primarySoft],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: AppColors.aqua,
        ),
      ),
    ];

    // Tablet: all four cards in one row. Phone: 2 x 2 grid.
    if (wide) {
      return Row(children: [...row1, const SizedBox(width: 12), ...row2]);
    }
    return Column(
      children: [
        Row(children: row1),
        const SizedBox(height: 12),
        Row(children: row2),
      ],
    );
  }

  Widget _buildRichMetricWidget({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconBgColor,
    required LinearGradient bgGradient,
    required Color borderColor,
  }) {
    return BouncingWidget(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: iconBgColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconBgColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconBgColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badgeText.contains('↑') ? Icons.trending_up_rounded : Icons.fiber_manual_record,
                    size: 11,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersOverviewChart(AppState state) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = state.ordersPerDayThisWeek();
    final int maxCount = counts.fold(0, (m, c) => c > m ? c : m);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Orders Overview",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    Text(
                      "${state.ordersThisWeek} orders placed this week",
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("This Week", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                final int count = counts[index];
                final double h = maxCount == 0 ? 0.0 : count / maxCount;
                final bool isHighest = maxCount > 0 && count == maxCount;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "$count",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHighest ? AppColors.primary : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      width: 18,
                      height: 4 + 62 * h,
                      decoration: BoxDecoration(
                        gradient: isHighest
                            ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )
                            : LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.8),
                            AppColors.accent.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
                        color: isHighest ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(String name, double current, double max, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink)),
              Text('${current} / $max', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: current / max,
            backgroundColor: const Color(0xFFF1F5F9),
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    // FIFO: oldest order first. New orders are inserted at the top of state.orders,
    // so reversing gives First In, First Out.
    final orders = state.orders.where((o) => o.status != 'Claimed').toList().reversed.toList();
    // The next order to claim is the oldest one that is still 'Received'.
    String? nextToClaimId;
    for (final o in orders) {
      if (o.status == 'Received') {
        nextToClaimId = o.id;
        break;
      }
    }

    // Tablet: queue on the left, selected order details on the right.
    final bool wide = MediaQuery.of(context).size.width >= 840;
    LaundryOrderModel? selected;
    if (wide && orders.isNotEmpty) {
      selected = orders.firstWhere((o) => o.id == _selectedId, orElse: () => orders.first);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: orders.isEmpty
          ? _buildEmptyOrdersState()
          : (wide ? _buildWideBody(orders, nextToClaimId, selected!, state) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.aqua),
              ),
              child: const Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "First In, First Out: orders are handled from oldest to newest. Claim the order marked NEXT first.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            );
          }
          final int idx = i - 1;
          final o = orders[idx];
          final bool isUnclaimedNewOrder = o.status == 'Received';
          final bool isNext = o.id == nextToClaimId;

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isNext ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isNext ? "QUEUE #${idx + 1} • NEXT" : "QUEUE #${idx + 1}",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNext ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${o.queueNumber} - ${o.customerName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandColor),
                      ),
                      OrderStatusBadge(status: o.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${o.serviceType} • ₱${o.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Payment: ${o.paymentStatus} (${o.paymentMethod ?? 'Cash'})", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text("Phone: ${o.customerPhone}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      if (isUnclaimedNewOrder)
                        ElevatedButton.icon(
                          onPressed: !isNext
                              ? null
                              : () {
                            setState(() {
                              state.updateOrderStatus(o.id, 'In Process');
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Order ${o.queueNumber} Claimed! Status changed to In Process.')),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: Text(isNext ? 'CLAIM' : 'WAIT FOR #1', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrderDetailUpdateScreen(order: o)),
                            );
                          },
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('UPDATE STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildWideBody(List<LaundryOrderModel> orders, String? nextToClaimId, LaundryOrderModel selected, AppState state) {
    return Row(
      children: [
        SizedBox(
          width: 400,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.aqua),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "First In, First Out: handle orders from oldest to newest. Claim the order marked NEXT first.",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, idx) {
                    final o = orders[idx];
                    return _compactOrderTile(o, idx, o.id == nextToClaimId, o.id == selected.id);
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.border),
        Expanded(child: _buildOrderDetailPane(selected, selected.id == nextToClaimId, state)),
      ],
    );
  }

  Widget _compactOrderTile(LaundryOrderModel o, int idx, bool isNext, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedId = o.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 1.8 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isNext ? AppColors.primary : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isNext ? "QUEUE #${idx + 1} • NEXT" : "QUEUE #${idx + 1}",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isNext ? Colors.white : AppColors.textSecondary),
                  ),
                ),
                const Spacer(),
                OrderStatusBadge(status: o.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('${o.queueNumber} - ${o.customerName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
            const SizedBox(height: 3),
            Text('${o.serviceType} • ₱${o.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailPane(LaundryOrderModel o, bool isNext, AppState state) {
    // Orders that are already being processed use the same status screen as the phone view.
    if (o.status != 'Received') {
      return OrderDetailUpdateScreen(key: ValueKey('${o.id}-${o.status}'), order: o, embedded: true);
    }

    const brandColor = AppColors.primary;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: brandColor)),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: brandColor.withValues(alpha: 0.05), blurRadius: 15)],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(o.queueNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandColor)),
                    OrderStatusBadge(status: o.status),
                  ],
                ),
                const SizedBox(height: 12),
                row("Customer Name", o.customerName),
                row("Phone Number", o.customerPhone),
                row("Service Package", o.serviceType),
                row("Payment Method", "${o.paymentMethod ?? 'Cash'} (${o.paymentStatus})"),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("₱${o.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (!isNext)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Text(
                "This order is not first in line. Claim the order marked NEXT first (first in, first out).",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: !isNext
                  ? null
                  : () {
                setState(() {
                  state.updateOrderStatus(o.id, 'In Process');
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order ${o.queueNumber} Claimed! Status changed to In Process.')),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(isNext ? 'CLAIM THIS ORDER' : 'WAIT FOR #1', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text("No orders placed yet.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 6),
          Text("Orders placed by customers will appear here.", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}

// --- DEDICATED ORDER DETAIL STATUS UPDATE PAGE ---
class OrderDetailUpdateScreen extends StatefulWidget {
  final LaundryOrderModel order;
  final bool embedded; // true when shown inside the tablet split view
  const OrderDetailUpdateScreen({super.key, required this.order, this.embedded = false});

  @override
  State<OrderDetailUpdateScreen> createState() => _OrderDetailUpdateScreenState();
}

class _OrderDetailUpdateScreenState extends State<OrderDetailUpdateScreen> {
  int _getStageIndex(String status) {
    if (status == 'Claimed') return 3;
    if (status == 'Ready to Claim' || status == 'Ready for Pickup' || status == 'Ready') return 2;
    return 1; // Default: 'In Process' or 'Received'
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final o = widget.order;
    final int currentStage = _getStageIndex(o.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded ? null : AppBar(
        title: const Text("Update Order Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Summary Card on Top
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: brandColor.withValues(alpha: 0.05), blurRadius: 15)],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(o.queueNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandColor)),
                      OrderStatusBadge(status: o.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow("Customer Name", o.customerName),
                  _infoRow("Phone Number", o.customerPhone),
                  _infoRow("Service Package", o.serviceType),
                  _infoRow("Payment Method", "${o.paymentMethod ?? 'Cash'} (${o.paymentStatus})"),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text("₱${o.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text("Order Status Timeline", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandColor)),
            const SizedBox(height: 12),

            // Horizontal ROW Style Status Stepper
            _buildHorizontalStatusRow(currentStage),

            const SizedBox(height: 35),

            // One-Way Forward Action Button (Isang Derechahan, Bawal Bumalik)
            _buildForwardActionButton(context, state, o, currentStage),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalStatusRow(int currentStage) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStageItem(1, "In Process", Icons.water_drop_rounded, AppColors.primary, currentStage),
          _buildStageDivider(1, currentStage),
          _buildStageItem(2, "Ready to Claim", Icons.check_circle_rounded, AppColors.success, currentStage),
          _buildStageDivider(2, currentStage),
          _buildStageItem(3, "Claimed", Icons.shopping_bag_rounded, AppColors.accent, currentStage),
        ],
      ),
    );
  }

  Widget _buildStageItem(int stageIndex, String label, IconData icon, Color color, int currentStage) {
    bool isCompleted = currentStage >= stageIndex;
    bool isCurrent = currentStage == stageIndex;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted ? color : Colors.grey.shade300,
              width: isCurrent ? 2.5 : 1,
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted ? color : Colors.grey.shade400,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCompleted ? AppColors.primary : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStageDivider(int fromStage, int currentStage) {
    bool isDone = currentStage > fromStage;
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDone ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildForwardActionButton(BuildContext context, AppState state, LaundryOrderModel order, int currentStage) {
    if (currentStage == 1) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            state.updateOrderStatus(order.id, 'Ready to Claim');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Push notification sent to ${order.customerName}: the order is ready to claim.')),
            );
          },
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          label: const Text(
            "ADVANCE TO READY TO CLAIM ➔",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
          ),
        ),
      );
    } else if (currentStage == 2) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            state.updateOrderStatus(order.id, 'Claimed');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Order #${order.queueNumber} marked as CLAIMED!')),
            );
            if (!widget.embedded) Navigator.pop(context);
          },
          icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
          label: const Text(
            "MARK AS CLAIMED ➔",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white70),
          label: const Text(
            "ORDER COMPLETED & CLAIMED ✅",
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});
  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  late CustomerModel _selectedCustomer;
  String _selectedService = 'Full Package (Regular Clothes)';
  FabricCategory _category = FabricCategory.thinRegular;
  double _weightKg = 5.0;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = AppStateProvider.of(context).customers.first;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final rec = BatchRecommendation.calculate(_weightKg, _category);
    double total = 170.0;
    if (_selectedService == 'Full Package (Regular Clothes)') total = 170.0;
    if (_selectedService == 'Whites / Baby Clothes (Extras)') total = 185.0;
    if (_selectedService == 'Beddings / Comforter / Heavy') total = 200.0;
    if (_selectedService == 'Wash Only') total = 60.0;
    if (_selectedService == 'Dry Only') total = 60.0;
    if (_selectedService == 'Fold Only') total = 30.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New Laundry Order', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Customer Record', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: DropdownButtonHideUnderline(child: DropdownButton<CustomerModel>(
              value: _selectedCustomer, isExpanded: true,
              items: state.customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.phone})'))).toList(),
              onChanged: (v) => setState(() => _selectedCustomer = v!),
            )),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _selectedService, decoration: const InputDecoration(labelText: 'Service Package'),
            items: const [
              DropdownMenuItem(value: 'Full Package (Regular Clothes)', child: Text('Full Package (₱170 - Max 8kg)')),
              DropdownMenuItem(value: 'Whites / Baby Clothes (Extras)', child: Text('Whites / Baby Clothes (₱185 - Max 7kg)')),
              DropdownMenuItem(value: 'Beddings / Comforter / Heavy', child: Text('Beddings / Comforter / Heavy (₱200)')),
              DropdownMenuItem(value: 'Wash Only', child: Text('Wash Only (₱60)')),
              DropdownMenuItem(value: 'Dry Only', child: Text('Dry Only (₱60)')),
              DropdownMenuItem(value: 'Fold Only', child: Text('Fold Only (₱30)')),
            ],
            onChanged: (v) => setState(() => _selectedService = v!),
          ),
          const SizedBox(height: 20),
          const Text('Fabric Categorization', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<FabricCategory>(
            segments: const [ButtonSegment(value: FabricCategory.thinRegular, label: Text('Thin/Regular')), ButtonSegment(value: FabricCategory.thickHeavy, label: Text('Thick/Heavy'))],
            selected: {_category}, onSelectionChanged: (s) => setState(() => _category = s.first),
          ),
          const SizedBox(height: 20),
          Text('Weight: ${_weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: _weightKg, min: 1, max: 20, onChanged: (v) => setState(() => _weightKg = v)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Batch Tier: ${rec.tier}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              Text('Machine: ${rec.suggestedWasher}'),
              Text('Est. Runtime: ${rec.estDurationMinutes} mins'),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              state.createOrder(customer: _selectedCustomer, serviceType: _selectedService, category: _category, weightKg: _weightKg, totalAmount: total, paymentStatus: 'Paid', paymentMethod: 'Cash');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Created Successfully! 🎉')));
              state.updateTab(1);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text('Submit Order (₱${total.toStringAsFixed(2)})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }
}

void showShopClosedDialog(BuildContext context) {
  final state = AppStateProvider.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.access_time_filled_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(child: Text("Shop is Closed", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        ],
      ),
      content: Text(state.shopClosedMessage, style: const TextStyle(fontSize: 13, height: 1.4)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

// --- CUSTOMER SCREENS ---

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  static bool _closedNoticeShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _closedNoticeShown) return;
      if (!AppStateProvider.of(context).isShopOpen) {
        _closedNoticeShown = true;
        showShopClosedDialog(context);
      }
    });
  }

  List<Widget> get _screens => [
    HomeTab(onProfileTap: () => setState(() => _selectedIndex = 4)),
    const HistoryScreen(),
    const SizedBox(), // Placeholder for Add Order modal/screen
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ["Dashboard", "Order History", "Place Order", "Notifications", "Profile"];

  PreferredSizeWidget _buildAppBar() {
    // Home, Notifications and Profile draw their own header
    final bool ownsHeader = _selectedIndex == 0 || _selectedIndex == 3 || _selectedIndex == 4;
    if (ownsHeader) {
      return const PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: SizedBox.shrink(),
      );
    }

    return AppBar(
      title: Text(_titles[_selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: ResponsiveCenter(maxWidth: 720, child: _screens[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderFormScreen()));
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            const BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: "History"),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
              label: "Book",
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text("${state.unreadCustomerCount}"),
                isLabelVisible: state.unreadCustomerCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              label: "Notifications",
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  final VoidCallback onProfileTap;

  const HomeTab({super.key, required this.onProfileTap});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good morning";
    } else if (hour >= 12 && hour < 18) {
      return "Good afternoon";
    } else {
      return "Good evening";
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final activeOrder = state.activeOrder;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeAndSlide(
                  child: _buildServicesGrid(context),
                ),
                const SizedBox(height: 30),
                FadeAndSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Current Progress"),
                      const SizedBox(height: 15),
                      _buildLargeActiveOrderCard(context, activeOrder),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                FadeAndSlide(
                  delay: const Duration(milliseconds: 200),
                  child: _buildRewardsCard(context, state),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${_getGreeting()},",
                        style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Text("👋", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${state.currentFullName}!",
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                  ),
                ],
              ),
              Row(
                children: [
                  BouncingWidget(
                    onTap: () => _showAdminChatModal(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncingWidget(
                    onTap: onProfileTap,
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 24),
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: AnimatedPulseBadge(color: AppColors.success, size: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHeroBanner(context),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return BouncingWidget(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OrderFormScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.local_laundry_service_rounded,
                size: 110,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "FRESH LAUNDRY GUARANTEE",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Fresh Clothes,\nFresh Start!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Quality laundry services at your convenience.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Book Now",
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openShopInMaps() async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=Brgy.+Bambang,+Nagcarlan,+Laguna');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildShopLocation() {
    return GestureDetector(
      onTap: _openShopInMaps,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Brgy. Bambang, Nagcarlan, Laguna',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShopLocation(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Our Services",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderFormScreen()),
              ),
              child: const Text(
                "View All",
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildServiceCategoryCard(
              context,
              title: "Wash & Fold",
              description: "Fresh, clean, and neatly folded clothes.",
              price: "₱70 / kg",
              icon: Icons.local_laundry_service_rounded,
              iconBg: AppColors.primarySoft,
              iconColor: AppColors.primary,
              borderColor: AppColors.aqua,
            ),
            _buildServiceCategoryCard(
              context,
              title: "Dry Cleaning",
              description: "For your special and delicate items.",
              price: "₱150 / item",
              icon: Icons.dry_cleaning_rounded,
              iconBg: const Color(0xFFECFDF5),
              iconColor: AppColors.success,
              borderColor: const Color(0xFFA7F3D0),
            ),
            _buildServiceCategoryCard(
              context,
              title: "Express Service",
              description: "Need it fast? We've got you covered.",
              price: "₱100 / kg",
              icon: Icons.bolt_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF9333EA),
              borderColor: const Color(0xFFE9D5FF),
            ),
            _buildServiceCategoryCard(
              context,
              title: "Comforters & Bedding",
              description: "Big items, handled with extra care.",
              price: "₱250 / item",
              icon: Icons.king_bed_rounded,
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFEA580C),
              borderColor: const Color(0xFFFED7AA),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCategoryCard(
      BuildContext context, {
        required String title,
        required String description,
        required String price,
        required IconData icon,
        required Color iconBg,
        required Color iconColor,
        required Color borderColor,
      }) {
    return BouncingWidget(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderFormScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "Book Now",
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeActiveOrderCard(BuildContext context, Order? order) {
    final bool hasOrder = order != null;
    final String orderId = hasOrder ? "ORDER ID: ${order.id}" : "ID: ----";
    final String statusTitle = hasOrder ? order.status : "No Active Order";
    final double progress = hasOrder ? _getProgressForStatus(order.status) : 0.0;
    final String statusSubtitle = hasOrder ? _getSubtitleForStatus(order.status) : "Place an order to start tracking in real-time.";

    final style = _getCardStyle(hasOrder, progress);
    final Color progressColor = style['color'] as Color;
    final IconData progressIcon = style['icon'] as IconData;
    final String progressPercent = style['percent'] as String;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderId, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(statusTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Icon(progressIcon, size: 42, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(progressPercent, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          if (hasOrder) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timelineStep("Received", _isStepDone(order.status, 1)),
                  _timelineDivider(_isStepDone(order.status, 2)),
                  _timelineStep("Washing", _isStepDone(order.status, 2)),
                  _timelineDivider(_isStepDone(order.status, 3)),
                  _timelineStep("Drying", _isStepDone(order.status, 3)),
                  _timelineDivider(_isStepDone(order.status, 4)),
                  _timelineStep("Folding", _isStepDone(order.status, 4)),
                  _timelineDivider(_isStepDone(order.status, 5)),
                  _timelineStep("Ready", _isStepDone(order.status, 5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TrackingFeedbackScreen(orderId: order.id)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("VIEW TRACKING & STUB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
          ] else ...[
            Text(statusSubtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderFormScreen())),
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text("PLACE AN ORDER NOW"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getCardStyle(bool hasOrder, double progress) {
    if (hasOrder) {
      return {
        'color': AppColors.primary,
        'icon': Icons.local_laundry_service_rounded,
        'percent': "${(progress * 100).toInt()}%",
      };
    } else {
      return {
        'color': Colors.grey.shade300,
        'icon': Icons.shopping_basket_outlined,
        'percent': "0%",
      };
    }
  }

  double _getProgressForStatus(String status) {
    switch (status) {
      case 'Washing':
      case 'In Process':
        return 0.40;
      case 'Drying':
        return 0.65;
      case 'Folding':
        return 0.85;
      case 'Ready':
      case 'Ready for Pickup':
        return 1.0;
      default:
        return 0.20;
    }
  }

  String _getSubtitleForStatus(String status) {
    switch (status) {
      case 'Ready':
      case 'Ready for Pickup':
        return "Your laundry is ready for pickup!";
      default:
        return "Estimated time: 30 - 45 Mins";
    }
  }

  bool _isStepDone(String currentStatus, int step) {
    int currentStep = 1;
    switch (currentStatus) {
      case 'Washing':
      case 'In Process':
        currentStep = 2;
        break;
      case 'Drying':
        currentStep = 3;
        break;
      case 'Folding':
        currentStep = 4;
        break;
      case 'Ready':
      case 'Ready for Pickup':
      case 'Claimed':
        currentStep = 5;
        break;
      default:
        currentStep = 1;
    }
    return currentStep >= step;
  }

  Widget _timelineStep(String label, bool isCompleted) {
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: isCompleted ? AppColors.primary : Colors.grey.shade300,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isCompleted ? AppColors.primary : Colors.grey)),
      ],
    );
  }

  Widget _timelineDivider(bool isCompleted) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: isCompleted ? AppColors.primary : Colors.grey.shade200,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const Text("View All", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPromoCarousel() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _promoCard("20% OFF", "On your first laundry order", AppColors.primary),
          _promoCard("FREE DRY", "Available every weekend", AppColors.primary),
        ],
      ),
    );
  }

  Widget _promoCard(String title, String sub, Color color) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text("USE CODE: LAUNDRI20", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          )
        ],
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context, AppState state) {
    final int stamps = (state.customerLoyaltyPoints > 10 ? 10 : state.customerLoyaltyPoints);
    final bool complete = state.hasFreeLaundry;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/rewards_redemption'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Loyalty Stamps", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    "$stamps/10",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StampGrid(stamps: stamps, size: 28),
            const SizedBox(height: 12),
            Text(
              complete ? "10/10 complete! Your next laundry is FREE." : "${10 - stamps} more claimed order${10 - stamps == 1 ? '' : 's'} for a FREE laundry!",
              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            if (complete) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderFormScreen(isFreeLaundry: true)),
                  ),
                  icon: const Icon(Icons.redeem_rounded, size: 18),
                  label: const Text("CLAIM FREE LAUNDRY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAdminChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Chat Admin / Owner", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text("G A Laundry Shop Owner • Online", style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 25),
            Expanded(
              child: ListView(
                children: [
                  _chatBubble("Magandang araw! Ako ang owner ng G A Laundry Shop. May maipaglilingkod ba ako sa laundry o order mo?", false),
                  _chatBubble("Hi Admin! Pwede po magtanong tungkol sa special fabric care request?", true),
                  _chatBubble("Oo naman! Pwede mong ilagay sa order notes o sabihin dito sa akin para maipagbilin ko agad sa washing staff.", false),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Message Admin / Owner...",
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Message sent directly to Shop Admin / Owner!")),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13)),
      ),
    );
  }
}

// --- ORDER FORM SCREEN ---
class OrderFormScreen extends StatefulWidget {
  /// True when the customer is claiming the free laundry from a 10/10 loyalty card.
  final bool isFreeLaundry;
  const OrderFormScreen({super.key, this.isFreeLaundry = false});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Multi-select: the customer can pick several laundry categories in one order.
  final Set<String> _selectedCategories = {"Regular Clothes"};

  // Maps each category title to its rate key in AppState.packageRates.
  static const Map<String, String> _categoryKeys = {
    "Regular Clothes": 'regular',
    "Whites (Max 7kg)": 'whites',
    "Baby Clothes (Max 7kg)": 'baby',
    "Beddings / Curtains": 'bedding',
    "Single Size Comforter": 'single',
    "Double Size Comforter": 'double',
    "Denim, Cargo, Jackets": 'denim',
  };

  String _rateText(String key) {
    final v = AppStateProvider.of(context).rateOf(key);
    return "₱${_formatRate(v)}";
  }

  String get _categoriesLabel => _selectedCategories.join(", ");
  bool _isFullService = true;
  bool _washOnly = false;
  bool _dryOnly = false;
  bool _foldOnly = false;
  bool _extraWash = false;

  bool _extraDetergent = false;
  bool _extraFabcon = false;

  String _paymentMethod = "Cash";

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Maria Santos');
    _phoneController = TextEditingController(text: '0928-188-6235');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String get _totalText => widget.isFreeLaundry ? "Free Laundry" : "₱${_calculateTotal.toStringAsFixed(2)}";

  double get _calculateTotal {
    if (widget.isFreeLaundry) return 0.0; // loyalty reward: no price
    // Full Package adds up the price of every selected category.
    final rates = AppStateProvider.of(context);
    double total = 0.0;

    if (_isFullService) {
      for (final c in _selectedCategories) {
        total += rates.rateOf(_categoryKeys[c] ?? 'regular');
      }
    } else {
      double perLoad = 0.0;
      if (_washOnly) perLoad += rates.rateOf('wash');
      if (_dryOnly) perLoad += rates.rateOf('dry');
      if (_foldOnly) perLoad += rates.rateOf('fold');
      total = perLoad; // charged once per order, not per category
    }

    // Add-ons are charged once per order (not per category).
    if (_extraWash) total += rates.rateOf('extraWash');
    if (_extraDetergent) total += rates.rateOf('extraDetergent');
    if (_extraFabcon) total += rates.rateOf('extraFabcon');

    return total;
  }

  bool get _hasService => _isFullService || _washOnly || _dryOnly || _foldOnly;

  String get _serviceLabel {
    if (_isFullService) return "Wash|Dry|Fold";
    final parts = <String>[
      if (_washOnly) "Wash",
      if (_dryOnly) "Dry",
      if (_foldOnly) "Fold",
    ];
    return parts.isEmpty ? "None" : "${parts.join(" + ")} Only";
  }

  void _nextPage() {
    if (_currentPage == 0 && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one laundry category.")),
      );
      return;
    }
    if (_currentPage == 1 && (!_hasService || (!widget.isFreeLaundry && _calculateTotal <= 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a service and options before continuing."),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _showConfirmationDialog();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Book a Pickup / Place Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: _prevPage,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Step ${_currentPage + 1} of 3",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
            ),
          )
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 640,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCategoryPage(),
                  _buildServiceAddonsPage(),
                  _buildSummaryPaymentPage(),
                ],
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 6,
      width: double.infinity,
      color: AppColors.border,
      child: Row(
        children: [
          Expanded(
            flex: _currentPage + 1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
            ),
          ),
          Expanded(flex: 3 - (_currentPage + 1), child: const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Total Estimate", style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              Text(
                _totalText,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
          BouncingWidget(
            onTap: _nextPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    _currentPage == 2 ? "CONFIRM ORDER" : "CONTINUE",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Laundry Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(widget.isFreeLaundry ? "Free Laundry reward: choose 1 category." : "You can choose more than one. Each category is washed as its own load.", style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          if (widget.isFreeLaundry) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.redeem_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Loyalty reward: this order is Free Laundry. Your card resets to 0/10 after you place it.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _categoryCard("Regular Clothes", "Full Package (Max 8kg) - Wash, Dry & Fold", _rateText('regular'), Icons.checkroom_rounded, AppColors.primarySoft, AppColors.primary),
          _categoryCard("Whites (Max 7kg)", "Special care for white garments", _rateText('whites'), Icons.color_lens_outlined, AppColors.primarySoft, AppColors.primary),
          _categoryCard("Baby Clothes (Max 7kg)", "Includes free gentle baby detergent", _rateText('baby'), Icons.child_care_rounded, const Color(0xFFFFF1F2), const Color(0xFFE11D48)),
          _categoryCard("Beddings / Curtains", "Bedsheets, Blankets, Towels (Max 8kg)", _rateText('bedding'), Icons.bed_rounded, const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
          _categoryCard("Single Size Comforter", "1 to 2 pcs per load", _rateText('single'), Icons.hotel_rounded, const Color(0xFFECFDF5), AppColors.success),
          _categoryCard("Double Size Comforter", "1 pc per load", _rateText('double'), Icons.king_bed_rounded, const Color(0xFFF3E8FF), const Color(0xFF9333EA)),
          _categoryCard("Denim, Cargo, Jackets", "Heavy pants, Shorts, Sweaters (Max 6kg)", _rateText('denim'), Icons.layers_rounded, AppColors.background, const Color(0xFF475569)),
        ],
      ),
    );
  }

  Widget _categoryCard(String title, String subtitle, String price, IconData icon, Color bgTint, Color themeColor) {
    bool isSelected = _selectedCategories.contains(title);
    return BouncingWidget(
      onTap: () => setState(() {
        if (widget.isFreeLaundry) {
          // Free laundry covers one load: only one category at a time.
          _selectedCategories
            ..clear()
            ..add(title);
          return;
        }
        if (!_selectedCategories.remove(title)) {
          _selectedCategories.add(title);
        }
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? bgTint : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? themeColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? themeColor : Colors.black).withValues(alpha: isSelected ? 0.08 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: themeColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                price,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: themeColor),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isSelected ? themeColor : const Color(0xFFCBD5E1),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceAddonsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Services & Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text("Customize your laundry wash, drying, and extra care add-ons.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          _sectionTitle("MAIN SERVICE PACKAGE"),
          _serviceOption("Full Package (Wash | Dry | Fold)", "Complete package with free Detergent & FabCon", _isFullService, (val) {
            setState(() { _isFullService = val!; if (val) { _washOnly = false; _dryOnly = false; _foldOnly = false; } });
          }, Icons.verified_rounded, AppColors.primary),

          if (!_isFullService) ...[
            const SizedBox(height: 8),
            _serviceOption("Wash Only (${_rateText('wash')})", "Individual machine wash cycle per load", _washOnly, (val) {
              setState(() { _washOnly = val!; });
            }, Icons.water_drop_rounded, AppColors.primary),
            _serviceOption("Dry Only (${_rateText('dry')})", "Individual heat commercial drying per load", _dryOnly, (val) {
              setState(() { _dryOnly = val!; });
            }, Icons.wb_sunny_rounded, AppColors.warning),
            _serviceOption("Fold Only (${_rateText('fold')})", "Neatly folded and packed per load", _foldOnly, (val) {
              setState(() { _foldOnly = val!; });
            }, Icons.inventory_2_rounded, AppColors.success),
          ],

          if (!_hasService) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Please select a service and options to continue.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!widget.isFreeLaundry) ...[
            const SizedBox(height: 24),
            _sectionTitle("WASH & CARE ADD-ONS"),
            _addonTile("Extra Wash Cycle (+${_rateText('extraWash')})", "An additional 15-min wash cycle", _extraWash, (v) => setState(() => _extraWash = v!), Icons.sync_rounded),
            _addonTile("Extra Detergent (+${_rateText('extraDetergent')})", "Extra Ariel Commercial Liquid Detergent", _extraDetergent, (v) => setState(() => _extraDetergent = v!), Icons.sanitizer_rounded),
            _addonTile("Extra Fabcon (+${_rateText('extraFabcon')})", "Extra Downy Floral Softener scent", _extraFabcon, (v) => setState(() => _extraFabcon = v!), Icons.local_florist_rounded),
          ],

          const SizedBox(height: 24),
          _sectionTitle("CUSTOMER CONTACT DETAILS"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Customer Full Name",
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  keyboardType: TextInputType.streetAddress,
                  decoration: const InputDecoration(
                    labelText: "Location / Address",
                    hintText: "Street, Barangay, Town",
                    prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                ),
                if (AppStateProvider.of(context).savedAddresses.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: AppStateProvider.of(context).savedAddresses.map((a) {
                        return ActionChip(
                          avatar: const Icon(Icons.bookmark_outline_rounded, size: 16, color: AppColors.primary),
                          label: Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => setState(() => _locationController.text = a.address),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
      ),
    );
  }

  Widget _serviceOption(String title, String sub, bool value, Function(bool?) onChanged, IconData icon, Color color) {
    return BouncingWidget(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? color : AppColors.border, width: value ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? color : AppColors.textMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: value ? color : AppColors.ink)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _addonTile(String label, String subtitle, bool value, Function(bool?) onChanged, IconData icon) {
    return BouncingWidget(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: value ? AppColors.primary : AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPaymentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Summary & Payment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text("Please review your order details before confirming.", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("LAUNDRY RECEIPT STUB", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                      child: const Text("NEW ORDER", style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _summaryRow("Customer Name", _nameController.text),
                _summaryRow("Phone Number", _phoneController.text),
                if (_locationController.text.trim().isNotEmpty)
                  _summaryRow("Location", _locationController.text.trim()),
                _summaryRow("Selected Categories", _categoriesLabel),
                _summaryRow("Main Service", _isFullService ? "Full Package (Wash/Dry/Fold)" : _serviceLabel),
                if (_extraWash || _extraDetergent || _extraFabcon)
                  _summaryRow(
                    "Add-ons",
                    [
                      if (_extraWash) "Extra Wash",
                      if (_extraDetergent) "Extra Detergent",
                      if (_extraFabcon) "Extra Fabcon",
                    ].join(", "),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL AMOUNT DUE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    Text(_totalText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),

          if (widget.isFreeLaundry)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.redeem_rounded, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Paid with Loyalty Reward: no payment needed for this order.",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 24),
            const Text("Select Payment Method", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 12),
            _paymentTile("Cash on Pickup / Drop-off", "Cash", Icons.payments_rounded, AppColors.success),
            _paymentTile("GCash E-Wallet Express", "GCash", Icons.account_balance_wallet_rounded, AppColors.primary),
            _paymentTile("PayMaya Wallet", "PayMaya", Icons.wallet_rounded, const Color(0xFF9333EA)),
            if (_paymentMethod != 'Cash') _buildQrPayCard(),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.ink),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPayCard() {
    final qr = AppStateProvider.of(context).qrFor(_paymentMethod);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text("Scan to pay with $_paymentMethod", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.ink)),
          const SizedBox(height: 12),
          if (qr != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(qr, height: 220, fit: BoxFit.contain),
            )
          else
            Text(
              "The shop has not uploaded a $_paymentMethod QR code yet. Please choose Cash or pay at the shop.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _paymentTile(String title, String method, IconData icon, Color iconColor) {
    bool isSelected = _paymentMethod == method;
    return BouncingWidget(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? iconColor : AppColors.border, width: isSelected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14, color: AppColors.ink)),
            const Spacer(),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: iconColor)
            else
              const Icon(Icons.radio_button_off, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink)),
        content: const Text("Are you sure all details are correct? By confirming, you agree to our terms and conditions."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processOrder();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("AGREE & PLACE ORDER"),
          ),
        ],
      ),
    );
  }

  void _processOrder() {
    final laundryState = AppStateProvider.of(context);
    if (widget.isFreeLaundry && !laundryState.hasFreeLaundry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need 10/10 loyalty stamps to claim a free laundry.")),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);

        List<String> addons = [];
        if (_extraWash) addons.add("Extra Wash");
        if (_extraDetergent) addons.add("Extra Detergent");
        if (_extraFabcon) addons.add("Extra Fabcon");

        // FIFO: position in line = unclaimed 'Received' orders ahead + 1
        final int queuePosition = laundryState.orders.where((o) => o.status == 'Received').length + 1;

        final newOrder = Order(
          id: "Q-${100 + laundryState.customerOrders.length + 1}",
          customerName: _nameController.text,
          phone: _phoneController.text,
          category: _categoriesLabel,
          service: _serviceLabel,
          total: _calculateTotal,
          paymentMethod: widget.isFreeLaundry ? 'Loyalty Reward' : _paymentMethod,
          addons: addons,
          timestamp: DateTime.now(),
        );

        laundryState.addOrder(newOrder);
        if (widget.isFreeLaundry) laundryState.redeemFreeLaundry(); // card goes back to 0/10

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DigitalReceiptScreen(
              orderData: {
                'id': newOrder.id,
                'name': newOrder.customerName,
                'category': newOrder.category,
                'service': newOrder.service,
                'location': _locationController.text.trim(),
                'queuePosition': queuePosition,
                'total': newOrder.total,
                'paymentMethod': newOrder.paymentMethod,
                'addons': newOrder.addons,
              },
            ),
          ),
        );
      }
    });
  }
}

// --- TRACKING & FEEDBACK SCREEN ---
class TrackingFeedbackScreen extends StatefulWidget {
  final String? orderId;
  const TrackingFeedbackScreen({super.key, this.orderId});

  @override
  State<TrackingFeedbackScreen> createState() => _TrackingFeedbackScreenState();
}

class _TrackingFeedbackScreenState extends State<TrackingFeedbackScreen> {
  int rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool isSubmittingFeedback = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Order? _getCurrentOrder(AppState state) {
    if (widget.orderId != null) {
      try {
        return state.customerOrders.firstWhere((o) => o.id == widget.orderId);
      } catch (_) {}
    }
    return state.activeOrder ?? (state.customerOrders.isNotEmpty ? state.customerOrders.first : null);
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final order = _getCurrentOrder(state);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Order Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: order == null
          ? const Center(
        child: Text(
          "No active order found.\nPlace an order to start tracking!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(brandColor, order),
            const SizedBox(height: 25),
            _buildDigitalClaimStub(brandColor, order),
            const SizedBox(height: 30),
            _buildSectionHeader("Order Live Progress"),
            const SizedBox(height: 15),
            _buildTrackingStepper(brandColor, order),
            const SizedBox(height: 30),
            _buildSectionHeader("Order Information"),
            const SizedBox(height: 15),
            _buildOrderInfoCard(brandColor, order),
            const SizedBox(height: 30),
            _buildSectionHeader("Service Feedback"),
            const SizedBox(height: 15),
            _buildFeedbackSection(brandColor, order),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildStatusHeader(Color brandColor, Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.status, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text("Estimated Completion: 30 - 45 Mins", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDigitalClaimStub(Color brandColor, Order order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 15)],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text("DIGITAL CLAIM STUB", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(order.id, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(30, (i) => Container(
              width: i % 4 == 0 ? 2 : 3,
              height: 35,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              color: Colors.black87,
            )),
          ),
          const SizedBox(height: 10),
          const Text("PRESENT THIS UPON PICKUP / CLAIMING", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(Color brandColor, Order order) {
    int currentStep = 1;
    if (order.status == 'Washing' || order.status == 'In Process') currentStep = 2;
    if (order.status == 'Drying') currentStep = 3;
    if (order.status == 'Folding') currentStep = 4;
    if (order.status == 'Ready' || order.status == 'Ready for Pickup' || order.status == 'Claimed') currentStep = 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _stepperItem("Order Received", "Order accepted by laundry shop", currentStep >= 1, true, brandColor, isActive: currentStep == 1),
          _stepperItem("Washing", "Machine wash cycle running", currentStep >= 2, true, brandColor, isActive: currentStep == 2),
          _stepperItem("Drying", "Heat drying in progress", currentStep >= 3, true, brandColor, isActive: currentStep == 3),
          _stepperItem("Folding", "Neatly folded and packed", currentStep >= 4, true, brandColor, isActive: currentStep == 4),
          _stepperItem("Ready for Pickup", "Available for customer claiming", currentStep >= 5, false, brandColor, isActive: currentStep == 5),
        ],
      ),
    );
  }

  Widget _stepperItem(String title, String subtitle, bool isCompleted, bool showLine, Color brandColor, {bool isActive = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? AppColors.primary : Colors.grey.shade300, width: 2),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            if (showLine) Container(width: 2, height: 40, color: isCompleted ? AppColors.primary : Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isActive ? AppColors.primary : (isCompleted ? brandColor : Colors.grey))),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOrderInfoCard(Color brandColor, Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: brandColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _infoRow("Category", order.category),
          _infoRow("Service", order.service),
          if (order.addons.isNotEmpty)
            _infoRow("Add-ons", order.addons.join(", ")),
          _infoRow("Payment Method", "${order.paymentMethod} (Confirmed)"),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL AMOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(_orderPrice(order.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(Color brandColor, Order order) {
    final feedbackState = AppStateProvider.of(context);
    final sent = feedbackState.feedbackFor(order.id);
    if (sent != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 10),
                Text("Thank you for your feedback!", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                    (i) => Icon(i < sent.rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 22),
              ),
            ),
            if (sent.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(sent.comment, style: const TextStyle(fontSize: 13, color: AppColors.ink)),
            ],
            if (sent.adminReply.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text("Shop reply: ${sent.adminReply}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How was our service for this order?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(
                  index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentController,
            maxLines: 2,
            maxLength: AppState.maxFeedbackLength,
            decoration: InputDecoration(
              hintText: "Leave comments or suggestions for the laundry staff...",
              hintStyle: const TextStyle(fontSize: 12),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmittingFeedback
                  ? null
                  : () async {
                if (rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please tap a star rating first!")));
                  return;
                }

                setState(() => isSubmittingFeedback = true);
                await Future.delayed(const Duration(milliseconds: 500));
                if (!mounted) return;
                final String? error = AppStateProvider.of(context).submitFeedback(
                  orderId: order.id,
                  customerName: order.customerName,
                  rating: rating,
                  comment: _commentController.text,
                );
                setState(() => isSubmittingFeedback = false);

                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  return;
                }
                _commentController.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feedback submitted successfully! Thank you.")));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: isSubmittingFeedback
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SUBMIT FEEDBACK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          )
        ],
      ),
    );
  }
}

// --- DIGITAL RECEIPT SCREEN ---
class DigitalReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const DigitalReceiptScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Digital Receipt", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.check_circle, color: AppColors.success, size: 60),
                  const SizedBox(height: 15),
                  const Text("Payment Successful", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Thank you for your order!", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  const Divider(indent: 20, endIndent: 20),
                  _buildReceiptRow("Order ID", orderData['id'] ?? "#ORD-101"),
                  _buildReceiptRow("Date", "${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}"),
                  _buildReceiptRow("Customer", orderData['name'] ?? "Guest"),
                  if (orderData['queuePosition'] != null)
                    _buildReceiptRow("Queue Position", "#${orderData['queuePosition']} (first in, first out)"),
                  if ((orderData['location'] ?? '').toString().isNotEmpty)
                    _buildReceiptRow("Location", orderData['location'].toString()),
                  const Divider(indent: 20, endIndent: 20),
                  _buildReceiptRow("Category", orderData['category'] ?? "Regular Clothes"),
                  _buildReceiptRow("Service", orderData['service'] ?? "Wash|Dry|Fold"),
                  if (orderData['addons'] != null && (orderData['addons'] as List).isNotEmpty)
                    _buildReceiptRow("Add-ons", (orderData['addons'] as List).join(", ")),
                  const Divider(indent: 20, endIndent: 20),
                  _buildReceiptRow("Total Paid", _orderPrice(orderData['total'] as double), isBold: true),
                  _buildReceiptRow("Payment Method", orderData['paymentMethod'] ?? "Cash", isBold: true),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(35, (i) => Container(
                        width: i % 4 == 0 ? 2 : 3,
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        color: Colors.black87,
                      )),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("SCAN FOR PICKUP", style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final d = orderData;
                  final List addons = (d['addons'] as List?) ?? [];
                  try {
                    await shareReceiptPdf(
                      orderId: (d['id'] ?? '').toString(),
                      customerName: (d['name'] ?? 'Guest').toString(),
                      details: [
                        MapEntry('Category', (d['category'] ?? '').toString()),
                        MapEntry('Service', (d['service'] ?? '').toString()),
                        if ((d['location'] ?? '').toString().isNotEmpty)
                          MapEntry('Location', d['location'].toString()),
                        if (d['queuePosition'] != null)
                          MapEntry('Queue Position', '#${d['queuePosition']} (first in, first out)'),
                        if (addons.isNotEmpty) MapEntry('Add-ons', addons.join(', ')),
                      ],
                      total: ((d['total'] ?? 0) as num).toDouble(),
                      paymentMethod: (d['paymentMethod'] ?? 'Cash').toString(),
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Could not create the receipt. Please try again.")),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text("DOWNLOAD RECEIPT"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("RETURN TO DASHBOARD", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isBold ? AppColors.primary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HISTORY SCREEN ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final orders = state.customerOrders;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: brandColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: "Order History"),
                  Tab(text: "Payment History"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrderList(context, orders, brandColor),
                  _buildPaymentList(context, orders, brandColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> data, Color brandColor) {
    if (data.isEmpty) return _buildEmptyState("No laundry orders found.", Icons.local_laundry_service_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final order = data[index];
        return _buildHistoryCard(context, order, brandColor, isOrder: true);
      },
    );
  }

  Widget _buildPaymentList(BuildContext context, List<Order> allOrders, Color brandColor) {
    // Cash is only recorded once claimed; GCash/PayMaya are recorded right away.
    final data = allOrders.where((o) => o.paymentMethod != 'Cash' || o.status == 'Claimed').toList();
    if (data.isEmpty) return _buildEmptyState("No payment records found.", Icons.receipt_long_rounded);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final order = data[index];
        return _buildHistoryCard(context, order, brandColor, isOrder: false);
      },
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 15),
          Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Order order, Color brandColor, {required bool isOrder}) {
    final bool isClaimed = order.status == 'Claimed';
    // Orders tab: green when ready/claimed. Payments tab: green only once claimed, amber while in process.
    bool isCompleted = isOrder ? (isClaimed || order.status == 'Ready' || order.status == 'Ready for Pickup') : isClaimed;
    String displayId = isOrder ? order.id : "PAY-${order.id.replaceAll('Q-', '')}";
    String dateStr = "${_getMonth(order.timestamp.month)} ${order.timestamp.day}, ${order.timestamp.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: brandColor.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () => _showDetailsDialog(context, order, isOrder),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOrder ? Icons.local_laundry_service_rounded : Icons.payment_rounded,
                  color: isCompleted ? AppColors.primary : AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                    const SizedBox(height: 3),
                    Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_orderPrice(order.total), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOrder ? order.status : (isClaimed ? "Paid" : "In Process"),
                      style: TextStyle(
                        color: isCompleted ? AppColors.success : AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Order order, bool isOrder) {
    String dateStr = "${_getMonth(order.timestamp.month)} ${order.timestamp.day}, ${order.timestamp.year}";
    String displayId = isOrder ? order.id : "PAY-${order.id.replaceAll('Q-', '')}";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 25),
            Text(isOrder ? "Order Information" : "Payment Receipt", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            Text(
              isOrder ? "Complete record of your laundry service." : "Verified transaction paid via ${order.paymentMethod}.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 25),
            _detailRow(isOrder ? "Order Reference ID" : "Transaction ID", displayId),
            if (!isOrder) _detailRow("Related Order ID", order.id),
            _detailRow("Date Placed", dateStr),
            _detailRow("Category", order.category),
            _detailRow("Service Type", order.service),
            _detailRow("Payment Method", order.paymentMethod),
            if (order.addons.isNotEmpty) _detailRow("Selected Add-ons", order.addons.join(", ")),
            const Spacer(),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL AMOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                Text(_orderPrice(order.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
        ],
      ),
    );
  }

  String _getMonth(int m) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[m - 1];
  }
}

// --- NOTIFICATIONS SCREEN ---
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final bool isAdmin = state.currentRole == UserRole.admin;
    final notifications = isAdmin ? state.notifications : state.customerNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAdmin ? "Admin Notifications" : "Notifications",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                state.markAllNotificationsAsRead(state.currentRole);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All notifications marked as read.")),
                );
              },
              child: const Text(
                "Read All",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 30),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final bool isAdminRequest = notif.type == 'admin_request';

          return InkWell(
            onTap: () => _handleNotifTap(context, state, notif),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(notif.type), color: brandColor, size: 24),
                        ),
                        if (!notif.isRead)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 15,
                                    color: brandColor,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(notif.timestamp),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notif.message,
                            style: TextStyle(
                              color: notif.isRead ? Colors.grey.shade600 : Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAdmin && isAdminRequest) ...[
                  const SizedBox(height: 12),
                  if (notif.adminRequestStatus == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              state.approveAdminRequest(notif.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("APPROVED admin account request for ${notif.applicantName ?? 'User'}!")),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                            label: const Text("ACCEPT & APPROVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              state.declineAdminRequest(notif.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("DECLINED admin account request for ${notif.applicantName ?? 'User'}.")),
                              );
                            },
                            icon: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.danger),
                            label: const Text("DECLINE", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ] else if (notif.adminRequestStatus == 'approved') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Text("ACCEPTED & APPROVED ✅", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    )
                  ] else if (notif.adminRequestStatus == 'declined') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cancel, color: AppColors.danger, size: 16),
                          const SizedBox(width: 6),
                          Text("DECLINED ❌", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    )
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("No notifications yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_update': return Icons.local_laundry_service_rounded;
      case 'order_alert': return Icons.shopping_basket_rounded;
      case 'admin_request': return Icons.admin_panel_settings_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${time.month}/${time.day}";
  }

  void _handleNotifTap(BuildContext context, AppState state, AppNotification notif) {
    state.markNotificationAsRead(notif.id);

    if (notif.relatedOrderId != null) {
      try {
        final order = state.customerOrders.firstWhere((o) => o.id == notif.relatedOrderId);
        _showOrderInfo(context, order);
      } catch (e) {
        _showGeneralNotif(context, notif);
      }
    } else {
      _showGeneralNotif(context, notif);
    }
  }

  void _showGeneralNotif(BuildContext context, AppNotification notif) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(notif.type), color: AppColors.primary),
                const SizedBox(width: 10),
                Text(notif.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Text(notif.message, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showOrderInfo(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 25),
            _infoRow("Queue No", order.id),
            _infoRow("Customer", order.customerName),
            _infoRow("Service", order.service),
            _infoRow("Status", order.status),
            _infoRow("Payment Method", order.paymentMethod),
            _infoRow("Add-ons", order.addons.isEmpty ? "None" : order.addons.join(", ")),
            const Spacer(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL AMOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₱${order.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final bool isAdmin = state.currentRole == UserRole.admin;
    final notifications = isAdmin ? state.notifications : state.customerNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAdmin ? "Admin Notifications" : "Notifications",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                state.markAllNotificationsAsRead(state.currentRole);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All notifications marked as read.")),
                );
              },
              child: const Text(
                "Read All",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 30),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final bool isAdminRequest = notif.type == 'admin_request';

          return InkWell(
            onTap: () => _handleNotifTap(context, state, notif),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: brandColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIcon(notif.type), color: brandColor, size: 24),
                        ),
                        if (!notif.isRead)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 15,
                                    color: brandColor,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(notif.timestamp),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notif.message,
                            style: TextStyle(
                              color: notif.isRead ? Colors.grey.shade600 : Colors.black87,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAdmin && isAdminRequest) ...[
                  const SizedBox(height: 12),
                  if (notif.adminRequestStatus == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              state.approveAdminRequest(notif.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("APPROVED admin account request for ${notif.applicantName ?? 'User'}!")),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                            label: const Text("ACCEPT & APPROVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              state.declineAdminRequest(notif.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("DECLINED admin account request for ${notif.applicantName ?? 'User'}.")),
                              );
                            },
                            icon: const Icon(Icons.cancel_rounded, size: 16, color: AppColors.danger),
                            label: const Text("DECLINE", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ] else if (notif.adminRequestStatus == 'approved') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Text("ACCEPTED & APPROVED ✅", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    )
                  ] else if (notif.adminRequestStatus == 'declined') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cancel, color: AppColors.danger, size: 16),
                          const SizedBox(width: 6),
                          Text("DECLINED ❌", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    )
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("No notifications yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_update': return Icons.local_laundry_service_rounded;
      case 'order_alert': return Icons.shopping_basket_rounded;
      case 'admin_request': return Icons.admin_panel_settings_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${time.month}/${time.day}";
  }

  void _handleNotifTap(BuildContext context, AppState state, AppNotification notif) {
    state.markNotificationAsRead(notif.id);

    if (notif.relatedOrderId != null) {
      try {
        final order = state.customerOrders.firstWhere((o) => o.id == notif.relatedOrderId);
        _showOrderInfo(context, order);
      } catch (e) {
        _showGeneralNotif(context, notif);
      }
    } else {
      _showGeneralNotif(context, notif);
    }
  }

  void _showGeneralNotif(BuildContext context, AppNotification notif) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIcon(notif.type), color: AppColors.primary),
                const SizedBox(width: 10),
                Text(notif.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Text(notif.message, style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showOrderInfo(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 25),
            _infoRow("Queue No", order.id),
            _infoRow("Customer", order.customerName),
            _infoRow("Service", order.service),
            _infoRow("Status", order.status),
            _infoRow("Payment Method", order.paymentMethod),
            _infoRow("Add-ons", order.addons.isEmpty ? "None" : order.addons.join(", ")),
            const Spacer(),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL AMOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("₱${order.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- PROFILE SCREEN ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    const accentColor = AppColors.accent;
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          state.currentRole == UserRole.admin ? "Admin Profile" : "Profile",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 3),
                        ),
                        child: const CircleAvatar(
                          radius: 42,
                          backgroundColor: brandColor,
                          child: Icon(Icons.person, size: 45, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(state.currentFullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandColor)),
                  const SizedBox(height: 4),
                  Text(state.currentEmail, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("${state.customerLoyaltyPoints}/10 LOYALTY STAMPS", style: const TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionCard(
              title: "Account Settings",
              brandColor: brandColor,
              options: [
                _buildProfileOption(context, Icons.person_outline_rounded, "Account Details", onTap: () => Navigator.pushNamed(context, '/account_details')),
                _buildProfileOption(context, Icons.location_on_outlined, "Saved Addresses", onTap: () => Navigator.pushNamed(context, '/saved_addresses')),
                _buildProfileOption(context, Icons.payment_outlined, "Payment Methods", onTap: () => Navigator.pushNamed(context, '/payment_methods')),
                _buildProfileOption(context, Icons.notifications_none_rounded, "Notification Settings", onTap: () => Navigator.pushNamed(context, '/notification_settings')),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Support & Information",
              brandColor: brandColor,
              options: [
                _buildProfileOption(context, Icons.help_outline_rounded, "Help & FAQ"),
                _buildProfileOption(context, Icons.info_outline_rounded, "About G A Laundry"),
                _buildProfileOption(
                  context,
                  Icons.logout_rounded,
                  "Logout",
                  textColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () => _showLogoutDialog(context, state),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Color brandColor, required List<Widget> options}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
            ),
            ...options,
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out of G A Laundry Shop?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              state.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, {Color? textColor, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor ?? AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Opening $title..."),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    const accentColor = AppColors.accent;
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          state.currentRole == UserRole.admin ? "Admin Profile" : "Profile",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentColor, width: 3),
                        ),
                        child: const CircleAvatar(
                          radius: 42,
                          backgroundColor: brandColor,
                          child: Icon(Icons.person, size: 45, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(state.currentFullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: brandColor)),
                  const SizedBox(height: 4),
                  Text(state.currentEmail, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("${state.customerLoyaltyPoints}/10 LOYALTY STAMPS", style: const TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            _buildSectionCard(
              title: "Account Settings",
              brandColor: brandColor,
              options: [
                _buildProfileOption(context, Icons.person_outline_rounded, "Account Details", onTap: () => Navigator.pushNamed(context, '/account_details')),
                _buildProfileOption(context, Icons.location_on_outlined, "Saved Addresses", onTap: () => Navigator.pushNamed(context, '/saved_addresses')),
                _buildProfileOption(context, Icons.payment_outlined, "Payment Methods", onTap: () => Navigator.pushNamed(context, '/payment_methods')),
                _buildProfileOption(context, Icons.notifications_none_rounded, "Notification Settings", onTap: () => Navigator.pushNamed(context, '/notification_settings')),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionCard(
              title: "Support & Information",
              brandColor: brandColor,
              options: [
                _buildProfileOption(context, Icons.help_outline_rounded, "Help & FAQ"),
                _buildProfileOption(context, Icons.info_outline_rounded, "About G A Laundry"),
                _buildProfileOption(
                  context,
                  Icons.logout_rounded,
                  "Logout",
                  textColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () => _showLogoutDialog(context, state),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Color brandColor, required List<Widget> options}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
            ),
            ...options,
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out of G A Laundry Shop?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              state.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, {Color? textColor, Color? iconColor, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: textColor ?? AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Opening $title..."),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }
}

// --- ACCOUNT DETAILS SCREEN ---
class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Account Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildInfoTile("Customer Account ID", state.currentCustomerId ?? "CUST-VERIFIED-REG"),
                  _buildInfoTile("Full Name", state.currentFullName),
                  _buildInfoTile("Phone Number", state.currentPhone),
                  _buildInfoTile("Email Address", state.currentEmail),
                  _buildInfoTile("Home Address", state.currentAddress),
                  _buildInfoTile("Username", state.currentUsername),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile edit request saved.")));
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("EDIT PROFILE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}


// --- LOYALTY STAMPS ---
String _formatRate(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _orderPrice(double total) => total == 0 ? "Free Laundry" : "₱${total.toStringAsFixed(2)}";

class StampGrid extends StatelessWidget {
  final int stamps;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Color iconColor;

  const StampGrid({
    super.key,
    required this.stamps,
    this.size = 34,
    this.filledColor = AppColors.pink,
    this.emptyColor = const Color(0x33FFFFFF),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: List.generate(10, (i) {
        final bool filled = i < stamps;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? filledColor : emptyColor,
            border: Border.all(color: filled ? filledColor : iconColor.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Center(
            child: filled
                ? Icon(Icons.local_laundry_service_rounded, color: iconColor, size: size * 0.55)
                : Text("${i + 1}", style: TextStyle(color: iconColor.withValues(alpha: 0.6), fontSize: size * 0.34, fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }
}

// --- LOYALTY REWARDS SCREEN ---
class RewardsRedemptionScreen extends StatelessWidget {
  const RewardsRedemptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primary;
    final state = AppStateProvider.of(context);
    final int stamps = (state.customerLoyaltyPoints > 10 ? 10 : state.customerLoyaltyPoints);
    final bool complete = state.hasFreeLaundry;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Loyalty Rewards", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Text("Your Loyalty Card", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text("$stamps/10", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 18),
                  StampGrid(stamps: stamps, size: 44),
                  const SizedBox(height: 18),
                  Text(
                    complete ? "10/10 complete! Your next laundry is FREE." : "${10 - stamps} more claimed order${10 - stamps == 1 ? '' : 's'} for a FREE laundry!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: complete
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderFormScreen(isFreeLaundry: true)),
                )
                    : null,
                icon: Icon(complete ? Icons.redeem_rounded : Icons.lock_outline_rounded),
                label: Text(
                  complete ? "CLAIM FREE LAUNDRY" : "COMPLETE 10 STAMPS TO CLAIM",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("How it works", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            _howItWorksTile(Icons.local_laundry_service_rounded, "Get 1 stamp for every order you claim."),
            _howItWorksTile(Icons.stars_rounded, "Collect 10 stamps (10/10) to unlock 1 free laundry."),
            _howItWorksTile(Icons.redeem_rounded, "Tap \"Claim Free Laundry\" to place your free order."),
            _howItWorksTile(Icons.restart_alt_rounded, "After you place it, your card goes back to 0/10."),
          ],
        ),
      ),
    );
  }

  Widget _howItWorksTile(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.ink))),
        ],
      ),
    );
  }
}

// --- NOTIFICATION SETTINGS SCREEN ---
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final String? token = PushNotificationService.instance.token;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Notification Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.aqua),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "G A Laundry Shop sends updates as push notifications from the app. We no longer send SMS or text messages.",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            title: const Text("Order Status Updates", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Push notification when your order is in process, ready to claim or claimed."),
            value: state.pushOrderUpdates,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => state.setPushPreference(orderUpdates: val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Promotions & Announcements", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text("Push notification about shop announcements and deals."),
            value: state.pushPromos,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => state.setPushPreference(promos: val),
          ),
          const Divider(),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                state.addPushMessage(
                  title: "Test notification",
                  body: "Push notifications are working on this device.",
                );
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text("SEND A TEST NOTIFICATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text("DEVICE TOKEN (FOR TESTING)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    token ?? "Not available yet. Allow notifications and make sure the phone is online.",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
                if (token != null)
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Device token copied.")));
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}