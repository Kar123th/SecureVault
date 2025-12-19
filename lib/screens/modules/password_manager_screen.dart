import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../utils/app_styles.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  List<PasswordItem> _passwords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('passwords', where: 'user_id = ?', whereArgs: [1]);
    setState(() {
      _passwords = result.map((e) => PasswordItem.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _showForm([PasswordItem? item]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PasswordForm(item: item)),
    );
    _loadPasswords();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Manager')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _passwords.isEmpty
                ? const Center(child: Text('No passwords saved'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _passwords.length,
                    itemBuilder: (context, index) {
                      final item = _passwords[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                          ),
                          title: Text(item.accountName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.username),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.blueAccent),
                                onPressed: () => _copyToClipboard(item.password, 'Password'),
                                tooltip: 'Copy Password',
                              ),
                              const Icon(Icons.chevron_right, size: 18),
                            ],
                          ),
                          onTap: () => _showForm(item),
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

class _PasswordForm extends StatefulWidget {
  final PasswordItem? item;
  const _PasswordForm({this.item});

  @override
  State<_PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<_PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _accountCtrl.text = widget.item!.accountName;
      _userCtrl.text = widget.item!.username;
      _passCtrl.text = widget.item!.password;
      _webCtrl.text = widget.item!.website ?? '';
      _notesCtrl.text = widget.item!.notes ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newItem = PasswordItem(
      id: widget.item?.id,
      userId: 1, // Mock user ID
      accountName: _accountCtrl.text,
      username: _userCtrl.text,
      password: _passCtrl.text,
      website: _webCtrl.text.isEmpty ? null : _webCtrl.text,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      await db.insert('passwords', newItem.toJson());
    } else {
      await db.update('passwords', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: const Text('Are you sure you want to delete this password?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('passwords', where: 'id = ?', whereArgs: [widget.item!.id]);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Password' : 'Edit Password'),
        actions: [
          if (widget.item != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
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
                  controller: _accountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. Google, Netflix, Bank',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _webCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.item == null ? 'Save Password' : 'Update Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
