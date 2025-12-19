import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/all_models.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_styles.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<ReminderItem> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('reminders', where: 'user_id = ?', whereArgs: [1], orderBy: 'reminder_date ASC');
    setState(() {
      _reminders = result.map((e) => ReminderItem.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _toggleCompletion(ReminderItem item) async {
    final updated = ReminderItem(
      id: item.id,
      userId: item.userId,
      title: item.title,
      category: item.category,
      reminderDate: item.reminderDate,
      isCompleted: !item.isCompleted,
      notes: item.notes,
    );

    final db = await DatabaseService.instance.database;
    await db.update('reminders', updated.toJson(), where: 'id = ?', whereArgs: [item.id]);
    
    if (updated.isCompleted) {
      await NotificationService().cancelReminder(item.id!);
    } else {
      await NotificationService().scheduleReminder(updated);
    }

    _loadReminders();
  }

  Future<void> _showForm([ReminderItem? item]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ReminderForm(item: item)),
    );
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders & Alerts')),
      body: Container(
        decoration: AppStyles.mainGradientDecoration(context),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reminders.isEmpty
                ? const Center(child: Text('No reminders set'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final item = _reminders[index];
                      final isOverdue = item.reminderDate.isBefore(DateTime.now()) && !item.isCompleted;
      
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isCompleted 
                              ? Colors.green.withOpacity(0.1) 
                              : (isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                            child: Icon(
                              _getIconForCategory(item.category),
                              color: item.isCompleted 
                                ? Colors.green 
                                : (isOverdue ? Colors.red : Colors.orange),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.category} • ${DateFormat('MMM dd, yyyy').format(item.reminderDate)}'),
                              if (isOverdue)
                                const Text('Overdue!', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: item.isCompleted,
                              shape: const CircleBorder(),
                              onChanged: (_) => _toggleCompletion(item),
                            ),
                          ),
                          onTap: () => _showForm(item),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Electricity': return Icons.electric_bolt;
      case 'Insurance': return Icons.verified_user_outlined;
      case 'SIP / Investment': return Icons.trending_up;
      case 'Rent': return Icons.vpn_key_outlined;
      case 'Subscription': return Icons.subscriptions_outlined;
      default: return Icons.notifications_active_outlined;
    }
  }
}

class _ReminderForm extends StatefulWidget {
  final ReminderItem? item;
  const _ReminderForm({this.item});

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = 'Electricity';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final List<String> _categories = [
    'Electricity', 'Insurance', 'SIP / Investment', 'Rent', 'Subscription', 'Water Bill', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleCtrl.text = widget.item!.title;
      _notesCtrl.text = widget.item!.notes ?? '';
      _category = widget.item!.category;
      _selectedDate = widget.item!.reminderDate;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newItem = ReminderItem(
      id: widget.item?.id,
      userId: 1,
      title: _titleCtrl.text,
      category: _category,
      reminderDate: _selectedDate,
      isCompleted: widget.item?.isCompleted ?? false,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    final db = await DatabaseService.instance.database;
    if (newItem.id == null) {
      final id = await db.insert('reminders', newItem.toJson());
      final savedItem = ReminderItem(
        id: id,
        userId: newItem.userId,
        title: newItem.title,
        category: newItem.category,
        reminderDate: newItem.reminderDate,
        isCompleted: newItem.isCompleted,
        notes: newItem.notes,
      );
      await NotificationService().scheduleReminder(savedItem);
    } else {
      await db.update('reminders', newItem.toJson(), where: 'id = ?', whereArgs: [newItem.id]);
      await NotificationService().scheduleReminder(newItem);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('reminders', where: 'id = ?', whereArgs: [widget.item!.id]);
      await NotificationService().cancelReminder(widget.item!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Reminder' : 'Edit Reminder'),
        actions: [
          if (widget.item != null)
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
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Title',
                    hintText: 'e.g. Electricity Bill Pay',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue.shade100, width: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: const Text('Reminder Date'),
                    subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.item == null ? 'Save Reminder' : 'Update Reminder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
