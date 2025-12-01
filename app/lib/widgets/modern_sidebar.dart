import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Function() onLogout;

  const ModernSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
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
          // Logo Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.borderRadiusSmall,
                    boxShadow: AppTheme.glowShadow(AppTheme.primary),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GK Express',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Transit International',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
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
