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
import 'package:secure_vault/screens/modules/password_manager_screen.dart';
import 'package:secure_vault/screens/modules/reminders_screen.dart';

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
    {'title': 'Passwords', 'icon': Icons.password_outlined, 'color': Colors.teal, 'route': '/passwords'},
    {'title': 'Reminders', 'icon': Icons.notifications_active_outlined, 'color': Colors.indigo, 'route': '/reminders'},
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
      case '/passwords': screen = const PasswordManagerScreen(); break;
      case '/reminders': screen = const RemindersScreen(); break;
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50.withOpacity(0.5),
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: Colors.white.withOpacity(0.9),
              elevation: 0,
              title: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'SecureVault',
                    style: TextStyle(
                      color: Colors.black87, 
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen())),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: const Text(
                  'My Vault',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: -0.5,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn().moveX(begin: -20, end: 0),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cat = categories[index];
                    return _DashboardCard(
                      title: cat['title'],
                      icon: cat['icon'],
                      color: cat['color'],
                      onTap: () => _navigateTo(context, cat['route']),
                    ).animate().scale(delay: Duration(milliseconds: 50 * index), curve: Curves.easeOutBack).fade();
                  },
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen())),
        label: const Text('Scan Doc', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.document_scanner),
        elevation: 4,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ).animate().slideY(begin: 1.5, end: 0, delay: 400.ms, curve: Curves.elasticOut),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.blue.shade50, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
