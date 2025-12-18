import 'package:flutter/material.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No education records'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.school)),
                        title: Text(r.degreeName),
                        subtitle: Text('${r.institution}\nYear: ${r.yearOfPassing ?? "N/A"}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showForm(r),
                      ),
                    );
                  },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.record == null ? 'Add Education' : 'Edit Education')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _degCtrl,
                decoration: const InputDecoration(labelText: 'Degree / Certificate'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instCtrl,
                decoration: const InputDecoration(labelText: 'Institution / Board'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearCtrl,
                      decoration: const InputDecoration(labelText: 'Year of Passing'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _gradeCtrl,
                      decoration: const InputDecoration(labelText: 'Grade / %'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_filePath != null) 
                 const Text('Certificate Attached', style: TextStyle(color: Colors.green)),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_filePath == null ? 'Attach Certificate' : 'Change Certificate'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
