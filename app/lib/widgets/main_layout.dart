import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../models/parcel.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../widgets/in_app_notification.dart';
import '../widgets/modern_sidebar.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  List<Parcel> _parcels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParcels();
    _initializeSocket();
  }

  void _initializeSocket() {
    SocketService.connect();

    SocketService.onNewParcel((data) async {
      debugPrint('📬 New parcel notification received: $data');

      if (mounted) {
        InAppNotification.show(
          context,
          title: '📦 Nouveau Colis Reçu !',
          message:
              'De ${data['originOfficeId'] ?? 'Inconnu'} → ${data['destination'] ?? ''}\nExpéditeur: ${data['senderName'] ?? 'Inconnu'}',
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF10B981),
        );
      }

      try {
        await NotificationService.showNewParcelNotification(
          parcelId: data['parcelId'] ?? '',
          senderName: data['senderName'] ?? 'Inconnu',
          originOffice: data['originOfficeId'] ?? '',
          destination: data['destination'] ?? '',
        );
      } catch (e) {
        debugPrint('System notification failed: $e');
      }

      _loadParcels();
    });
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadParcels() async {
    setState(() => _isLoading = true);
    final parcels = await ApiService.fetchParcels();
    setState(() {
      _parcels = parcels;
      _isLoading = false;
    });
  }

  void _addParcel(Parcel parcel) {
    setState(() {
      _parcels.insert(0, parcel);
    });
  }

  List<Parcel> _getSentParcels() {
    final userOfficeId = AuthService.currentUser?.officeId;
    if (userOfficeId == null) return [];
    return _parcels.where((p) => p.originOfficeId == userOfficeId).toList();
  }

  List<Parcel> _getReceivedParcels() {
    final userOfficeId = AuthService.currentUser?.officeId;
    if (userOfficeId == null) return [];
    return _parcels
        .where((p) => p.destinationOfficeId == userOfficeId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Index 0: Dashboard
    // Index 1: Colis Envoyés
    // Index 2: Colis Reçus
    // Index 3: Tous les colis
    // Index 4: Messages
    // Index 5: Utilisateurs
    // Index 6: Paramètres
    final List<Widget> screens = [
      DashboardScreen(parcels: _parcels, isLoading: _isLoading),
      HomeScreen(
        parcels: _getSentParcels(),
        isLoading: _isLoading,
        onParcelAdded: _addParcel,
        onRefresh: _loadParcels,
        title: 'Colis Envoyés',
        emptyMessage: 'Aucun colis envoyé',
      ),
      HomeScreen(
        parcels: _getReceivedParcels(),
        isLoading: _isLoading,
        onParcelAdded: _addParcel,
        onRefresh: _loadParcels,
        title: 'Colis Reçus',
        emptyMessage: 'Aucun colis reçu',
        showCreateButton: false,
      ),
      HomeScreen(
        parcels: _parcels,
        isLoading: _isLoading,
        onParcelAdded: _addParcel,
        onRefresh: _loadParcels,
        title: 'Tous les Colis',
        emptyMessage: 'Aucun colis',
      ),
      const Center(
        child: Text(
          'Messages (Bientôt)',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
      const Center(
        child: Text(
          'Utilisateurs (Bientôt)',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          ModernSidebar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            onLogout: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
