import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/file_service.dart';
import 'dart:io';

// --- Configuration Classes ---

enum FieldType { text, date, dropdown, file }

class FieldConfig {
  final String key;
  final String label;
  final FieldType type;
  final List<String>? options; // For dropdown
  final bool required;

  FieldConfig({required this.key, required this.label, this.type = FieldType.text, this.options, this.required = false});
}

abstract class ModuleConfig<T> {
  String get title;
  String get tableName;
  List<FieldConfig> get fields;
  
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  
  // Helpers to get data for generic UI
  String getTitle(T item);
  String getSubtitle(T item);
  String? getFilePath(T item);
}

// --- Generic Screen Implementation ---

class GenericModuleListScreen<T> extends StatefulWidget {
  final ModuleConfig<T> config;
  const GenericModuleListScreen({super.key, required this.config});

  @override
  State<GenericModuleListScreen<T>> createState() => _GenericModuleListScreenState<T>();
}

class _GenericModuleListScreenState<T> extends State<GenericModuleListScreen<T>> {
  List<T> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query(widget.config.tableName, where: 'user_id = ?', whereArgs: [1]); // Mock user_id 1
    setState(() {
      _items = result.map((e) => widget.config.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _navigate([T? item]) async {
    final res = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => GenericFormScreen<T>(config: widget.config, item: item))
    );
    if (res == true) _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.config.title)),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : 
        _items.isEmpty ? Center(child: Text('No ${widget.config.title} yet')) :
        ListView.builder(
          itemCount: _items.length,
          itemBuilder: (ctx, i) {
            final item = _items[i];
            return Card(
              child: ListTile(
                title: Text(widget.config.getTitle(item)),
                subtitle: Text(widget.config.getSubtitle(item)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _navigate(item),
              ),
            );
          }
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GenericFormScreen<T> extends StatefulWidget {
  final ModuleConfig<T> config;
  final T? item;
  const GenericFormScreen({super.key, required this.config, this.item});

  @override
  State<GenericFormScreen<T>> createState() => _GenericFormScreenState<T>();
}

class _GenericFormScreenState<T> extends State<GenericFormScreen<T>> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _formData.addAll(widget.config.toJson(widget.item!));
    } else {
      // Initialize defaults
      for (var f in widget.config.fields) {
        if (f.type == FieldType.text) _formData[f.key] = '';
        if (f.type == FieldType.date) _formData[f.key] = DateTime.now().toIso8601String();
        if (f.type == FieldType.dropdown) _formData[f.key] = f.options!.first;
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final db = await DatabaseService.instance.database;
    final data = Map<String, dynamic>.from(_formData);
    data['user_id'] = 1; // Mock

    if (widget.item == null) {
      await db.insert(widget.config.tableName, data);
    } else {
      final id = widget.config.toJson(widget.item!)['id'];
      await db.update(widget.config.tableName, data, where: 'id = ?', whereArgs: [id]);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickFile(String key) async {
    final path = await FileService().pickAndEncryptFile(); // Generic file pickle
    if (path != null) {
      setState(() => _formData[key] = path);
    }
  }

  Future<void> _viewFile(String path) async {
    final file = await FileService().decryptFile(path);
    if (file != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Decrypted to ${file.path}')));
      // Real app would open with OpenFile package
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.item == null ? 'Add' : 'Edit'} ${widget.config.title}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...widget.config.fields.map((field) {
              if (field.type == FieldType.file) {
                 final val = _formData[field.key];
                 return Column(
                   children: [
                     if (val != null) ...[
                       Text('File attached'),
                       TextButton(onPressed: () => _viewFile(val), child: const Text('View Decrypted')),
                     ],
                     OutlinedButton.icon(
                       onPressed: () => _pickFile(field.key),
                       icon: const Icon(Icons.attach_file),
                       label: Text(val == null ? 'Attach ${field.label}' : 'Change File'),
                     ),
                     const SizedBox(height: 16),
                   ],
                 );
              }
              if (field.type == FieldType.dropdown) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _formData[field.key],
                    decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
                    items: field.options!.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => setState(() => _formData[field.key] = v),
                  ),
                );
              }
              if (field.type == FieldType.date) {
                final date = DateTime.tryParse(_formData[field.key] ?? '') ?? DateTime.now();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(1900), lastDate: DateTime(2100));
                      if (picked != null) setState(() => _formData[field.key] = picked.toIso8601String());
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
                      child: Text(DateFormat('yyyy-MM-dd').format(date)),
                    ),
                  ),
                );
              }
              // Text
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  initialValue: _formData[field.key],
                  decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
                  onChanged: (v) => _formData[field.key] = v,
                  validator: field.required ? (v) => v!.isEmpty ? 'Required' : null : null,
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save'),
            )
          ],
        ),
      ),
    );
  }
}
