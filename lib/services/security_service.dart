import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:no_screenshot/no_screenshot.dart';

class SecurityService {
  static final SecurityService instance = SecurityService._internal();
  SecurityService._internal();

  final _storage = const FlutterSecureStorage();
  final _noScreenshot = NoScreenshot.instance;

  Future<void> init() async {
    final enabled = await isScreenshotPreventionEnabled();
    if (enabled) {
      await applyScreenshotPrevention(true);
    }
  }

  Future<bool> isScreenshotPreventionEnabled() async {
    final value = await _storage.read(key: 'screenshot_prevention');
    return value == 'true';
  }

  Future<void> setScreenshotPrevention(bool enabled) async {
    await _storage.write(key: 'screenshot_prevention', value: enabled.toString());
    await applyScreenshotPrevention(enabled);
  }

  Future<void> applyScreenshotPrevention(bool enabled) async {
    if (enabled) {
      await _noScreenshot.screenshotOff();
    } else {
      await _noScreenshot.screenshotOn();
    }
  }
}
