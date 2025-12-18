import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../services/backup_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _securityService = SecurityService.instance;

  bool _biometricEnabled = false;
  bool _screenshotPrevention = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final bio = await _authService.isBiometricEnabled();
    final ss = await _securityService.isScreenshotPreventionEnabled();
    setState(() {
      _biometricEnabled = bio;
      _screenshotPrevention = ss;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Logic to enable biometric: usually requires verifying current password
      final password = await _showPasswordDialog();
      if (password != null) {
        final success = await _authService.verifyPassword(password);
        if (success) {
          final bioSuccess = await _authService.setBiometricEnabled(true, password);
          if (bioSuccess) {
            setState(() => _biometricEnabled = true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics enabled successfully')));
          } else {
            _showError('Biometric verification failed');
          }
        } else {
          _showError('Invalid Password');
        }
      }
    } else {
      await _authService.setBiometricEnabled(false, null);
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _toggleScreenshotPrevention(bool value) async {
    await _securityService.setScreenshotPrevention(value);
    setState(() => _screenshotPrevention = value);
  }

  Future<String?> _showPasswordDialog() async {
    String? password;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Password'),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Master Password'),
          onChanged: (v) => password = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, password), child: const Text('Verify')),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle('Security'),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Change Master Password'),
                  subtitle: const Text('Reset your primary entry code'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Unlock with Fingerprint or Face'),
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
                const Divider(),
                _buildSectionTitle('Privacy'),
                SwitchListTile(
                  secondary: const Icon(Icons.screenshot_monitor),
                  title: const Text('Prevent Screenshots'),
                  subtitle: const Text('Block screenshots/screen recordings'),
                  value: _screenshotPrevention,
                  onChanged: _toggleScreenshotPrevention,
                ),
                const Divider(),
                _buildSectionTitle('Data Management'),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Export encrypted backup file'),
                  onTap: () async {
                    try {
                      await BackupService.instance.createBackup();
                    } catch (e) {
                      _showError('Backup failed: $e');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Import from backup file'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restore Backup?'),
                        content: const Text('This will overwrite all current data. This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final success = await BackupService.instance.restoreBackup();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Restore successful! Restart app to apply.')),
                        );
                        // Force a logout/restart logic if needed
                      } else {
                        _showError('Restore failed or cancelled');
                      }
                    }
                  },
                ),
                const Divider(),
                _buildSectionTitle('About'),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('SecureVault Version'),
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
