import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medical_record_model.dart';
import '../../services/file_service.dart';
import 'medical_record_form_screen.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final MedicalRecord record;

  const MedicalRecordDetailScreen({super.key, required this.record});

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalRecordFormScreen(record: record),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context, true); // Return to list to refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.category, 'Type', record.recordType),
            _buildDetailRow(Icons.calendar_today, 'Date', 
                DateFormat('yyyy-MM-dd').format(record.date)),
            _buildDetailRow(Icons.person, 'Doctor', record.doctorName ?? 'N/A'),
            const Divider(height: 32),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              record.notes ?? 'No notes available.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (record.filePath != null && record.filePath!.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  await FileService().openDecryptedFile(record.filePath!);
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('View Attachment'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueAccent.withOpacity(0.1),
          child: const Icon(Icons.file_present, size: 30, color: Colors.blueAccent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Added on ${DateFormat.yMMMd().format(DateTime.now())}', // Mock 'created_at' if not in model
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
