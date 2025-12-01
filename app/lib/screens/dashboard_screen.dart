import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chart.dart';

class DashboardScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final bool isLoading;

  const DashboardScreen({
    super.key,
    required this.parcels,
    required this.isLoading,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'all';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String? _selectedOfficeId; // null = tous les bureaux
  String? _selectedOfficeName; // Nom du bureau sélectionné pour l'affichage

  bool get _isBoss => AuthService.currentUser?.role == 'boss';

  Future<void> _showOfficeSelector() async {
    // Charger les bureaux seulement quand on ouvre le modal
    List<Office> offices = [];
    bool isLoading = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Charger les bureaux au premier build
            if (isLoading) {
              ApiService.fetchOffices()
                  .then((data) {
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
                    onPressed: () => Navigator.of(context).pop(),
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
                              context,
                              null,
                              '🌍 Tous les bureaux',
                            ),
                            const Divider(),
                            ...offices.map(
                              (office) => _buildOfficeOption(
                                context,
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
    BuildContext context,
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
          _selectedOfficeName = office?.name;
        });
        Navigator.of(context).pop();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: const Color(0xFF9C27B0).withValues(alpha: 0.1),
    );
  }

  List<Parcel> get _filteredParcels {
    final now = DateTime.now();

    // D'abord filtrer par bureau si un bureau est sélectionné
    var parcels = widget.parcels;
    if (_selectedOfficeId != null && _isBoss) {
      parcels = parcels
          .where(
            (p) =>
                p.originOfficeId == _selectedOfficeId ||
                p.destinationOfficeId == _selectedOfficeId,
          )
          .toList();
    }

    // Ensuite filtrer par période
    switch (_selectedPeriod) {
      case 'today':
        return parcels.where((p) {
          final date = p.createdAt;
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();

      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return parcels.where((p) {
          return p.createdAt.isAfter(
                weekStart.subtract(const Duration(days: 1)),
              ) &&
              p.createdAt.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();

      case 'month':
        return parcels.where((p) {
          return p.createdAt.year == now.year && p.createdAt.month == now.month;
        }).toList();

      case 'custom':
        if (_customStartDate == null || _customEndDate == null) {
          return parcels;
        }
        return parcels.where((p) {
          return p.createdAt.isAfter(
                _customStartDate!.subtract(const Duration(days: 1)),
              ) &&
              p.createdAt.isBefore(
                _customEndDate!.add(const Duration(days: 1)),
              );
        }).toList();

      default:
        return parcels;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcels = _filteredParcels;
    final totalRevenue = _calculateTotalRevenue(parcels);
    final paidRevenue = _calculatePaidRevenue(parcels);
    final unpaidRevenue = _calculateUnpaidRevenue(parcels);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Vue d\'ensemble'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {},
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.borderRadiusSmall,
                    boxShadow: AppTheme.glowShadow(AppTheme.primary),
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, Boss',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Voici un aperçu de votre activité',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Filters Row: Period (left) and Office Selector (right)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Filter (left side)
                Expanded(
                  flex: _isBoss ? 3 : 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: Color(0xFF0066CC),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Période',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const Spacer(),
                            if (_selectedPeriod == 'custom' &&
                                _customStartDate != null &&
                                _customEndDate != null)
                              Text(
                                '${DateFormat('dd/MM/yy').format(_customStartDate!)} - ${DateFormat('dd/MM/yy').format(_customEndDate!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPeriodChip(
                              'Tout',
                              'all',
                              Icons.all_inclusive_rounded,
                            ),
                            _buildPeriodChip(
                              'Aujourd\'hui',
                              'today',
                              Icons.today_rounded,
                            ),
                            _buildPeriodChip(
                              'Cette Semaine',
                              'week',
                              Icons.date_range_rounded,
                            ),
                            _buildPeriodChip(
                              'Ce Mois',
                              'month',
                              Icons.calendar_month_rounded,
                            ),
                            _buildPeriodChip(
                              'Personnalisé',
                              'custom',
                              Icons.tune_rounded,
                            ),
                          ],
                        ),
                        if (_selectedPeriod == 'custom') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _customStartDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _customStartDate = date);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _customStartDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_customStartDate!)
                                        : 'Date Début',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _customEndDate ?? DateTime.now(),
                                      firstDate:
                                          _customStartDate ?? DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _customEndDate = date);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.event_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _customEndDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_customEndDate!)
                                        : 'Date Fin',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Office Selector (right side) - Only for Boss
                if (_isBoss) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.business_rounded,
                                size: 20,
                                color: Color(0xFF9C27B0),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Bureau',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const Spacer(),
                              if (_selectedOfficeId != null)
                                TextButton(
                                  onPressed: () {
                                    setState(() => _selectedOfficeId = null);
                                  },
                                  child: const Text(
                                    'Réinitialiser',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingOffices)
                            const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildOfficeChip(null, '🌍 Tous'),
                                ..._offices.map(
                                  (office) => _buildOfficeChip(
                                    office.id,
                                    '${office.flag} ${office.name}',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            if (widget.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  // Stats Cards Row 1
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Colis',
                          value: parcels.length.toString(),
                          icon: Icons.inventory_2_rounded,
                          gradient: AppTheme.primaryGradient,
                          subtitle: 'Tous statuts',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'En Transit',
                          value: parcels
                              .where((p) => p.status == ParcelStatus.inTransit)
                              .length
                              .toString(),
                          icon: Icons.local_shipping_rounded,
                          gradient: AppTheme.infoGradient,
                          subtitle: 'En cours',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Livrés',
                          value: parcels
                              .where((p) => p.status == ParcelStatus.delivered)
                              .length
                              .toString(),
                          icon: Icons.check_circle_rounded,
                          gradient: AppTheme.successGradient,
                          subtitle: 'Terminés',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Problèmes',
                          value: parcels
                              .where((p) => p.status == ParcelStatus.issue)
                              .length
                              .toString(),
                          icon: Icons.warning_rounded,
                          gradient: AppTheme.warningGradient,
                          subtitle: 'Attention',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Revenue Statistics Row 2
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Chiffre d\'Affaires',
                          value: totalRevenue,
                          icon: Icons.account_balance_wallet_rounded,
                          gradient: AppTheme.successGradient,
                          subtitle: 'Total',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Montant Payé',
                          value: paidRevenue,
                          icon: Icons.check_circle_rounded,
                          gradient: AppTheme.infoGradient,
                          subtitle:
                              '${_calculatePaidPercentage(parcels)}% du total',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Montant Impayé',
                          value: unpaidRevenue,
                          icon: Icons.pending_rounded,
                          gradient: AppTheme.warningGradient,
                          subtitle:
                              '${parcels.where((p) => !p.isPaid).length} colis',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Status Chart
            StatusChart(parcels: parcels),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activité Récente',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Voir tout'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: parcels.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun colis pour cette période',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: parcels.take(5).length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final parcel = parcels[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                parcel.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: _getStatusColor(parcel.status),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            parcel.receiverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${parcel.destination} • ${_getStatusLabel(parcel.status)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                parcel.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(parcel.status),
                              style: TextStyle(
                                color: _getStatusColor(parcel.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = value);
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

  Widget _buildOfficeChip(String? officeId, String label) {
    final isSelected = _selectedOfficeId == officeId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedOfficeId = officeId);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF9C27B0).withValues(alpha: 0.15),
      checkmarkColor: const Color(0xFF9C27B0),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF9C27B0) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  String _calculateTotalRevenue(List<Parcel> parcels) {
    final total = parcels.fold<double>(0, (sum, p) => sum + p.price);
    return '${total.toStringAsFixed(0)} FCFA';
  }

  String _calculatePaidRevenue(List<Parcel> parcels) {
    final paid = parcels
        .where((p) => p.isPaid)
        .fold<double>(0, (sum, p) => sum + p.price);
    return '${paid.toStringAsFixed(0)} FCFA';
  }

  String _calculateUnpaidRevenue(List<Parcel> parcels) {
    final unpaid = parcels
        .where((p) => !p.isPaid)
        .fold<double>(0, (sum, p) => sum + p.price);
    return '${unpaid.toStringAsFixed(0)} FCFA';
  }

  int _calculatePaidPercentage(List<Parcel> parcels) {
    if (parcels.isEmpty) return 0;
    final paidCount = parcels.where((p) => p.isPaid).length;
    return ((paidCount / parcels.length) * 100).round();
  }
}
