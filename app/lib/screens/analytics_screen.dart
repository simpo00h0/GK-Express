import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../models/office.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final List<Office> offices;
  final bool isLoading;
  final VoidCallback? onRefresh;

  const AnalyticsScreen({
    super.key,
    required this.parcels,
    required this.offices,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';

  bool get _isBoss => AuthService.currentUser?.role == 'boss';
  String? get _currentOfficeId => AuthService.currentUser?.officeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isBoss ? 4 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Filter parcels by period
  List<Parcel> get _filteredParcels {
    final now = DateTime.now();
    return widget.parcels.where((p) {
      final created = p.createdAt;
      switch (_selectedPeriod) {
        case 'week':
          return now.difference(created).inDays <= 7;
        case 'month':
          return now.difference(created).inDays <= 30;
        case 'year':
          return now.difference(created).inDays <= 365;
        default:
          return true;
      }
    }).toList();
  }

  // Get office-specific parcels for agents
  List<Parcel> get _officeParcels {
    if (_isBoss) return _filteredParcels;
    return _filteredParcels
        .where(
          (p) =>
              p.originOfficeId == _currentOfficeId ||
              p.destinationOfficeId == _currentOfficeId,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _isBoss
                        ? [
                            _buildOverviewTab(),
                            _buildOfficesTab(),
                            _buildFlowsTab(),
                            _buildPerformanceTab(),
                          ]
                        : [_buildOverviewTab(), _buildPerformanceTab()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isBoss ? 'Analyses Système' : 'Analyses Bureau',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _isBoss
                    ? 'Vue complète de tous les bureaux'
                    : 'Statistiques de votre bureau',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          _buildPeriodSelector(),
          const SizedBox(width: 16),
          IconButton(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedPeriod,
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: 'week', child: Text('7 derniers jours')),
          DropdownMenuItem(value: 'month', child: Text('30 derniers jours')),
          DropdownMenuItem(value: 'year', child: Text('Cette année')),
          DropdownMenuItem(value: 'all', child: Text('Tout')),
        ],
        onChanged: (v) => setState(() => _selectedPeriod = v!),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primary,
        tabs: _isBoss
            ? const [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'Vue Générale'),
                Tab(icon: Icon(Icons.business_rounded), text: 'Bureaux'),
                Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'Flux'),
                Tab(icon: Icon(Icons.speed_rounded), text: 'Performance'),
              ]
            : const [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'Vue Générale'),
                Tab(icon: Icon(Icons.speed_rounded), text: 'Performance'),
              ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    final parcels = _officeParcels;
    final sent = parcels
        .where((p) => _isBoss || p.originOfficeId == _currentOfficeId)
        .length;
    final received = parcels
        .where((p) => _isBoss || p.destinationOfficeId == _currentOfficeId)
        .length;
    final delivered = parcels
        .where((p) => p.status == ParcelStatus.delivered)
        .length;
    final pending = parcels
        .where(
          (p) =>
              p.status == ParcelStatus.created ||
              p.status == ParcelStatus.inTransit,
        )
        .length;
    final totalRevenue = parcels.fold<double>(0, (sum, p) => sum + p.price);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards Row
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Total Colis',
                  '${parcels.length}',
                  Icons.inventory_2_rounded,
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Envoyés',
                  '$sent',
                  Icons.upload_rounded,
                  AppTheme.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Reçus',
                  '$received',
                  Icons.download_rounded,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Livrés',
                  '$delivered',
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'En Attente',
                  '$pending',
                  Icons.hourglass_empty_rounded,
                  AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Revenus',
                  '${totalRevenue.toStringAsFixed(0)} CFA',
                  Icons.payments_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Taux Livraison',
                  parcels.isEmpty
                      ? '0%'
                      : '${(delivered / parcels.length * 100).toStringAsFixed(1)}%',
                  Icons.trending_up_rounded,
                  AppTheme.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  _isBoss ? 'Bureaux Actifs' : 'Mon Bureau',
                  _isBoss
                      ? '${widget.offices.length}'
                      : _getOfficeName(_currentOfficeId),
                  Icons.business_rounded,
                  AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Status Distribution
          _buildSectionTitle('Répartition par Statut'),
          const SizedBox(height: 16),
          _buildStatusDistribution(parcels),
          const SizedBox(height: 32),
          // Recent Activity
          _buildSectionTitle('Activité Récente'),
          const SizedBox(height: 16),
          _buildRecentActivity(parcels),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildStatusDistribution(List<Parcel> parcels) {
    final statusCounts = <ParcelStatus, int>{};
    for (final p in parcels) {
      statusCounts[p.status] = (statusCounts[p.status] ?? 0) + 1;
    }
    final statusLabels = {
      ParcelStatus.created: 'Créé',
      ParcelStatus.inTransit: 'En Transit',
      ParcelStatus.arrived: 'Arrivé',
      ParcelStatus.delivered: 'Livré',
      ParcelStatus.issue: 'Problème',
    };
    final statusColors = {
      ParcelStatus.created: AppTheme.info,
      ParcelStatus.inTransit: AppTheme.warning,
      ParcelStatus.arrived: AppTheme.primary,
      ParcelStatus.delivered: AppTheme.success,
      ParcelStatus.issue: AppTheme.error,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: statusCounts.entries.map((e) {
          final percent = parcels.isEmpty ? 0.0 : e.value / parcels.length;
          return Expanded(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          statusColors[e.key] ?? AppTheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  statusLabels[e.key] ?? e.key.name,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  '${e.value}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColors[e.key],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity(List<Parcel> parcels) {
    final recent = parcels.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: recent.isEmpty
            ? [const Center(child: Text('Aucune activité récente'))]
            : recent.map((p) => _buildActivityItem(p)).toList(),
      ),
    );
  }

  Widget _buildActivityItem(Parcel p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.id.substring(0, 8).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${p.senderName} → ${p.receiverName}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          _buildStatusBadge(p.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ParcelStatus status) {
    final colors = {
      ParcelStatus.created: AppTheme.info,
      ParcelStatus.inTransit: AppTheme.warning,
      ParcelStatus.arrived: AppTheme.primary,
      ParcelStatus.delivered: AppTheme.success,
      ParcelStatus.issue: AppTheme.error,
    };
    final labels = {
      ParcelStatus.created: 'Créé',
      ParcelStatus.inTransit: 'Transit',
      ParcelStatus.arrived: 'Arrivé',
      ParcelStatus.delivered: 'Livré',
      ParcelStatus.issue: 'Problème',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? AppTheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        labels[status] ?? status.name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors[status],
        ),
      ),
    );
  }

  String _getOfficeName(String? officeId) {
    if (officeId == null) return 'N/A';
    return widget.offices
        .firstWhere(
          (o) => o.id == officeId,
          orElse: () =>
              Office(id: '', name: 'Inconnu', country: '', countryCode: ''),
        )
        .name;
  }

  // ==================== OFFICES TAB (BOSS ONLY) ====================
  Widget _buildOfficesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance par Bureau'),
          const SizedBox(height: 16),
          ...widget.offices.map((office) => _buildOfficeCard(office)),
        ],
      ),
    );
  }

  Widget _buildOfficeCard(Office office) {
    final officeParcels = _filteredParcels
        .where(
          (p) =>
              p.originOfficeId == office.id ||
              p.destinationOfficeId == office.id,
        )
        .toList();
    final sent = officeParcels
        .where((p) => p.originOfficeId == office.id)
        .length;
    final received = officeParcels
        .where((p) => p.destinationOfficeId == office.id)
        .length;
    final delivered = officeParcels
        .where((p) => p.status == ParcelStatus.delivered)
        .length;
    final revenue = officeParcels.fold<double>(0, (sum, p) => sum + p.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  office.countryCode,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      office.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      office.country,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${officeParcels.length} colis',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Envoyés',
                  '$sent',
                  Icons.upload_rounded,
                  AppTheme.info,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Reçus',
                  '$received',
                  Icons.download_rounded,
                  AppTheme.primary,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Livrés',
                  '$delivered',
                  Icons.check_circle_rounded,
                  AppTheme.success,
                ),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Revenus',
                  '${revenue.toStringAsFixed(0)} CFA',
                  Icons.payments_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ==================== FLOWS TAB (BOSS ONLY) ====================
  Widget _buildFlowsTab() {
    // Calculate flows between offices
    final flows = <String, int>{};
    for (final p in _filteredParcels) {
      if (p.originOfficeId != null && p.destinationOfficeId != null) {
        final key = '${p.originOfficeId}→${p.destinationOfficeId}';
        flows[key] = (flows[key] ?? 0) + 1;
      }
    }
    final sortedFlows = flows.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Flux Inter-Bureaux'),
          const SizedBox(height: 8),
          Text(
            'Analyse des échanges de colis entre bureaux',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: sortedFlows.isEmpty
                  ? [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Aucun flux enregistré'),
                        ),
                      ),
                    ]
                  : sortedFlows
                        .take(10)
                        .map(
                          (e) => _buildFlowItem(
                            e.key,
                            e.value,
                            _filteredParcels.length,
                          ),
                        )
                        .toList(),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Matrice des Échanges'),
          const SizedBox(height: 16),
          _buildFlowMatrix(),
        ],
      ),
    );
  }

  Widget _buildFlowItem(String flowKey, int count, int total) {
    final parts = flowKey.split('→');
    final originName = _getOfficeName(parts[0]);
    final destName = _getOfficeName(parts[1]);
    final percent = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    originName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.info,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    destName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            ' (${(percent * 100).toStringAsFixed(1)}%)',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowMatrix() {
    if (widget.offices.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(
              label: Text(
                'De \\ Vers',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...widget.offices.map(
              (o) => DataColumn(
                label: Text(
                  o.name.length > 10 ? '${o.name.substring(0, 10)}...' : o.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          rows: widget.offices.map((origin) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    origin.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ...widget.offices.map((dest) {
                  final count = _filteredParcels
                      .where(
                        (p) =>
                            p.originOfficeId == origin.id &&
                            p.destinationOfficeId == dest.id,
                      )
                      .length;
                  return DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: count > 0
                            ? AppTheme.primary.withValues(
                                alpha: 0.1 + (count / 20).clamp(0, 0.4),
                              )
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontWeight: count > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: count > 0 ? AppTheme.primary : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== PERFORMANCE TAB ====================
  Widget _buildPerformanceTab() {
    final parcels = _officeParcels;
    final delivered = parcels
        .where((p) => p.status == ParcelStatus.delivered)
        .length;
    final totalPaid = parcels.where((p) => p.isPaid).length;
    final avgPrice = parcels.isEmpty
        ? 0.0
        : parcels.fold<double>(0, (s, p) => s + p.price) / parcels.length;

    // Group by day for trend
    final dailyCounts = <String, int>{};
    for (final p in parcels) {
      final day = '${p.createdAt.day}/${p.createdAt.month}';
      dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Indicateurs de Performance'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Taux de Livraison',
                  parcels.isEmpty
                      ? '0%'
                      : '${(delivered / parcels.length * 100).toStringAsFixed(1)}%',
                  Icons.local_shipping_rounded,
                  AppTheme.success,
                  parcels.isEmpty ? 0 : delivered / parcels.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Taux de Paiement',
                  parcels.isEmpty
                      ? '0%'
                      : '${(totalPaid / parcels.length * 100).toStringAsFixed(1)}%',
                  Icons.payments_rounded,
                  const Color(0xFF8B5CF6),
                  parcels.isEmpty ? 0 : totalPaid / parcels.length,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceCard(
                  'Prix Moyen',
                  '${avgPrice.toStringAsFixed(0)} CFA',
                  Icons.analytics_rounded,
                  AppTheme.info,
                  0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Tendance Journalière'),
          const SizedBox(height: 16),
          _buildDailyTrend(dailyCounts),
          const SizedBox(height: 32),
          _buildSectionTitle('Top Destinations'),
          const SizedBox(height: 16),
          _buildTopDestinations(parcels),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTrend(Map<String, int> dailyCounts) {
    final entries = dailyCounts.entries.toList();
    final maxCount = entries.isEmpty
        ? 1
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      height: 250,
      child: entries.isEmpty
          ? const Center(child: Text('Aucune donnée disponible'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight =
                    constraints.maxHeight - 60; // Espace pour textes
                final barEntries = entries.take(14).toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: barEntries.asMap().entries.map((entry) {
                    final e = entry.value;
                    final barHeight = maxCount > 0
                        ? (e.value / maxCount) * availableHeight * 0.8
                        : 0.0;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: barHeight.clamp(
                                4.0,
                                availableHeight * 0.8,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildTopDestinations(List<Parcel> parcels) {
    final destCounts = <String, int>{};
    for (final p in parcels) {
      destCounts[p.destination] = (destCounts[p.destination] ?? 0) + 1;
    }
    final sorted = destCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: sorted.isEmpty
            ? [const Center(child: Text('Aucune destination'))]
            : sorted.take(5).map((e) {
                final percent = parcels.isEmpty
                    ? 0.0
                    : e.value / parcels.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${e.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${(percent * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }
}
