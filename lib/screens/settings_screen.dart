import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../services/backup_service.dart';
import '../utils/app_styles.dart';
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

  Future<void> _setupDecoyPIN() async {
    String? pin;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Decoy PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a secondary PIN that will open a decoy vault with no sensitive data.'),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Decoy PIN (Numeric)'),
              onChanged: (v) => pin = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, pin), child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _authService.setDecoyPIN(result);
      if (success) {
        _showError('Decoy PIN setup successfully');
      } else {
        _showError('Failed to setup Decoy PIN');
      }
    }
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
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        height: double.infinity,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildSectionTitle('Security'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.password, color: Colors.white, size: 20),
                          ),
                          title: const Text('Change Master Password', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Reset your primary entry code'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupScreen()));
                          },
                        ),
                        const Divider(indent: 70),
                        SwitchListTile(
                          secondary: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.fingerprint, color: Colors.white, size: 20),
                          ),
                          title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Unlock with Fingerprint or Face'),
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                        ),
                        const Divider(indent: 70),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          ),
                          title: const Text('Setup Decoy PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Set a fake PIN for emergency situations'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _setupDecoyPIN,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Privacy'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return SwitchListTile(
                              secondary: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.dark_mode, color: Colors.white, size: 20),
                              ),
                              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Toggle between light and dark themes'),
                              value: themeProvider.isDarkMode,
                              onChanged: (value) => themeProvider.toggleTheme(),
                            );
                          },
                        ),
                        const Divider(indent: 70),
                        SwitchListTile(
                          secondary: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.screenshot_monitor, color: Colors.white, size: 20),
                          ),
                          title: const Text('Prevent Screenshots', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Block screenshots/screen recordings'),
                          value: _screenshotPrevention,
                          onChanged: _toggleScreenshotPrevention,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Data Management'),
                  _buildSettingCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.backup, color: Colors.white, size: 20),
                          ),
                          title: const Text('Backup Data', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Export encrypted backup file'),
                          onTap: () async {
                            try {
                              await BackupService.instance.createBackup();
                            } catch (e) {
                              _showError('Backup failed: $e');
                            }
                          },
                        ),
                        const Divider(indent: 70),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.restore, color: Colors.white, size: 20),
                          ),
                          title: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              } else {
                                _showError('Restore failed or cancelled');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('About'),
                  _buildSettingCard(
                    child: const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.info_outline, color: Colors.white, size: 20),
                      ),
                      title: Text('SecureVault Version', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('1.0.0'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }
}
