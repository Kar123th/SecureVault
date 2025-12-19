import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../utils/app_styles.dart';
import '../services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import '../services/file_service.dart';
import '../services/database_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _image;
  String _extractedText = '';
  bool _isScanning = false;
  String? _suggestedCategory;

  final Map<String, List<String>> _categoryKeywords = {
    'Personal Docs (Passport)': ['passport', 'republic', 'nationality', 'place of birth'],
    'Personal Docs (ID Card)': ['identity card', 'national id', 'citizen', 'dob'],
    'Financial (Bill)': ['invoice', 'bill', 'receipt', 'amount', 'total', 'tax', 'utility'],
    'Medical Records': ['hospital', 'prescription', 'doctor', 'medical', 'patient', 'clinical'],
    'Vehicle Info': ['registration', 'rc', 'engine', 'chassis', 'vehicle'],
  };

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _extractedText = '';
        _suggestedCategory = null;
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;
    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFile(_image!);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String detectedText = recognizedText.text;
      
      // Auto-categorize
      String? category;
      String lowerText = detectedText.toLowerCase();
      
      for (var entry in _categoryKeywords.entries) {
        for (var keyword in entry.value) {
          if (lowerText.contains(keyword)) {
            category = entry.key;
            break;
          }
        }
        if (category != null) break;
      }

      setState(() {
        _extractedText = detectedText;
        _suggestedCategory = category;
      });
      
      textRecognizer.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error scanning: $e')));
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _exportAsPdf() async {
    if (_image == null) return;
    
    setState(() => _isScanning = true);
    try {
      final pdfFile = await PdfService.generatePdfFromImage(_image!, "Scan_${DateTime.now().millisecondsSinceEpoch}");
       
      if (!mounted) return;

      // Show Save/Share Dialog
      await showDialog(
        context: context,
        builder: (ctx) => _SavePdfDialog(
          pdfFile: pdfFile,
          suggestedCategory: _suggestedCategory,
          onSave: (name, category, subCategory) async {
             await _saveToVault(pdfFile, name, category, subCategory);
          },
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveToVault(File pdfFile, String name, String category, String? subCategory) async {
    try {
      // 1. Encrypt File
      final encryptedPath = await FileService().encryptFile(pdfFile);
      final db = await DatabaseService.instance.database;

      // 2. Insert into DB based on category
      switch (category) {
        case 'Personal':
          await db.insert('personal_documents', {
            'user_id': 1,
            'category': subCategory ?? 'Other',
            'document_name': name,
            'file_path': encryptedPath,
            'issue_date': DateTime.now().toIso8601String(), // Optional: set today as issue default
          });
          break;
        case 'Medical':
          await db.insert('medical_records', {
            'user_id': 1,
            'title': name,
            'record_type': 'other', // Default
            'date': DateTime.now().toIso8601String(),
            'file_path': encryptedPath,
          });
          break;
        case 'Vehicle':
          await db.insert('vehicle_info', {
            'user_id': 1,
            'vehicle_type': 'Car', // Default
            'reg_number': name, // Using name as identifier
            'doc_type': 'Scanned Doc',
            'file_path': encryptedPath,
            'expiry_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
          });
          break;
        case 'Financial':
          await db.insert('financial_records', {
            'user_id': 1,
            'record_type': 'Other',
            'institution_name': name,
            'file_path': encryptedPath,
          });
          break;
        case 'Education':
          await db.insert('education_records', {
            'user_id': 1,
            'degree_name': name,
            'institution': 'Scanned Document',
            'file_path': encryptedPath,
          });
          break;
        case 'Home':
          await db.insert('home_records', {
            'user_id': 1,
            'item_name': name,
            'brand': 'Unknown',
            'purchase_date': DateTime.now().toIso8601String(),
            'file_path': encryptedPath,
          });
          break;
        case 'Travel':
          await db.insert('travel_docs', {
            'user_id': 1,
            'doc_type': 'Other', 
            'country': name,
            'file_path': encryptedPath,
          });
          break;
        case 'Emergency':
           await db.insert('emergency_info', {
            'user_id': 1,
            'info_type': 'Emergency Contact', // Default
            'name': name,
            'value': 'See attached doc',
            'notes': 'Scanned document attached: $encryptedPath (Ref)',
           });
           break;
        case 'Password':
           // Passwords don't really support file paths directly in the simple model, append to notes?
           await db.insert('passwords', {
             'user_id': 1,
             'account_name': name,
             'username': 'See Attachment',
             'password': 'N/A',
             'notes': 'Scanned attachment: $name (Encrypted)',
             // Warning: Password table might not have file_path column based on previous code
           });
           break;
        case 'Reminders':
           await db.insert('reminders', {
             'user_id': 1,
             'title': name,
             'category': 'Other',
             'reminder_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
             'notes': 'Attachment saved securely',
             // Reminders table might not support file_path either
           });
           break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $category Vault!')));
        // 3. Trigger Share
        await Share.shareXFiles([XFile(pdfFile.path)], text: 'Exported Scanned Document');
      }
    } catch (e) {
      debugPrint('Save Error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save to $category: $e')));
    }
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: _extractedText));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Scanner')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        child: Column(
          children: [
            if (_suggestedCategory != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Detected: $_suggestedCategory',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Logic to save to this category
                      },
                      child: const Text('Save to Category'),
                    )
                  ],
                ),
              ),
            Expanded(
              flex: 2,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  width: double.infinity,
                  color: isDark ? Colors.black26 : Colors.blue.shade50.withOpacity(0.3),
                  child: _image == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_search, size: 64, color: Colors.blueAccent),
                              SizedBox(height: 16),
                              Text('Pick an image to scan', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : Image.file(_image!, fit: BoxFit.contain),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('EXTRACTED TEXT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent, letterSpacing: 1.1)),
                          Row(
                            children: [
                              if (_extractedText.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _exportAsPdf, 
                                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                                  label: const Text('Export PDF'),
                                ),
                              IconButton(
                                onPressed: _extractedText.isNotEmpty ? _copyText : null, 
                                icon: const Icon(Icons.copy, color: Colors.blueAccent),
                                tooltip: 'Copy to Clipboard',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _isScanning 
                          ? const Center(child: CircularProgressIndicator()) 
                          : Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.black26 : Colors.blue.shade50.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _extractedText.isEmpty && _image != null 
                                    ? 'No text found in this image.' 
                                    : (_extractedText.isEmpty ? 'Select an image above to begin scanning.' : _extractedText),
                                  style: const TextStyle(height: 1.5, fontSize: 15),
                                ),
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 70,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavePdfDialog extends StatefulWidget {
  final File pdfFile;
  final String? suggestedCategory;
  final Function(String name, String category, String? subCategory) onSave;

  const _SavePdfDialog({required this.pdfFile, required this.onSave, this.suggestedCategory});

  @override
  State<_SavePdfDialog> createState() => _SavePdfDialogState();
}

class _SavePdfDialogState extends State<_SavePdfDialog> {
  final _nameCtrl = TextEditingController();
  String _category = 'Personal';
  String _subCategory = 'Aadhar'; // Default sub-category for Personal

  final List<String> _categories = [
    'Personal',
    'Medical',
    'Vehicle',
    'Financial',
    'Education',
    'Home',
    'Travel',
    'Emergency',
    'Password',
    'Reminders'
  ];

  final List<String> _personalSubCategories = [
    'Aadhar',
    'PAN',
    'Passport',
    'Driving License',
    'Voter ID',
    'Student ID',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = "Scanned ${DateTime.now().hour}-${DateTime.now().minute}";
    if (widget.suggestedCategory != null) {
      if (widget.suggestedCategory!.contains('Passport')) {
        _category = 'Personal';
        _subCategory = 'Passport';
      } else if (widget.suggestedCategory!.contains('ID')) {
        _category = 'Personal';
        _subCategory = 'Other'; 
      } else if (widget.suggestedCategory!.contains('Medical')) {
        _category = 'Medical';
      } else if (widget.suggestedCategory!.contains('Vehicle')) {
        _category = 'Vehicle';
      } else if (widget.suggestedCategory!.contains('Bill')) {
        _category = 'Financial';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save to Vault'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save this document securely before sharing.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Document Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Select Category', border: OutlineInputBorder(), prefixIcon: Icon(Icons.folder)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                _category = v!;
                // Reset sub-category if switching away from Personal, or keep it if switching back? 
                // Typically just keep defaults or let user select.
              }),
            ),
            if (_category == 'Personal') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _subCategory,
                decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                items: _personalSubCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _subCategory = v!),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_nameCtrl.text.isEmpty) return;
            widget.onSave(_nameCtrl.text, _category, _category == 'Personal' ? _subCategory : null);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.save),
          label: const Text('Save & Share'),
        ),
      ],
    );
  }
}
