import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/medical_record_model.dart';
import 'medical_record_form_screen.dart';
import 'medical_record_detail_screen.dart';
import '../../utils/app_styles.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _isLoading = true;
  List<MedicalRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    // In a real app, get current user ID from auth state
    // For now, assume user_id = 1
    final db = await DatabaseService.instance.database;
    final result = await db.query(
      'medical_records',
      where: 'user_id = ?',
      whereArgs: [1],
      orderBy: 'date DESC',
    );

    setState(() {
      _records = result.map((json) => MedicalRecord.fromJson(json)).toList();
      _isLoading = false;
    });
  }

  Future<void> _navigateToDetail(MedicalRecord record) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalRecordDetailScreen(record: record),
      ),
    );

    if (result == true) {
      _loadRecords();
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MedicalRecordFormScreen(),
      ),
    );

    if (result == true) {
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: Container(
        decoration: AppStyles.mainGradientDecoration,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No medical records yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red[100],
                            child: Icon(
                              _getIconForType(record.recordType),
                              color: Colors.red,
                            ),
                          ),
                          title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${record.date.day}/${record.date.month}/${record.date.year} • ${record.doctorName ?? "No Doctor"}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _navigateToDetail(record),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'prescription':
        return Icons.note_alt_outlined;
      case 'lab_report':
        return Icons.science_outlined;
      case 'vaccination':
        return Icons.vaccines_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
