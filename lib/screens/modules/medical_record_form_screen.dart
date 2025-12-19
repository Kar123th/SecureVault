import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/medical_record_model.dart';
import '../../services/file_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_styles.dart';
import 'medical_records_screen.dart';

class MedicalRecordFormScreen extends StatefulWidget {
  final MedicalRecord? record; // If null, we are adding new

  const MedicalRecordFormScreen({super.key, this.record});

  @override
  State<MedicalRecordFormScreen> createState() => _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends State<MedicalRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _doctorController;
  late TextEditingController _notesController;
  
  String _selectedType = 'prescription';
  DateTime _selectedDate = DateTime.now();
  DateTime? _expiryDate;
  String? _filePath; // Added
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record?.title ?? '');
    _doctorController = TextEditingController(text: widget.record?.doctorName ?? '');
    _notesController = TextEditingController(text: widget.record?.notes ?? '');
    if (widget.record != null) {
      _selectedType = widget.record!.recordType;
      _selectedDate = widget.record!.date;
      _filePath = widget.record!.filePath;
      _expiryDate = widget.record!.expiryDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {bool isExpiry = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiry ? (_expiryDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final path = await FileService().pickAndEncryptFile();
    if (path != null) setState(() => _filePath = path);
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newRecord = MedicalRecord(
      id: widget.record?.id, 
      userId: 1, 
      title: _titleController.text,
      recordType: _selectedType,
      date: _selectedDate,
      doctorName: _doctorController.text,
      notes: _notesController.text,
      filePath: _filePath,
      expiryDate: _expiryDate,
    );

    final db = await DatabaseService.instance.database;
    int id;
    if (widget.record == null) {
      id = await db.insert('medical_records', newRecord.toJson());
    } else {
      id = widget.record!.id!;
      await db.update('medical_records', newRecord.toJson(), where: 'id = ?', whereArgs: [id]);
    }

    if (_expiryDate != null) {
      await NotificationService().scheduleExpiryWarning(
        id: id + 500000, // Offset for medical expiry
        docName: 'Medical: ${_titleController.text}',
        expiryDate: _expiryDate!,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this medical record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('medical_records', where: 'id = ?', whereArgs: [widget.record!.id]);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'Add Medical Record' : 'Edit Record'),
        actions: [
          if (widget.record != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title / Purpose',
                    hintText: 'e.g. Annual Checkup',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Record Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                    DropdownMenuItem(value: 'lab_report', child: Text('Lab Report')),
                    DropdownMenuItem(value: 'vaccination', child: Text('Vaccination')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: 16),
  
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: () => _selectDate(context, isExpiry: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event_busy),
                    ),
                    child: Text(
                      _expiryDate == null ? 'None' : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
  
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
  
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
  
                if (_filePath != null) ...[
                   const Text('Attachment Linked (Encrypted)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                   TextButton.icon(
                     onPressed: () async {
                       await FileService().openDecryptedFile(_filePath!);
                     }, 
                     icon: const Icon(Icons.remove_red_eye),
                     label: const Text('View Current File')
                   )
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
  
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Record'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
