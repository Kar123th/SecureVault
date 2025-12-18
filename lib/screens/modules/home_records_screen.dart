import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';

class HomeRecordsScreen extends StatefulWidget {
  const HomeRecordsScreen({super.key});

  @override
  State<HomeRecordsScreen> createState() => _HomeRecordsScreenState();
}

class _HomeRecordsScreenState extends State<HomeRecordsScreen> {
  List<HomeRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('home_records', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _records = result.map((e) => HomeRecord.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([HomeRecord? r]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _HomeForm(record: r)));
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home & Warranty')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No items added'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.home_filled)),
                        title: Text(r.itemName),
                        subtitle: Text('${r.brand ?? "Unknown Brand"}\nWarranty: ${r.warrantyExpiry != null ? DateFormat('yyyy-MM-dd').format(r.warrantyExpiry!) : "N/A"}'),
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

class _HomeForm extends StatefulWidget {
  final HomeRecord? record;
  const _HomeForm({this.record});

  @override
  State<_HomeForm> createState() => _HomeFormState();
}

class _HomeFormState extends State<_HomeForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _billCtrl = TextEditingController();
  DateTime? _purchaseDate;
  DateTime? _warrantyDate;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _itemCtrl.text = r.itemName;
      _brandCtrl.text = r.brand ?? '';
      _billCtrl.text = r.billNumber ?? '';
      _purchaseDate = r.purchaseDate;
      _warrantyDate = r.warrantyExpiry;
      _filePath = r.filePath;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newItem = HomeRecord(
      id: widget.record?.id,
      userId: 1,
      itemName: _itemCtrl.text,
      brand: _brandCtrl.text,
      billNumber: _billCtrl.text,
      purchaseDate: _purchaseDate,
      warrantyExpiry: _warrantyDate,
      filePath: _filePath,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      await db.insert('home_records', newItem.toJson());
    } else {
      await db.update('home_records', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
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
      appBar: AppBar(title: Text(widget.record == null ? 'Add Item' : 'Edit Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _itemCtrl,
                decoration: const InputDecoration(labelText: 'Item Name (e.g. Fridge)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandCtrl,
                decoration: const InputDecoration(labelText: 'Brand / Manufacturer'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _billCtrl,
                decoration: const InputDecoration(labelText: 'Bill Number'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_purchaseDate == null ? 'Purchase Date' : 'Purchased: ${DateFormat('yyyy-MM-dd').format(_purchaseDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                  if (d != null) setState(() => _purchaseDate = d);
                },
              ),
              ListTile(
                title: Text(_warrantyDate == null ? 'Warranty Expiry' : 'Warranty Expires: ${DateFormat('yyyy-MM-dd').format(_warrantyDate!)}'),
                trailing: const Icon(Icons.security),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                  if (d != null) setState(() => _warrantyDate = d);
                },
              ),
              const SizedBox(height: 16),
              if (_filePath != null) ...[
                 const Text('Document Attached', style: TextStyle(color: Colors.green)),
                 TextButton(
                   onPressed: () async {
                     await FileService().openDecryptedFile(_filePath!);
                   }, 
                   child: const Text('View Bill/Warranty')
                 )
              ],
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_filePath == null ? 'Attach Bill/Warranty' : 'Change Document'),
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
