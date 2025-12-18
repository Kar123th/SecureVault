import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  final _storage = const FlutterSecureStorage();
  final _imagePicker = ImagePicker();

  // Get or create the data encryption key
  Future<String> _getEncryptionKey() async {
    String? key = await _storage.read(key: 'file_encryption_key');
    if (key == null) {
      // Generate a new 32-char key (AES-256)
      final newKey = enc.Key.fromSecureRandom(32);
      key = newKey.base64;
      await _storage.write(key: 'file_encryption_key', value: key);
    }
    return key;
  }

  // Pick and Encrypt Image
  Future<String?> pickAndEncryptImage(bool fromCamera) async {
    final XFile? image = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80, // Compress
    );
    
    if (image == null) return null;
    return await _encryptFile(File(image.path));
  }

  // Pick and Encrypt Document (PDF etc)
  Future<String?> pickAndEncryptFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return null;
    return await _encryptFile(File(result.files.single.path!));
  }

  Future<String> _encryptFile(File originalFile) async {
    final keyStr = await _getEncryptionKey();
    final key = enc.Key.fromBase64(keyStr);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));

    final bytes = await originalFile.readAsBytes();
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(originalFile.path)}.enc';
    final savePath = p.join(appDir.path, fileName);
    
    // Save IV + Encrypted Data
    // We prepend the IV to the file for decryption later
    final file = File(savePath);
    await file.writeAsBytes(iv.bytes + encrypted.bytes);

    return savePath;
  }

  Future<File?> decryptFile(String path) async {
    final encryptedFile = File(path);
    if (!await encryptedFile.exists()) return null;

    final keyStr = await _getEncryptionKey();
    final key = enc.Key.fromBase64(keyStr);
    final encrypter = enc.Encrypter(enc.AES(key));

    final allBytes = await encryptedFile.readAsBytes();
    
    // Extract IV (first 16 bytes)
    final ivBytes = allBytes.sublist(0, 16);
    final contentBytes = allBytes.sublist(16);
    final iv = enc.IV(ivBytes);

    final decrypted = encrypter.decryptBytes(enc.Encrypted(contentBytes), iv: iv);

    // Save to a temporary file for viewing
    final tempDir = await getTemporaryDirectory();
    // Try to recover extension from filename or default to .jpg/.pdf if unknown
    // Real implementation would store metadata. For now, we assume standard viewing.
    String originalName = p.basename(path).replaceAll('.enc', '');
    // If we originally appended extension before .enc, it stays. 
    // e.g. "timestamp_image.jpg.enc" -> "timestamp_image.jpg"
    
    final tempPath = p.join(tempDir.path, originalName);
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(decrypted);

    return tempFile;
  }

  Future<void> openDecryptedFile(String path) async {
    final file = await decryptFile(path);
    if (file != null) {
      await OpenFilex.open(file.path);
    }
  }
}
