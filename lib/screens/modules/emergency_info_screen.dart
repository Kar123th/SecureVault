import 'package:flutter/material.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../utils/app_styles.dart';

class EmergencyInfoScreen extends StatefulWidget {
  const EmergencyInfoScreen({super.key});

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  List<EmergencyInfo> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('emergency_info', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _records = result.map((e) => EmergencyInfo.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([EmergencyInfo? r]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => _EmergencyForm(record: r)));
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Info')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? const Center(child: Text('No emergency info'))
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
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            child: const Icon(Icons.medical_information, color: Colors.redAccent),
                          ),
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${r.infoType}: ${r.value}'),
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

class _EmergencyForm extends StatefulWidget {
  final EmergencyInfo? record;
  const _EmergencyForm({this.record});

  @override
  State<_EmergencyForm> createState() => _EmergencyFormState();
}

class _EmergencyFormState extends State<_EmergencyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'Emergency Contact';

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final r = widget.record!;
      _nameCtrl.text = r.name;
      _valCtrl.text = r.value;
      _noteCtrl.text = r.notes ?? '';
      _type = r.infoType;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newItem = EmergencyInfo(
      id: widget.record?.id,
      userId: 1,
      infoType: _type,
      name: _nameCtrl.text,
      value: _valCtrl.text,
      notes: _noteCtrl.text,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      await db.insert('emergency_info', newItem.toJson());
    } else {
      await db.update('emergency_info', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Info'),
        content: const Text('Are you sure you want to delete this emergency info?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('emergency_info', where: 'id = ?', whereArgs: [widget.record!.id]);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'Add Info' : 'Edit Info'),
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
                DropdownButtonFormField<String>(
                  value: _type,
                  items: ['Emergency Contact', 'Blood Group', 'Allergy', 'Medication', 'Doctor']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _type = v!),
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name / Title (e.g. Dr. Smith)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valCtrl,
                  decoration: const InputDecoration(labelText: 'Value (Phone / O+ etc)', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                  maxLines: 3,
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
