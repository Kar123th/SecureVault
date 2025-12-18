import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/database_service.dart';
// Import all specific screens to navigate to them
import 'modules/medical_records_screen.dart'; // We might need to make detail screens accessible generically
import 'modules/personal_documents_screen.dart';
import 'modules/vehicle_info_screen.dart';
import 'modules/financial_records_screen.dart';
import 'modules/education_records_screen.dart';
import 'modules/home_records_screen.dart';
import 'modules/travel_records_screen.dart';
import 'modules/emergency_info_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> allResults = [];

    // Helper to query and tag results
    Future<void> searchTable(String table, String type, String titleCol, String subCol) async {
      final res = await db.query(
        table,
        where: '$titleCol LIKE ? OR $subCol LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
      for (var r in res) {
        allResults.add({
          'type': type,
          'title': r[titleCol],
          'subtitle': r[subCol], // Rough mapping
          'data': r,
          'table': table,
        });
      }
    }

    await searchTable('medical_records', 'Medical', 'title', 'doctor_name');
    await searchTable('personal_documents', 'Personal', 'document_name', 'document_number');
    await searchTable('vehicle_info', 'Vehicle', 'reg_number', 'vehicle_type');
    await searchTable('financial_records', 'Financial', 'institution_name', 'account_number');
    await searchTable('education_records', 'Education', 'degree_name', 'institution');
    await searchTable('home_records', 'Home', 'item_name', 'brand');
    await searchTable('travel_docs', 'Travel', 'doc_type', 'country');
    await searchTable('emergency_info', 'Emergency', 'name', 'value');

    setState(() {
      _results = allResults;
      _isSearching = false;
    });
  }

  void _navigateToItem(Map<String, dynamic> item) {
    // For now, simpler to just open the relevant list screen
    // Enhancing this to open direct detail is possible but requires refactoring all modules to accept IDs
    Widget? screen;
    switch(item['table']) {
      case 'medical_records': screen = const MedicalRecordsScreen(); break;
      case 'personal_documents': screen = const PersonalDocumentsScreen(); break;
      case 'vehicle_info': screen = const VehicleInfoScreen(); break;
      case 'financial_records': screen = const FinancialRecordsScreen(); break;
      case 'education_records': screen = const EducationRecordsScreen(); break;
      case 'home_records': screen = const HomeRecordsScreen(); break;
      case 'travel_docs': screen = const TravelRecordsScreen(); break;
      case 'emergency_info': screen = const EmergencyInfoScreen(); break;
    }
    
    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search everything...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _performSearch,
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty ? 'Type to search' : 'No matches found',
                        style: const TextStyle(color: Colors.grey),
                      )
                    ],
                  ).animate().fade().scale(),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: _getIcon(item['type']),
                        title: Text(item['title']?.toString() ?? 'Unknown'),
                        subtitle: Text('${item['type']} • ${item['subtitle'] ?? ""}'),
                        onTap: () => _navigateToItem(item),
                      ),
                    ).animate().slideX(begin: 1.0, end: 0.0, delay: Duration(milliseconds: index * 50)).fade();
                  },
                ),
    );
  }

  Icon _getIcon(String type) {
    switch (type) {
      case 'Medical': return const Icon(Icons.medical_services, color: Colors.red);
      case 'Personal': return const Icon(Icons.badge, color: Colors.blue);
      case 'Vehicle': return const Icon(Icons.directions_car, color: Colors.orange);
      case 'Financial': return const Icon(Icons.account_balance, color: Colors.green);
      // ... Add others
      default: return const Icon(Icons.folder, color: Colors.grey);
    }
  }
}
