import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import animations
import 'package:secure_vault/screens/login_screen.dart';
import 'package:secure_vault/screens/search_screen.dart'; // Import Search
import 'package:secure_vault/screens/scanner_screen.dart'; // Import Scanner
import 'package:secure_vault/screens/settings_screen.dart'; // New Settings Screen
import 'package:secure_vault/screens/setup_screen.dart';

// Module Imports 
import 'package:secure_vault/screens/modules/medical_records_screen.dart';
import 'package:secure_vault/screens/modules/personal_documents_screen.dart';
import 'package:secure_vault/screens/modules/vehicle_info_screen.dart';
import 'package:secure_vault/screens/modules/financial_records_screen.dart';
import 'package:secure_vault/screens/modules/education_records_screen.dart';
import 'package:secure_vault/screens/modules/home_records_screen.dart';
import 'package:secure_vault/screens/modules/travel_records_screen.dart';
import 'package:secure_vault/screens/modules/emergency_info_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'title': 'Medical Records', 'icon': Icons.medical_services_outlined, 'color': Colors.redAccent, 'route': '/medical'},
    {'title': 'Personal Docs', 'icon': Icons.badge_outlined, 'color': Colors.blueAccent, 'route': '/personal'},
    {'title': 'Vehicle Info', 'icon': Icons.directions_car_outlined, 'color': Colors.orangeAccent, 'route': '/vehicle'},
    {'title': 'Financial', 'icon': Icons.account_balance_outlined, 'color': Colors.green, 'route': '/financial'},
    {'title': 'Education', 'icon': Icons.school_outlined, 'color': Colors.purpleAccent, 'route': '/education'},
    {'title': 'Home & Warranty', 'icon': Icons.home_outlined, 'color': Colors.brown, 'route': '/home'},
    {'title': 'Travel Docs', 'icon': Icons.flight_takeoff, 'color': Colors.lightBlue, 'route': '/travel'},
    {'title': 'Emergency', 'icon': Icons.emergency_outlined, 'color': Colors.red, 'route': '/emergency'},
  ];

  void _navigateTo(BuildContext context, String route) {
    Widget? screen;
    switch (route) {
      case '/medical': screen = const MedicalRecordsScreen(); break;
      case '/personal': screen = const PersonalDocumentsScreen(); break;
      case '/vehicle': screen = const VehicleInfoScreen(); break;
      case '/financial': screen = const FinancialRecordsScreen(); break;
      case '/education': screen = const EducationRecordsScreen(); break;
      case '/home': screen = const HomeRecordsScreen(); break;
      case '/travel': screen = const TravelRecordsScreen(); break;
      case '/emergency': screen = const EmergencyInfoScreen(); break;
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('SecureVault'),
          ],
        ).animate().fade(duration: 500.ms).slide(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                 Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              } else if (value == 'settings') {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); 
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Vault',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ).animate().fadeIn().moveY(begin: -20, end: 0),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return _DashboardCard(
                    title: cat['title'],
                    icon: cat['icon'],
                    color: cat['color'],
                    onTap: () => _navigateTo(context, cat['route']),
                  ).animate().scale(delay: Duration(milliseconds: 100 * index)).fade();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
        label: const Text('Scan Doc'),
        icon: const Icon(Icons.document_scanner),
      ).animate().slideY(begin: 1, end: 0, delay: 500.ms),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
