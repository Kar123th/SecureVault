import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import '../../utils/app_styles.dart';

class TravelRecordsScreen extends StatefulWidget {
  const TravelRecordsScreen({super.key});

  @override
  State<TravelRecordsScreen> createState() => _TravelRecordsScreenState();
}

class _TravelRecordsScreenState extends State<TravelRecordsScreen> {
  List<TravelDoc> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('travel_docs', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _records = result.map((e) => TravelDoc.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([TravelDoc? r]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _TravelForm(record: r)));
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Travel Documents')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? const Center(child: Text('No travel docs added'))
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
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: const Icon(Icons.flight, color: Colors.blueAccent),
                          ),
                          title: Text(r.docType, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${r.country ?? "No Country"}\n${r.docNumber ?? ""}'),
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

class _TravelForm extends StatefulWidget {
  final TravelDoc? record;
  const _TravelForm({this.record});

  @override
  State<_TravelForm> createState() => _TravelFormState();
}

class _TravelFormState extends State<_TravelForm> {
  final _formKey = GlobalKey<FormState>();
  final _countryCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  String _type = 'Passport';
  DateTime? _expiryDate;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _countryCtrl.text = r.country ?? '';
      _numCtrl.text = r.docNumber ?? '';
      _type = r.docType;
      _expiryDate = r.expiryDate;
      _filePath = r.filePath;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newItem = TravelDoc(
      id: widget.record?.id,
      userId: 1,
      docType: _type,
      country: _countryCtrl.text,
      docNumber: _numCtrl.text,
      expiryDate: _expiryDate,
      filePath: _filePath,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      await db.insert('travel_docs', newItem.toJson());
    } else {
      await db.update('travel_docs', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
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
      appBar: AppBar(title: Text(widget.record == null ? 'Add Travel Doc' : 'Edit Document')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  items: ['Passport', 'Visa', 'Ticket', 'Travel Insurance'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                  decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _countryCtrl,
                  decoration: const InputDecoration(labelText: 'Country (if applicable)', border: OutlineInputBorder()),
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
                    title: Text(_expiryDate == null ? 'Expiry / Travel Date' : 'Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                      if (d != null) setState(() => _expiryDate = d);
                    },
                  ),
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
