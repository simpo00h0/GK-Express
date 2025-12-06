import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../models/parcel_status_history.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../services/history_cache_service.dart';
import '../widgets/status_timeline.dart';
import 'update_status_screen.dart';

class ParcelDetailScreen extends StatefulWidget {
  final Parcel parcel;
  final Function() onStatusUpdated;

  const ParcelDetailScreen({
    super.key,
    required this.parcel,
    required this.onStatusUpdated,
  });

  @override
  State<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends State<ParcelDetailScreen> {
  List<ParcelStatusHistory> _history = [];
  bool _isLoadingHistory = true;
  Parcel? _currentParcel; // Parcel actuel (peut être mis à jour)

  @override
  void initState() {
    super.initState();
    _currentParcel = widget.parcel;
    // Load history lazily - only when user scrolls to it
    // This improves initial page load performance
    _loadHistory(forceRefresh: false);
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      // Load cache asynchronously to not block UI
      HistoryCacheService.getCachedHistory(widget.parcel.id).then((cachedHistory) {
        if (cachedHistory != null && cachedHistory.isNotEmpty && mounted) {
          setState(() {
            _history = cachedHistory;
            _isLoadingHistory = false;
          });
          // Load in background to update cache (non-blocking)
          _loadHistoryFromApi();
        } else {
          // No cache, load from API
          _loadHistoryFromApi();
        }
      });
      return;
    }

    // Force refresh, load from API
    await _loadHistoryFromApi();
  }

  Future<void> _loadHistoryFromApi() async {
    if (!mounted) return;
    
    setState(() => _isLoadingHistory = true);
    try {
      final history = await ApiService.fetchParcelStatusHistory(widget.parcel.id);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
        // Update cache
        await HistoryCacheService.cacheHistory(widget.parcel.id, history);
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _reloadParcel() async {
    try {
      // Recharger uniquement ce colis (beaucoup plus rapide)
      final updatedParcel = await ApiService.fetchParcelById(widget.parcel.id);
      if (updatedParcel != null && mounted) {
        setState(() {
          _currentParcel = updatedParcel;
        });
        // Recharger l'historique avec force refresh pour avoir les dernières données
        await _loadHistory(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Error reloading parcel: $e');
    }
  }

  @override
  void didUpdateWidget(ParcelDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if parcel ID changed, not on every rebuild
    if (oldWidget.parcel.id != widget.parcel.id) {
      _currentParcel = widget.parcel;
      _loadHistory(forceRefresh: false); // Use cache if available
    }
  }

  // Générer les données du QR code avec informations lisibles
  String _generateQrData() {
    final parcel = _currentParcel ?? widget.parcel;
    final shortId = parcel.id.substring(0, 8).toUpperCase();
    final statusText = _getStatusText(parcel.status);
    final paymentStatus = parcel.isPaid ? 'Payé ✅' : 'Non payé ❌';
    final date = DateFormat('dd/MM/yyyy HH:mm').format(parcel.createdAt);

    return '''📦 GK EXPRESS - Colis #$shortId
━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 Expediteur: ${parcel.senderName}
   Tel: ${parcel.senderPhone}

📥 Destinataire: ${parcel.receiverName}
   Tel: ${parcel.receiverPhone}

📍 Destination: ${parcel.destination}
📊 Statut: $statusText
💰 Prix: ${parcel.price.toStringAsFixed(0)} CFA ($paymentStatus)
📅 Cree le: $date
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 Suivi en ligne:
   gkexpress.com/track/$shortId

📄 Telecharger PDF:
   gkexpress.com/pdf/$shortId''';
  }

  String _getStatusText(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return '🆕 Créé';
      case ParcelStatus.inTransit:
        return '🚚 En Transit';
      case ParcelStatus.arrived:
        return '📍 Arrivé';
      case ParcelStatus.delivered:
        return '✅ Livré';
      case ParcelStatus.issue:
        return '⚠️ Problème';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Détails du Colis'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateStatusScreen(
                      parcel: _currentParcel ?? widget.parcel,
                      onStatusUpdated: () async {
                        // Recharger le colis et l'historique
                        await _reloadParcel();
                        // Notifier le parent pour rafraîchir la liste
                        widget.onStatusUpdated();
                      },
                    ),
                  ),
                );
                
                // Only reload if status was actually updated (result indicates success)
                // Don't reload on simple back navigation
                if (mounted && result == true) {
                  await _loadHistory(forceRefresh: true);
                }
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Modifier Statut'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // QR Code Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: _generateQrData(),
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ID: ${(_currentParcel ?? widget.parcel).id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // PDF Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            PdfService.generateAndOpenPdf(_currentParcel ?? widget.parcel, context),
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                        label: const Text('Ouvrir PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => PdfService.generateAndPrintParcelPdf(
                          _currentParcel ?? widget.parcel,
                          context,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Imprimer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9C27B0),
                          side: const BorderSide(color: Color(0xFF9C27B0)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor((_currentParcel ?? widget.parcel).status),
                    _getStatusColor((_currentParcel ?? widget.parcel).status).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(
                      (_currentParcel ?? widget.parcel).status,
                    ).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon((_currentParcel ?? widget.parcel).status),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statut Actuel',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel((_currentParcel ?? widget.parcel).status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Details Cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Expéditeur',
                    (_currentParcel ?? widget.parcel).senderName,
                    (_currentParcel ?? widget.parcel).senderPhone,
                    Icons.person_outline_rounded,
                    const Color(0xFF667EEA),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(
                    'Destinataire',
                    (_currentParcel ?? widget.parcel).receiverName,
                    (_currentParcel ?? widget.parcel).receiverPhone,
                    Icons.person_rounded,
                    const Color(0xFFF093FB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Destination',
              (_currentParcel ?? widget.parcel).destination,
              DateFormat('dd/MM/yyyy HH:mm').format((_currentParcel ?? widget.parcel).createdAt),
              Icons.location_on_rounded,
              const Color(0xFF4FACFE),
            ),
            const SizedBox(height: 24),

            // Status History Timeline
            StatusTimeline(
              history: _history,
              isLoading: _isLoadingHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
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

  IconData _getStatusIcon(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.created:
        return Icons.fiber_new_rounded;
      case ParcelStatus.inTransit:
        return Icons.local_shipping_rounded;
      case ParcelStatus.arrived:
        return Icons.location_on_rounded;
      case ParcelStatus.delivered:
        return Icons.check_circle_rounded;
      case ParcelStatus.issue:
        return Icons.warning_rounded;
    }
  }
}
