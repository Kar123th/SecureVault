import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  List<VehicleRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('vehicle_info', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _records = result.map((e) => VehicleRecord.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([VehicleRecord? record]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _VehicleForm(record: record)),
    );
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Information')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('No vehicle info added'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final rec = _records[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                        title: Text('${rec.vehicleType} - ${rec.regNumber}'),
                        subtitle: Text('${rec.documentType} \nExpires: ${rec.expiryDate != null ? DateFormat('yyyy-MM-dd').format(rec.expiryDate!) : 'N/A'}'),
                        isThreeLine: true,
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showForm(rec),
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

class _VehicleForm extends StatefulWidget {
  final VehicleRecord? record;
  const _VehicleForm({this.record});

  @override
  State<_VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<_VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _regCtrl = TextEditingController();
  String _vehicleType = 'Car';
  String _docType = 'RC Book';
  DateTime? _expiryDate;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _regCtrl.text = r.regNumber;
      _vehicleType = r.vehicleType;
      _docType = r.documentType;
      _expiryDate = r.expiryDate;
      _filePath = r.filePath;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newRec = VehicleRecord(
      id: widget.record?.id,
      userId: 1,
      vehicleType: _vehicleType,
      regNumber: _regCtrl.text,
      documentType: _docType,
      expiryDate: _expiryDate,
      filePath: _filePath,
    );

    final db = await DatabaseService.instance.database;
    if (newRec.id == null) {
      await db.insert('vehicle_info', newRec.toJson());
    } else {
      await db.update('vehicle_info', newRec.toJson(), where: 'id = ?', whereArgs: [newRec.id]);
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
      appBar: AppBar(title: Text(widget.record == null ? 'Add Vehicle Info' : 'Edit Vehicle Info')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _vehicleType,
                items: ['Car', 'Bike', 'Scooter', 'Truck', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _vehicleType = v!),
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regCtrl,
                decoration: const InputDecoration(labelText: 'Registration Number'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _docType,
                items: ['RC Book', 'Insurance', 'PUC', 'Service Record'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _docType = v!),
                decoration: const InputDecoration(labelText: 'Document Type'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_expiryDate == null ? 'Select Expiry Date' : 'Expiry: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2050));
                  if (d != null) setState(() => _expiryDate = d);
                },
              ),
              const SizedBox(height: 16),
              if (_filePath != null) ...[
                 const Center(child: Text('Document Attached', style: TextStyle(color: Colors.green))),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     TextButton.icon(
                       onPressed: () async {
                         await FileService().openDecryptedFile(_filePath!);
                       }, 
                       icon: const Icon(Icons.remove_red_eye),
                       label: const Text('View'),
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
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(_filePath == null ? 'Attach Document' : 'Change Document'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Save Record'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
