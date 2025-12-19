import 'package:flutter/material.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import '../../utils/app_styles.dart';

class EducationRecordsScreen extends StatefulWidget {
  const EducationRecordsScreen({super.key});

  @override
  State<EducationRecordsScreen> createState() => _EducationRecordsScreenState();
}

class _EducationRecordsScreenState extends State<EducationRecordsScreen> {
  List<EducationRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('education_records', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _records = result.map((e) => EducationRecord.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([EducationRecord? r]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _EducationForm(record: r)));
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? const Center(child: Text('No education records'))
                : ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final r = _records[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purpleAccent.withOpacity(0.1),
                            child: const Icon(Icons.school, color: Colors.purpleAccent),
                          ),
                          title: Text(r.degreeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${r.institution}\nYear: ${r.yearOfPassing ?? "N/A"}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.edit, size: 20),
                          onTap: () => _showForm(r),
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

class _EducationForm extends StatefulWidget {
  final EducationRecord? record;
  const _EducationForm({this.record});

  @override
  State<_EducationForm> createState() => _EducationFormState();
}

class _EducationFormState extends State<_EducationForm> {
  final _formKey = GlobalKey<FormState>();
  final _degCtrl = TextEditingController();
  final _instCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  String? _filePath;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _degCtrl.text = r.degreeName;
      _instCtrl.text = r.institution;
      _yearCtrl.text = r.yearOfPassing ?? '';
      _gradeCtrl.text = r.grade ?? '';
      _filePath = r.filePath;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newItem = EducationRecord(
      id: widget.record?.id,
      userId: 1,
      degreeName: _degCtrl.text,
      institution: _instCtrl.text,
      yearOfPassing: _yearCtrl.text,
      grade: _gradeCtrl.text,
      filePath: _filePath,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      await db.insert('education_records', newItem.toJson());
    } else {
      await db.update('education_records', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
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
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this education record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('education_records', where: 'id = ?', whereArgs: [widget.record!.id]);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'Add Education' : 'Edit Education'),
        actions: [
          if (widget.record != null)
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
                  controller: _degCtrl,
                  decoration: const InputDecoration(labelText: 'Degree / Certificate', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instCtrl,
                  decoration: const InputDecoration(labelText: 'Institution / Board', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearCtrl,
                        decoration: const InputDecoration(labelText: 'Year of Passing', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _gradeCtrl,
                        decoration: const InputDecoration(labelText: 'Grade / %', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_filePath != null) ...[
                   const Center(child: Text('Certificate Attached', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       TextButton.icon(
                         onPressed: () async {
                           await FileService().openDecryptedFile(_filePath!);
                         }, 
                         icon: const Icon(Icons.remove_red_eye),
                         label: const Text('View Certificate'),
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
                    label: Text(_filePath == null ? 'Attach Certificate' : 'Change Certificate'),
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
                  child: const Text('Save'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
