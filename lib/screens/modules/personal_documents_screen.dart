import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_styles.dart';

class PersonalDocumentsScreen extends StatefulWidget {
  const PersonalDocumentsScreen({super.key});

  @override
  State<PersonalDocumentsScreen> createState() => _PersonalDocumentsScreenState();
}

class _PersonalDocumentsScreenState extends State<PersonalDocumentsScreen> {
  List<PersonalDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('personal_documents', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _documents = result.map((e) => PersonalDocument.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([PersonalDocument? doc]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PersonalDocForm(document: doc)),
    );
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Documents')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? const Center(child: Text('No documents added'))
                : ListView.builder(
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: const Icon(Icons.badge, color: Colors.blueAccent),
                          ),
                          title: Text(doc.documentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${doc.category} \n${doc.documentNumber ?? "No Number"}'),
                          trailing: const Icon(Icons.edit, size: 20),
                          isThreeLine: true,
                          onTap: () => _showForm(doc),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PersonalDocForm extends StatefulWidget {
  final PersonalDocument? document;
  const _PersonalDocForm({this.document});

  @override
  State<_PersonalDocForm> createState() => _PersonalDocFormState();
}

class _PersonalDocFormState extends State<_PersonalDocForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  String _category = 'Aadhar';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      final d = widget.document!;
      _nameCtrl.text = d.documentName;
      _numCtrl.text = d.documentNumber ?? '';
      _category = d.category;
      _issueDate = d.issueDate;
      _expiryDate = d.expiryDate;
      _filePath = d.filePath;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newItem = PersonalDocument(
      id: widget.document?.id,
      userId: 1,
      category: _category,
      documentName: _nameCtrl.text,
      documentNumber: _numCtrl.text,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      filePath: _filePath,
    );

    final db = await DatabaseService.instance.database;
    int id;
    if (newItem.id == null) {
      id = await db.insert('personal_documents', newItem.toJson());
    } else {
      id = newItem.id!;
      await db.update('personal_documents', newItem.toJson(), where: 'id = ?', whereArgs: [id]);
    }

    // Schedule expiry notification if date is set
    if (_expiryDate != null) {
      await NotificationService().scheduleExpiryWarning(
        id: id,
        docName: _nameCtrl.text,
        expiryDate: _expiryDate!,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickFile() async {
    final path = await FileService().pickAndEncryptFile();
    if (path != null) setState(() => _filePath = path);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('personal_documents', where: 'id = ?', whereArgs: [widget.document!.id]);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document == null ? 'Add Document' : 'Edit Document'),
        actions: [
          if (widget.document != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Document Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: ['Aadhar', 'PAN', 'Passport', 'Driving License', 'Other']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numCtrl,
                  decoration: const InputDecoration(labelText: 'Document Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
                  child: ListTile(
                    title: Text(_expiryDate == null ? 'Select Expiry Date' : 'Expiry: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                      if (d != null) setState(() => _expiryDate = d);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_filePath != null) ...[
                   const Center(child: Text('File Attached (Encrypted)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       TextButton.icon(
                         onPressed: () async {
                           await FileService().openDecryptedFile(_filePath!);
                         }, 
                         icon: const Icon(Icons.remove_red_eye),
                         label: const Text('View File'),
                       ),
                       TextButton.icon(
                         onPressed: () async {
                           await FileService().shareFile(_filePath!);
                         },
                         icon: const Icon(Icons.share),
                         label: const Text('Share'),
                       ),
                     ],
                   ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_filePath == null ? 'Attach Copy' : 'Change File'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Document'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
