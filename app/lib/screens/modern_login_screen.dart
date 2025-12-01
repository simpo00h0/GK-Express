import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/main_layout.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(result['message'] ?? 'Erreur de connexion'),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusSmall,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated GK Logo
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Speedometer circle with G and K
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(painter: _GKLogoPainter()),
                        ),
                        const SizedBox(width: 12),
                        // EXpress text with DELIVERY below
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'EX',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFE53935),
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  'press',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1A1A1A),
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'DELIVERY',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE53935),
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Slogan
                  Text(
                    'Simple, rapide et efficace!',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppTheme.borderRadiusLarge,
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connectez-vous à votre compte',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'votre@email.com',
                              prefixIcon: const Icon(Icons.email_rounded),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.borderRadiusSmall,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.borderRadiusSmall,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.borderRadiusSmall,
                                borderSide: const BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email requis';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.borderRadiusSmall,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppTheme.borderRadiusSmall,
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppTheme.borderRadiusSmall,
                                borderSide: const BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mot de passe requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Login Button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: AppTheme.borderRadiusSmall,
                              boxShadow: AppTheme.glowShadow(AppTheme.primary),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppTheme.borderRadiusSmall,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'SE CONNECTER',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// Custom painter for GK Logo
class _GKLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw speedometer arc (black)
    final arcPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const startAngle = 2.4;
    const sweepAngle = 4.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 6; i++) {
      final angle = startAngle + (sweepAngle * i / 6);
      final outerPoint = Offset(
        center.dx + radius * 0.95 * math.cos(angle),
        center.dy + radius * 0.95 * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + radius * 0.75 * math.cos(angle),
        center.dy + radius * 0.75 * math.sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Draw "G" in red
    final gPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Color(0xFFE53935),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    gPainter.layout();
    gPainter.paint(canvas, Offset(center.dx - 18, center.dy - 14));

    // Draw "K" in black
    final kPainter = TextPainter(
      text: const TextSpan(
        text: 'K',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1A1A1A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    kPainter.layout();
    kPainter.paint(canvas, Offset(center.dx + 2, center.dy - 10));

    // Draw red accent line (needle)
    final needlePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 8, center.dy + 12),
      Offset(center.dx + 12, center.dy - 8),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
