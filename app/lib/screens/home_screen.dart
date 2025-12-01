import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/auth_service.dart';
import '../widgets/enhanced_parcel_card.dart';
import 'create_parcel_screen.dart';
import 'parcel_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final bool isLoading;
  final Function(Parcel) onParcelAdded;
  final Function() onRefresh;
  final String title;
  final String emptyMessage;

  const HomeScreen({
    super.key,
    required this.parcels,
    required this.isLoading,
    required this.onParcelAdded,
    required this.onRefresh,
    this.title = 'Gestion des Colis',
    this.emptyMessage = 'Aucun colis pour le moment',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  String _parcelDirection = 'all'; // 'all', 'sent', 'received'

  List<Parcel> get _filteredParcels {
    var filtered = widget.parcels;
    final userOfficeId = AuthService.currentUser?.officeId;

    // Filter by direction (sent/received)
    if (_parcelDirection != 'all' && userOfficeId != null) {
      if (_parcelDirection == 'sent') {
        // Colis envoyés depuis notre bureau
        filtered = filtered
            .where((p) => p.originOfficeId == userOfficeId)
            .toList();
      } else if (_parcelDirection == 'received') {
        // Colis reçus à notre bureau
        filtered = filtered
            .where((p) => p.destinationOfficeId == userOfficeId)
            .toList();
      }
    }

    // Filter by status
    if (_filterStatus != 'all') {
      filtered = filtered.where((p) => p.status.name == _filterStatus).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((parcel) {
        return parcel.id.toLowerCase().contains(query) ||
            parcel.senderName.toLowerCase().contains(query) ||
            parcel.receiverName.toLowerCase().contains(query) ||
            parcel.destination.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: widget.onRefresh,
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher par ID, nom, destination...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Tous',
                        'all',
                        Icons.all_inclusive_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Créés',
                        'created',
                        Icons.fiber_new_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'En Transit',
                        'inTransit',
                        Icons.local_shipping_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Arrivés',
                        'arrived',
                        Icons.location_on_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Livrés',
                        'delivered',
                        Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Problèmes',
                        'issue',
                        Icons.warning_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Parcels List
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredParcels.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async => widget.onRefresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredParcels.length,
                      itemBuilder: (context, index) {
                        final parcel = _filteredParcels[index];
                        return EnhancedParcelCard(
                          parcel: parcel,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParcelDetailScreen(
                                  parcel: parcel,
                                  onStatusUpdated: widget.onRefresh,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateParcelScreen(onParcelCreated: widget.onParcelAdded),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau Colis'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF0066CC).withOpacity(0.15),
      checkmarkColor: const Color(0xFF0066CC),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0066CC) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDirectionChip(String label, String value, IconData icon) {
    final isSelected = _parcelDirection == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _parcelDirection = value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF10B981).withOpacity(0.15),
      checkmarkColor: const Color(0xFF10B981),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildParcelCard(Parcel parcel) {
    final userOfficeId = AuthService.currentUser?.officeId;
    final isSent = parcel.originOfficeId == userOfficeId;
    final isReceived = parcel.destinationOfficeId == userOfficeId;

    // Determine border color and badge
    Color borderColor = Colors.grey.shade200;
    Color badgeColor = Colors.grey;
    IconData badgeIcon = Icons.swap_horiz_rounded;
    String badgeLabel = '';

    if (isSent && !isReceived) {
      // Colis envoyé
      borderColor = const Color(0xFF3B82F6); // Bleu
      badgeColor = const Color(0xFF3B82F6);
      badgeIcon = Icons.upload_rounded;
      badgeLabel = 'Envoyé';
    } else if (isReceived && !isSent) {
      // Colis reçu
      borderColor = const Color(0xFF10B981); // Vert
      badgeColor = const Color(0xFF10B981);
      badgeIcon = Icons.download_rounded;
      badgeLabel = 'Reçu';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParcelDetailScreen(
              parcel: parcel,
              onStatusUpdated: widget.onRefresh,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(parcel.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: _getStatusColor(parcel.status),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  // Badge direction
                  if (badgeLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(parcel.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(parcel.status),
                  style: TextStyle(
                    color: _getStatusColor(parcel.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                parcel.receiverName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      parcel.destination,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      parcel.senderName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat trouvé'
                : widget.emptyMessage,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez une autre recherche'
                : 'Créez votre premier colis pour commencer',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateParcelScreen(
                      onParcelCreated: widget.onParcelAdded,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer un colis'),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusLabel(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return 'Créé';
      case ParcelStatus.inTransit:
        return 'En Transit';
      case ParcelStatus.arrived:
        return 'Arrivé';
      case ParcelStatus.delivered:
        return 'Livré';
      case ParcelStatus.issue:
        return 'Problème';
    }
  }

  Color _getStatusColor(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return const Color(0xFF9E9E9E);
      case ParcelStatus.inTransit:
        return const Color(0xFFFF9800);
      case ParcelStatus.arrived:
        return const Color(0xFF2196F3);
      case ParcelStatus.delivered:
        return const Color(0xFF4CAF50);
      case ParcelStatus.issue:
        return const Color(0xFFF44336);
    }
  }
}
