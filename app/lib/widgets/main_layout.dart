import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/users_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/medias_screen.dart';
import '../screens/messages_screen.dart';
import '../models/parcel.dart';
import '../models/office.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import '../widgets/in_app_notification.dart';
import '../widgets/modern_sidebar.dart';
import '../widgets/enhanced_parcel_card.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  List<Parcel> _parcels = [];
  List<User> _users = [];
  bool _isLoading = true;
  bool _isLoadingUsers = false;
  Set<String> _onlineUserIds = {};

  // Sélecteur de bureau global pour le Boss
  String? _selectedOfficeId;
  String? _selectedOfficeName;
  static List<Office>? _cachedOffices;

  @override
  void initState() {
    super.initState();
    _loadParcels();
    _loadOffices();
    _loadUsers();
    _initializeSocket();
  }

  Future<void> _loadOffices() async {
    if (_cachedOffices == null) {
      final offices = await ApiService.fetchOffices();
      if (mounted) {
        setState(() {
          _cachedOffices = offices;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    if (!_isBoss) return;
    setState(() => _isLoadingUsers = true);
    final users = await ApiService.fetchUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    }
    // Request online users after loading
    SocketService.requestOnlineUsers();
  }

  void _initializeSocket() {
    SocketService.connect();

    // Listen for presence updates
    SocketService.onPresenceUpdate((onlineIds) {
      if (mounted) {
        setState(() {
          _onlineUserIds = onlineIds;
        });
      }
    });

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

  // Boss: colis envoyés par le bureau sélectionné
  List<Parcel> _getBossSentParcels() {
    if (_selectedOfficeId == null) return _parcels;
    return _parcels
        .where((p) => p.originOfficeId == _selectedOfficeId)
        .toList();
  }

  // Boss: colis reçus par le bureau sélectionné
  List<Parcel> _getBossReceivedParcels() {
    if (_selectedOfficeId == null) return _parcels;
    return _parcels
        .where((p) => p.destinationOfficeId == _selectedOfficeId)
        .toList();
  }

  // Boss: tous les colis du bureau sélectionné
  List<Parcel> _getBossAllParcels() {
    if (_selectedOfficeId == null) return _parcels;
    return _parcels
        .where(
          (p) =>
              p.originOfficeId == _selectedOfficeId ||
              p.destinationOfficeId == _selectedOfficeId,
        )
        .toList();
  }

  // Le Boss ne peut pas créer de colis, il supervise uniquement
  bool get _isBoss => AuthService.currentUser?.role == 'boss';

  String get _officeLabel => _selectedOfficeName ?? '🌍 Tous les bureaux';

  Future<void> _showOfficeSelector() async {
    List<Office> offices = _cachedOffices ?? [];
    bool isLoading = _cachedOffices == null;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isLoading && _cachedOffices == null) {
              ApiService.fetchOffices()
                  .then((data) {
                    _cachedOffices = data;
                    setDialogState(() {
                      offices = data;
                      isLoading = false;
                    });
                  })
                  .catchError((e) {
                    setDialogState(() => isLoading = false);
                  });
            }

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.business_rounded, color: Color(0xFF9C27B0)),
                  const SizedBox(width: 12),
                  const Text('Sélectionner un bureau'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildOfficeOption(
                              dialogContext,
                              null,
                              '🌍 Tous les bureaux',
                            ),
                            const Divider(),
                            ...offices.map(
                              (office) => _buildOfficeOption(
                                dialogContext,
                                office,
                                '${office.flag} ${office.name}',
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOfficeOption(
    BuildContext dialogContext,
    Office? office,
    String label,
  ) {
    final isSelected = _selectedOfficeId == office?.id;
    return ListTile(
      leading: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF9C27B0))
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF9C27B0) : null,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedOfficeId = office?.id;
          _selectedOfficeName = office != null
              ? '${office.flag} ${office.name}'
              : null;
        });
        Navigator.of(dialogContext).pop();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: const Color(0xFF9C27B0).withValues(alpha: 0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colis filtrés pour le Boss
    final bossSentParcels = _getBossSentParcels();
    final bossReceivedParcels = _getBossReceivedParcels();
    final bossAllParcels = _getBossAllParcels();

    // Index 0: Dashboard
    // Index 1: Colis Envoyés
    // Index 2: Colis Reçus
    // Index 3: Tous les colis
    // Index 4: Messages
    // Index 5: Utilisateurs
    // Index 6: Paramètres
    final List<Widget> screens = [
      DashboardScreen(
        parcels: _isBoss ? bossAllParcels : _parcels,
        isLoading: _isLoading,
      ),
      HomeScreen(
        parcels: _isBoss ? bossSentParcels : _getSentParcels(),
        isLoading: _isLoading,
        onParcelAdded: _addParcel,
        onRefresh: _loadParcels,
        title: _isBoss
            ? (_selectedOfficeId != null
                  ? 'Colis Envoyés - $_selectedOfficeName'
                  : 'Tous les Colis Envoyés')
            : 'Colis Envoyés',
        emptyMessage: 'Aucun colis envoyé',
        showCreateButton: !_isBoss,
        offices: _cachedOffices,
        viewType: ParcelViewType.sent,
      ),
      HomeScreen(
        parcels: _isBoss ? bossReceivedParcels : _getReceivedParcels(),
        isLoading: _isLoading,
        onParcelAdded: _addParcel,
        onRefresh: _loadParcels,
        title: _isBoss
            ? (_selectedOfficeId != null
                  ? 'Colis Reçus - $_selectedOfficeName'
                  : 'Tous les Colis Reçus')
            : 'Colis Reçus',
        emptyMessage: 'Aucun colis reçu',
        showCreateButton: false,
        offices: _cachedOffices,
        viewType: ParcelViewType.received,
      ),
      HomeScreen(
        parcels: _isBoss ? bossAllParcels : _parcels,
        isLoading: _isLoading,
        onParcelAdded: _addParcel,
        onRefresh: _loadParcels,
        title: _isBoss
            ? (_selectedOfficeId != null
                  ? 'Tous les Colis - $_selectedOfficeName'
                  : 'Tous les Colis')
            : 'Tous les Colis',
        emptyMessage: 'Aucun colis',
        showCreateButton: !_isBoss,
        offices: _cachedOffices,
        viewType: ParcelViewType.all,
      ),
      const MessagesScreen(),
      // Écran des utilisateurs (Boss uniquement)
      _isBoss
          ? UsersScreen(
              users: _users,
              offices: _cachedOffices ?? [],
              isLoading: _isLoadingUsers,
              onlineUserIds: _onlineUserIds,
              onRefresh: _loadUsers,
            )
          : const Center(
              child: Text(
                'Accès réservé aux superviseurs',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
      // Écran des analyses (Agent et Boss)
      AnalyticsScreen(
        parcels: _parcels,
        offices: _cachedOffices ?? [],
        isLoading: _isLoading,
        onRefresh: _loadParcels,
      ),
      // Écran des médias (Disponible bientôt)
      const MediasScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          ModernSidebar(
            selectedIndex: _selectedIndex,
            isBoss: _isBoss,
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
          Expanded(
            child: Column(
              children: [
                // AppBar global avec sélecteur de bureau pour le Boss
                if (_isBoss)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        // Sélecteur de bureau
                        InkWell(
                          onTap: _showOfficeSelector,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedOfficeId != null
                                  ? const Color(
                                      0xFF9C27B0,
                                    ).withValues(alpha: 0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedOfficeId != null
                                    ? const Color(0xFF9C27B0)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 18,
                                  color: _selectedOfficeId != null
                                      ? const Color(0xFF9C27B0)
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _officeLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedOfficeId != null
                                        ? const Color(0xFF9C27B0)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: _selectedOfficeId != null
                                      ? const Color(0xFF9C27B0)
                                      : Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedOfficeId != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedOfficeId = null;
                                _selectedOfficeName = null;
                              });
                            },
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: 'Réinitialiser',
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: _loadParcels,
                          tooltip: 'Actualiser',
                        ),
                      ],
                    ),
                  ),
                Expanded(child: screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
