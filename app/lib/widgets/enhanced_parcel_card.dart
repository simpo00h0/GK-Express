import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../models/office.dart';
import '../theme/app_theme.dart';
import '../utils/status_utils.dart';

enum ParcelViewType { sent, received, all }

class EnhancedParcelCard extends StatefulWidget {
  final Parcel parcel;
  final VoidCallback onTap;
  final List<Office>? offices;
  final ParcelViewType viewType;

  const EnhancedParcelCard({
    super.key,
    required this.parcel,
    required this.onTap,
    this.offices,
    this.viewType = ParcelViewType.all,
  });

  @override
  State<EnhancedParcelCard> createState() => _EnhancedParcelCardState();
}

class _EnhancedParcelCardState extends State<EnhancedParcelCard> {
  bool _isHovered = false;

  String _getOfficeName(String? officeId) {
    if (officeId == null || widget.offices == null) return '';
    final office = widget.offices!.where((o) => o.id == officeId).firstOrNull;
    return office?.name ?? '';
  }

  // Affiche "Envoyé par [bureau]" ou "Envoyé au [bureau]"
  String get _officeLabel {
    if (widget.viewType == ParcelViewType.received) {
      // Onglet Colis Reçus - afficher le bureau d'origine
      final originName = _getOfficeName(widget.parcel.originOfficeId);
      return originName.isNotEmpty ? 'Envoyé par $originName' : '';
    } else if (widget.viewType == ParcelViewType.sent) {
      // Onglet Colis Envoyés - afficher le bureau de destination
      final destName = _getOfficeName(widget.parcel.destinationOfficeId);
      return destName.isNotEmpty ? 'Envoyé au $destName' : '';
    }
    return '';
  }

  Color get _officeLabelColor {
    if (widget.viewType == ParcelViewType.received) {
      return AppTheme.success;
    } else if (widget.viewType == ParcelViewType.sent) {
      return AppTheme.info;
    }
    return AppTheme.textSecondary;
  }

  IconData get _officeLabelIcon {
    if (widget.viewType == ParcelViewType.received) {
      return Icons.arrow_downward_rounded;
    } else if (widget.viewType == ParcelViewType.sent) {
      return Icons.arrow_upward_rounded;
    }
    return Icons.swap_horiz_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusUtils.getStatusColor(widget.parcel.status.name);
    final statusLabel = StatusUtils.getStatusLabel(widget.parcel.status.name);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Transform.translate(
        offset: Offset(0.0, _isHovered ? -4.0 : 0.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150), // Plus rapide
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.borderRadius,
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : AppTheme.divider,
              width: 1,
            ),
            boxShadow: _isHovered
                ? AppTheme.elevatedShadow
                : AppTheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: AppTheme.borderRadius,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: AppTheme.borderRadiusSmall,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Office Badge (pour Boss et Agents)
                        if (_officeLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _officeLabelColor.withValues(alpha: 0.1),
                              borderRadius: AppTheme.borderRadiusSmall,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _officeLabelIcon,
                                  size: 14,
                                  color: _officeLabelColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _officeLabel,
                                  style: TextStyle(
                                    color: _officeLabelColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Parcel ID
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.parcel.id.substring(0, 8).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sender & Receiver
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoColumn(
                            icon: Icons.person_outline_rounded,
                            label: 'Expéditeur',
                            value: widget.parcel.senderName,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppTheme.divider,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            icon: Icons.person_rounded,
                            label: 'Destinataire',
                            value: widget.parcel.receiverName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Destination & Date
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.location_on_outlined,
                            text: widget.parcel.destination,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildInfoRow(
                          icon: Icons.calendar_today_rounded,
                          text: DateFormat(
                            'dd/MM/yy',
                          ).format(widget.parcel.createdAt),
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Price & Payment Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: AppTheme.borderRadiusSmall,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.attach_money_rounded,
                                size: 16,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.parcel.price.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.parcel.isPaid
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : AppTheme.warning.withValues(alpha: 0.1),
                            borderRadius: AppTheme.borderRadiusSmall,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.parcel.isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_rounded,
                                size: 16,
                                color: widget.parcel.isPaid
                                    ? AppTheme.success
                                    : AppTheme.warning,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.parcel.isPaid ? 'Payé' : 'Impayé',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: widget.parcel.isPaid
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
