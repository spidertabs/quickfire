import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/supabase_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _regController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _regController.dispose();
    _passController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final reg = _regController.text.trim();
    final pass = _passController.text.trim();

    if (reg.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final studentData = await SupabaseService.loginStudent(reg, pass);

      if (!mounted) return;

      if (studentData != null) {
        var student = Student.fromJson(studentData);
        // Fetch college name from the database
        if (student.collegeId != null) {
          final collegeName =
              await SupabaseService.getCollegeName(student.collegeId!);
          if (collegeName != null) {
            student = student.copyWith(collegeName: collegeName);
          }
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home', arguments: student);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/images/q_dark.png'
                          : 'assets/images/q_light.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name and Tagline
                  Text(
                    'Quickfire',
                    style: TextStyle(
                      color: AppTheme.getTextPrimary(context),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UEMS Online Assessment Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.getSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.getBorder(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Use your student registration number',
                          style: TextStyle(
                              color: AppTheme.getTextSecondary(context), fontSize: 13),
                        ),
                        const SizedBox(height: 24),

                        // Registration number
                        Text(
                          'Registration Number',
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _regController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. KIU/2024/0001',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        Text(
                          'Password',
                          style: TextStyle(
                            color: AppTheme.getTextPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Login to Dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  // Footer
                  Text(
                    '© 2026 UEMS-PhD-VV Extention',
                    style: TextStyle(
                      color: AppTheme.getTextMuted(context),
                      fontSize: 11,
                    ),
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
