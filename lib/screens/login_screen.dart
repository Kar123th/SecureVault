import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import '../utils/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final enabled = await _authService.isBiometricEnabled();
    if (enabled && mounted) {
      setState(() => _canCheckBiometrics = true);
      _handleBiometricAuth(); // Auto-prompt on load
    }
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() => _isLoading = true);

    final success = await _authService.verifyPassword(password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')),
        );
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final password = await _authService.authenticateBiometric();
      if (password != null) {
        setState(() => _isLoading = true);
        final success = await _authService.verifyPassword(password);
        
        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric login failed: Invalid saved credentials')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Biometric login error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        height: double.infinity,
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Hero(
                tag: 'logo',
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Unlock SecureVault',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Master Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Unlock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (_canCheckBiometrics) ...[
                const SizedBox(height: 30),
                const Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                InkWell(
                  onTap: _handleBiometricAuth,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint, size: 50, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Use Biometrics', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
