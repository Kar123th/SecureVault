import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite_sqlcipher/sqflite.dart'; // For DatabaseException
import 'database_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  Future<bool> isSetupComplete() async {
    String? value = await _storage.read(key: 'is_setup_complete');
    return value == 'true';
  }

  Future<bool> setupMasterPassword(String password) async {
    try {
      // Initialize DB with this password
      // In a real scenario, we might want to delete old DB if it exists
      await DatabaseService.instance.init(password);
      
      // Store setup flag
      await _storage.write(key: 'is_setup_complete', value: 'true');
      
      // Optionally store password for biometric access later if desired
      // For now, we won't strictly bind biometric to password storage until explicitly enabled
      return true;
    } catch (e) {
      print('Setup error: $e');
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    try {
      // Try to open/init database with this password
      // If the database is already open, we might need to close it first to test the key?
      // Or just assume if we are calling this, we want to open it.
      await DatabaseService.instance.init(password);
      
      // Test a query to ensure key is correct
      final db = await DatabaseService.instance.database;
      await db.query('users', limit: 1); 
      
      return true;
    } catch (e) {
      print('Login error: $e');
      // If encryption fails, it usually throws a DatabaseException
      return false;
    }
  }

  Future<bool> setBiometricEnabled(bool enabled, String? password) async {
    if (enabled) {
      if (password == null) return false;

      // Verify that the user can actually authenticate with biometrics on this device
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to link Biometrics to your Vault',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (!didAuthenticate) return false;

      await _storage.write(key: 'master_password', value: password);
      await _storage.write(key: 'biometric_enabled', value: 'true');
    } else {
      await _storage.delete(key: 'biometric_enabled');
      await _storage.delete(key: 'master_password');
    }
    return true;
  }
  
  Future<bool> isBiometricEnabled() async {
    String? val = await _storage.read(key: 'biometric_enabled');
    return val == 'true';
  }

  Future<String?> authenticateBiometric() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return null;

      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access SecureVault',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (didAuthenticate) {
        return await _storage.read(key: 'master_password');
      }
    } on PlatformException catch (e) {
      print('Biometric error: $e');
    }
    return null;
  }
}
