import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Function() onLogout;
  final bool isBoss;

  const ModernSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
    this.isBoss = false,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  int? _hoveredIndex;
  bool _colisExpanded = false;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Tableau de bord',
      index: 0,
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Colis',
      index: -1, // Parent item, no direct index
      hasChildren: true,
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
      index: 4,
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Utilisateurs',
      index: 5,
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Paramètres',
      index: 6,
    ),
  ];

  final List<_NavItem> _colisSubItems = [
    _NavItem(
      icon: Icons.upload_outlined,
      selectedIcon: Icons.upload_rounded,
      label: 'Envoyés',
      index: 1,
    ),
    _NavItem(
      icon: Icons.download_outlined,
      selectedIcon: Icons.download_rounded,
      label: 'Reçus',
      index: 2,
    ),
    _NavItem(
      icon: Icons.all_inclusive_rounded,
      selectedIcon: Icons.all_inclusive_rounded,
      label: 'Tous les colis',
      index: 3,
    ),
  ];

  bool _isColisChildSelected() {
    return _colisSubItems.any((item) => item.index == widget.selectedIndex);
  }

  Widget _buildNavItem(_NavItem item, int listIndex) {
    final isSelected = item.hasChildren
        ? _isColisChildSelected()
        : widget.selectedIndex == item.index;
    final isHovered = _hoveredIndex == listIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = listIndex),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: AppTheme.animationDuration,
          curve: AppTheme.animationCurve,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : isHovered
                ? AppTheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: AppTheme.borderRadiusSmall,
            border: Border(
              left: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (item.hasChildren) {
                  setState(() => _colisExpanded = !_colisExpanded);
                } else {
                  widget.onDestinationSelected(item.index);
                }
              },
              borderRadius: AppTheme.borderRadiusSmall,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    AnimatedScale(
                      duration: AppTheme.animationDuration,
                      scale: isSelected || isHovered ? 1.1 : 1.0,
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (item.hasChildren)
                      AnimatedRotation(
                        duration: AppTheme.animationDuration,
                        turns: _colisExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.expand_more,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      )
                    else if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
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

  Widget _buildSubNavItem(_NavItem item) {
    final isSelected = widget.selectedIndex == item.index;
    final isHovered = _hoveredIndex == (100 + item.index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 20),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = 100 + item.index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: AppTheme.animationDuration,
          curve: AppTheme.animationCurve,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.1)
                : isHovered
                ? AppTheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onDestinationSelected(item.index),
              borderRadius: AppTheme.borderRadiusSmall,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header - GK Express
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Speedometer circle with G and K
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CustomPaint(painter: _GKLogoPainter()),
                    ),
                    const SizedBox(width: 4),
                    // EXpress text
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'EX',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE53935),
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'press',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A1A),
                                height: 1.0,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'DELIVERY',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE53935),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Slogan
                const Text(
                  'Simple, rapide et efficace!',
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (int i = 0; i < _navItems.length; i++) ...[
                  // Hide "Utilisateurs" (index 5) for non-boss users
                  if (_navItems[i].index == 5 && !widget.isBoss)
                    const SizedBox.shrink()
                  else
                    _buildNavItem(_navItems[i], i),
                  // Sous-menu Colis (index 1)
                  if (i == 1 && _colisExpanded)
                    ..._colisSubItems.map(
                      (subItem) => _buildSubNavItem(subItem),
                    ),
                ],
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = -1),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: AppTheme.animationDuration,
                decoration: BoxDecoration(
                  color: _hoveredIndex == -1
                      ? AppTheme.error.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onLogout,
                    borderRadius: AppTheme.borderRadiusSmall,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: _hoveredIndex == -1
                                ? AppTheme.error
                                : AppTheme.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Déconnexion',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _hoveredIndex == -1
                                  ? AppTheme.error
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  final bool hasChildren;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
    this.hasChildren = false,
  });
}

// Custom painter for GK Express logo (speedometer with G and K)
class _GKLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Arc paint (black thick arc)
    final arcPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw the speedometer arc (from 150° to 30°, leaving gap at bottom)
    const startAngle = 2.4; // ~137 degrees in radians
    const sweepAngle = 4.0; // ~230 degrees sweep
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw small tick marks on the arc
    final tickPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i <= 4; i++) {
      final angle = startAngle + (sweepAngle * i / 4);
      final outerPoint = Offset(
        center.dx + radius * 0.95 * cos(angle),
        center.dy + radius * 0.95 * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + radius * 0.75 * cos(angle),
        center.dy + radius * 0.75 * sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // Draw "G" in red
    final gTextPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFFE53935),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    gTextPainter.layout();
    gTextPainter.paint(canvas, Offset(center.dx - 12, center.dy - 10));

    // Draw "K" in black
    final kTextPainter = TextPainter(
      text: const TextSpan(
        text: 'K',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1A1A1A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    kTextPainter.layout();
    kTextPainter.paint(canvas, Offset(center.dx, center.dy - 2));

    // Draw needle/accent line (red diagonal)
    final needlePaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 6, center.dy + 8),
      Offset(center.dx + 6, center.dy - 4),
      needlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper for math functions
double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);
