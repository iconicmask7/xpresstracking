import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animated_button.dart';
import '../../../core/utils/glass_card.dart';
import '../../../core/utils/error_handler.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnimation = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref.read(authViewModelProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(authViewModelProvider, (previous, next) {
      if (next.hasError && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getFriendlyMessage(next.error!)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final authState = ref.watch(authViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Stack(
          children: [
            // Animated background blobs
            _AnimatedBackground(animation: _bgAnimation, isDark: isDark),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 48.h),

                      // Logo & title
                      Center(
                        child: Column(
                          children: [
                            // Animated logo circle
                            _LogoWidget(animation: _bgAnimation)
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: -0.3, curve: Curves.easeOutBack),
                            SizedBox(height: 24.h),
                            Text(
                              'XpressTrack',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [
                                          AppColors.gradientStart,
                                          AppColors.gradientEnd,
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0, 0, 200, 70),
                                      ),
                                  ),
                            )
                                .animate(delay: 200.ms)
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2),
                            SizedBox(height: 8.h),
                            Text(
                              'Delivery intelligence, simplified.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(letterSpacing: 0.3),
                            )
                                .animate(delay: 350.ms)
                                .fadeIn(duration: 500.ms),
                          ],
                        ),
                      ),

                      SizedBox(height: 48.h),

                      // Login card
                      GlassCard(
                        padding: EdgeInsets.all(28.r),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            )
                                .animate(delay: 400.ms)
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: -0.1),
                            SizedBox(height: 4.h),
                            Text(
                              'Sign in to continue tracking',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                                .animate(delay: 450.ms)
                                .fadeIn(duration: 400.ms),
                            SizedBox(height: 28.h),

                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Email is required';
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                                return null;
                              },
                            )
                                .animate(delay: 500.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.15),
                            SizedBox(height: 16.h),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password is required';
                                if (value.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.lightTextSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            )
                                .animate(delay: 575.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.15),

                            SizedBox(height: 28.h),

                            GradientButton(
                              label: 'Sign In',
                              onPressed: _handleLogin,
                              isLoading: authState.isLoading,
                              icon: Icons.arrow_forward_rounded,
                            )
                                .animate(delay: 650.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2),

                            SizedBox(height: 24.h),
                            
                            // Sign up link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(delay: 700.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.2),
                          ],
                        ),
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOutCubic),

                      SizedBox(height: 32.h),

                      // Footer
                      Center(
                        child: Text(
                          '© 2024 XpressTrack. All rights reserved.',
                          style: Theme.of(context).textTheme.labelSmall,
                        ).animate(delay: 800.ms).fadeIn(),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        suffixIcon: suffix,
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  final Animation<double> animation;

  const _LogoWidget({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: const [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment(
                math.cos(animation.value * 2 * math.pi),
                math.sin(animation.value * 2 * math.pi),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4 + animation.value * 0.2),
                blurRadius: 24 + animation.value * 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 48,
          ),
        );
      },
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final Animation<double> animation;
  final bool isDark;

  const _AnimatedBackground({required this.animation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Stack(
          children: [
            // Primary blob
            Positioned(
              top: -80 + animation.value * 40,
              right: -60 + animation.value * 30,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            // Secondary blob
            Positioned(
              bottom: 80 + animation.value * 30,
              left: -80 + animation.value * 20,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: isDark ? 0.18 : 0.08),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
