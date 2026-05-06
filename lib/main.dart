import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/appointment_model.dart';
import 'core/theme.dart';
import 'screens/booking_screen.dart';
import 'screens/queue_status_screen.dart';
import 'screens/appointment_list_screen.dart';
import 'screens/admin_dashboard_screen.dart';

/// Entry point for the QueueMate application.
/// Initializes Firebase, Hive local storage, and registers type adapters
/// before launching the app wrapped in Riverpod's ProviderScope.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for Flutter (local storage)
  await Hive.initFlutter();

  // Register the Appointment Hive adapter for serialization
  Hive.registerAdapter(AppointmentAdapter());

  // Open the appointments box for CRUD operations
  await Hive.openBox<Appointment>('appointments');

  // Launch the app with Riverpod state management
  runApp(const ProviderScope(child: QueueMateApp()));
}

/// Root widget for the QueueMate application.
/// Sets up Material 3 theming and bottom navigation with 4 tabs.
class QueueMateApp extends StatelessWidget {
  const QueueMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QueueMate',
      theme: QueueMateTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigation(),
    );
  }
}

/// MainNavigation provides the bottom navigation bar with 4 tabs:
/// Book, Queue, Appointments, and Admin.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  /// List of screens corresponding to each bottom navigation tab.
  final List<Widget> _screens = const [
    BookingScreen(),
    QueueStatusScreen(),
    AppointmentListScreen(),
    AdminDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_outlined),
            activeIcon: Icon(Icons.queue),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}
