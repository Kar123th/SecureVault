import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

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
    final password = await _authService.authenticateBiometric();
    if (password != null) {
      setState(() => _isLoading = true);
      final success = await _authService.verifyPassword(password);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Unlock SecureVault',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Unlock'),
              ),
            ),
            if (_canCheckBiometrics) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _handleBiometricAuth,
                icon: const Icon(Icons.fingerprint, size: 30),
                label: const Text('Use Biometrics'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
