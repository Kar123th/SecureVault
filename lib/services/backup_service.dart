import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  Future<String> _getAppDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> createBackup() async {
    try {
      final appDir = await _getAppDir();
      final dbFile = File(join(appDir, 'secure_vault.db'));
      
      if (!await dbFile.exists()) {
        throw Exception("Database file not found");
      }

      final backupPath = join(appDir, 'securevault_db_backup.db');
      await dbFile.copy(backupPath);

      // Share the file
      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'SecureVault Database Backup',
        text: 'This is your encrypted vault database. Import it back to restore your data.',
      );
    } catch (e) {
      print('Backup error: $e');
      rethrow;
    }
  }

  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Looking for .db files
      );

      if (result == null || result.files.single.path == null) return false;

      final backupFile = File(result.files.single.path!);
      final appDir = await _getAppDir();
      final targetPath = join(appDir, 'secure_vault.db');

      // Close DB before overwriting
      await DatabaseService.instance.close();

      // Overwrite DB
      await backupFile.copy(targetPath);

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
}
