import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/office.dart';
import '../widgets/main_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'boss';
  Office? _selectedOffice;
  List<Office> _offices = [];

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    final offices = await AuthService.fetchOffices();
    setState(() => _offices = offices);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == 'agent' && _selectedOffice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Veuillez sélectionner un bureau'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final result = await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        officeId: _selectedOffice?.id,
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
                  child: Text(result['message'] ?? 'Erreur d\'inscription'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Créer un Compte')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // GK Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Speedometer circle with G and K
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CustomPaint(painter: _GKLogoPainter()),
                    ),
                    const SizedBox(width: 10),
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
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFE53935),
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'press',
                              style: TextStyle(
                                fontSize: 26,
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
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE53935),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Inscription',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre compte GK Express',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Role Selection
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rôle',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              RadioGroup<String>(
                                groupValue: _selectedRole,
                                onChanged: (value) =>
                                    setState(() => _selectedRole = value!),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Boss (PDG)'),
                                        value: 'boss',
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: const Text('Agent'),
                                        value: 'agent',
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom Complet',
                            prefixIcon: Icon(Icons.person_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nom requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_rounded),
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

                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_rounded),
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
                            if (value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),

                        if (_selectedRole == 'agent') ...[
                          const SizedBox(height: 20),
                          DropdownButtonFormField<Office>(
                            initialValue: _selectedOffice,
                            decoration: const InputDecoration(
                              labelText: 'Bureau',
                              prefixIcon: Icon(Icons.business_rounded),
                            ),
                            items: _offices.map((office) {
                              return DropdownMenuItem(
                                value: office,
                                child: Text('${office.flag} ${office.name}'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedOffice = value),
                            validator: (value) {
                              if (_selectedRole == 'agent' && value == null) {
                                return 'Bureau requis pour les agents';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066CC),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'CRÉER MON COMPTE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    final radius = size.width / 2 - 3;

    // Draw speedometer arc (black)
    final arcPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
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
      ..strokeWidth = 1.5
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
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFFE53935),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    gPainter.layout();
    gPainter.paint(canvas, Offset(center.dx - 13, center.dy - 10));

    // Draw "K" in black
    final kPainter = TextPainter(
      text: const TextSpan(
        text: 'K',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1A1A1A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    kPainter.layout();
    kPainter.paint(canvas, Offset(center.dx + 1, center.dy - 7));

    // Draw red accent line (needle)
    final needlePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 5, center.dy + 8),
      Offset(center.dx + 8, center.dy - 5),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
