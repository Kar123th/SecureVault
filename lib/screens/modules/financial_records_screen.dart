import 'package:flutter/material.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import '../../utils/app_styles.dart';

class FinancialRecordsScreen extends StatefulWidget {
  const FinancialRecordsScreen({super.key});

  @override
  State<FinancialRecordsScreen> createState() => _FinancialRecordsScreenState();
}

class _FinancialRecordsScreenState extends State<FinancialRecordsScreen> {
  List<FinancialRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('financial_records', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _records = result.map((e) => FinancialRecord.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([FinancialRecord? rec]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _FinancialForm(record: rec)));
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Records')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty 
               ? const Center(child: Text('No records'))
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
                           backgroundColor: Colors.green.withOpacity(0.1),
                           child: const Icon(Icons.account_balance, color: Colors.green),
                         ),
                         title: Text(r.institutionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                         subtitle: Text('${r.recordType}\n${r.accountNumber ?? ""}'),
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

class _FinancialForm extends StatefulWidget {
  final FinancialRecord? record;
  const _FinancialForm({this.record});

  @override
  State<_FinancialForm> createState() => _FinancialFormState();
}

class _FinancialFormState extends State<_FinancialForm> {
  final _formKey = GlobalKey<FormState>();
  final _instCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'Bank Account';
  String? _filePath;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _instCtrl.text = r.institutionName;
      _accCtrl.text = r.accountNumber ?? '';
      _noteCtrl.text = r.notes ?? '';
      _type = r.recordType;
      _filePath = r.filePath;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newItem = FinancialRecord(
      id: widget.record?.id,
      userId: 1,
      recordType: _type,
      institutionName: _instCtrl.text,
      accountNumber: _accCtrl.text,
      notes: _noteCtrl.text,
      filePath: _filePath,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      await db.insert('financial_records', newItem.toJson());
    } else {
      await db.update('financial_records', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
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
      appBar: AppBar(title: Text(widget.record == null ? 'Add Financial Record' : 'Edit Record')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _instCtrl,
                  decoration: const InputDecoration(labelText: 'Institution Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: ['Bank Account', 'Credit Card', 'Loan', 'Insurance', 'Tax', 'Investment']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accCtrl,
                  decoration: const InputDecoration(labelText: 'Account/Policy Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                if (_filePath != null) ...[
                   const Center(child: Text('Document Attached', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       TextButton.icon(
                         onPressed: () async {
                           await FileService().openDecryptedFile(_filePath!);
                         }, 
                         icon: const Icon(Icons.remove_red_eye),
                         label: const Text('View Document'),
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
                    label: Text(_filePath == null ? 'Attach Document' : 'Change Document'),
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
