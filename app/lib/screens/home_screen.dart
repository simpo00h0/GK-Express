import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../models/office.dart';
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
  final List<Office>? offices;
  final ParcelViewType viewType;

  const HomeScreen({
    super.key,
    required this.parcels,
    required this.isLoading,
    required this.onParcelAdded,
    required this.onRefresh,
    this.title = 'Gestion des Colis',
    this.emptyMessage = 'Aucun colis pour le moment',
    this.showCreateButton = true,
    this.offices,
    this.viewType = ParcelViewType.all,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  String get _filterLabel {
    switch (_filterStatus) {
      case 'created':
        return '🆕 Créés';
      case 'inTransit':
        return '🚚 En Transit';
      case 'arrived':
        return '📍 Arrivés';
      case 'delivered':
        return '✅ Livrés';
      case 'issue':
        return '⚠️ Problèmes';
      default:
        return '🔄 Tous les statuts';
    }
  }

  Future<void> _showFilterSelector() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.filter_list_rounded, color: Color(0xFF0066CC)),
              const SizedBox(width: 12),
              const Text('Filtrer par statut'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterOption(
                    context,
                    'all',
                    '🔄 Tous les statuts',
                    Icons.all_inclusive_rounded,
                  ),
                  const Divider(),
                  _buildFilterOption(
                    context,
                    'created',
                    '🆕 Créés',
                    Icons.fiber_new_rounded,
                  ),
                  _buildFilterOption(
                    context,
                    'inTransit',
                    '🚚 En Transit',
                    Icons.local_shipping_rounded,
                  ),
                  _buildFilterOption(
                    context,
                    'arrived',
                    '📍 Arrivés',
                    Icons.location_on_rounded,
                  ),
                  _buildFilterOption(
                    context,
                    'delivered',
                    '✅ Livrés',
                    Icons.check_circle_rounded,
                  ),
                  _buildFilterOption(
                    context,
                    'issue',
                    '⚠️ Problèmes',
                    Icons.warning_rounded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _filterStatus == value;
    return ListTile(
      leading: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF0066CC))
          : Icon(icon, color: Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF0066CC) : null,
        ),
      ),
      onTap: () {
        setState(() => _filterStatus = value);
        Navigator.of(context).pop();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: const Color(0xFF0066CC).withValues(alpha: 0.1),
    );
  }

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
                const SizedBox(height: 12),
                // Status Filter Button
                Row(
                  children: [
                    InkWell(
                      onTap: _showFilterSelector,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _filterStatus != 'all'
                              ? const Color(0xFF0066CC).withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _filterStatus != 'all'
                                ? const Color(0xFF0066CC)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: _filterStatus != 'all'
                                  ? const Color(0xFF0066CC)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _filterLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _filterStatus != 'all'
                                    ? const Color(0xFF0066CC)
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: _filterStatus != 'all'
                                  ? const Color(0xFF0066CC)
                                  : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_filterStatus != 'all') ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => setState(() => _filterStatus = 'all'),
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Réinitialiser'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
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
                          offices: widget.offices,
                          viewType: widget.viewType,
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
