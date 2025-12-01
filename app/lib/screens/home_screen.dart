import 'package:flutter/material.dart';
import '../models/parcel.dart';
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
  final bool showCreateButton;

  const HomeScreen({
    super.key,
    required this.parcels,
    required this.isLoading,
    required this.onParcelAdded,
    required this.onRefresh,
    this.title = 'Gestion des Colis',
    this.emptyMessage = 'Aucun colis pour le moment',
    this.showCreateButton = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  List<Parcel> get _filteredParcels {
    var filtered = widget.parcels;

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
                  color: Colors.black.withValues(alpha: 0.03),
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
      floatingActionButton: widget.showCreateButton
          ? FloatingActionButton.extended(
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
              label: const Text('Nouveau Colis'),
            )
          : null,
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
      selectedColor: const Color(0xFF0066CC).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF0066CC),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0066CC) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                : widget.showCreateButton
                ? 'Créez votre premier colis pour commencer'
                : '',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          if (_searchQuery.isEmpty && widget.showCreateButton) ...[
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
}
