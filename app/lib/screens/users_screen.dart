import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/office.dart';
import '../theme/app_theme.dart';

class UsersScreen extends StatefulWidget {
  final List<User> users;
  final List<Office> offices;
  final bool isLoading;
  final Set<String> onlineUserIds;
  final VoidCallback onRefresh;

  const UsersScreen({
    super.key,
    required this.users,
    required this.offices,
    required this.isLoading,
    required this.onlineUserIds,
    required this.onRefresh,
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String? _selectedOfficeId;

  List<User> get _filteredUsers {
    if (_selectedOfficeId == null) {
      return widget.users;
    }
    return widget.users.where((u) => u.officeId == _selectedOfficeId).toList();
  }

  String _getOfficeName(String? officeId) {
    if (officeId == null) return 'Non assigné';
    final office = widget.offices.where((o) => o.id == officeId).firstOrNull;
    return office?.name ?? 'Bureau inconnu';
  }

  @override
  Widget build(BuildContext context) {
    final agents = _filteredUsers.where((u) => u.role == 'agent').toList();
    final bosses = _filteredUsers.where((u) => u.role == 'boss').toList();
    final onlineCount = widget.onlineUserIds.length;
    final totalCount = widget.users.length;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Icon(Icons.people_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Utilisateurs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              // Online status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$onlineCount / $totalCount en ligne',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Office filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedOfficeId,
                    hint: const Text('Tous les bureaux'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tous les bureaux'),
                      ),
                      ...widget.offices.map(
                        (office) => DropdownMenuItem(
                          value: office.id,
                          child: Text(office.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedOfficeId = value);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Refresh button
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),

        // Users list
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
              ? _buildEmptyState()
              : _buildUsersList(agents, bosses),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> agents, List<User> bosses) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (bosses.isNotEmpty) ...[
          _buildSectionHeader(
            'Superviseurs',
            bosses.length,
            Icons.admin_panel_settings_rounded,
          ),
          const SizedBox(height: 12),
          ...bosses.map((user) => _buildUserCard(user)),
          const SizedBox(height: 24),
        ],
        if (agents.isNotEmpty) ...[
          _buildSectionHeader(
            'Agents',
            agents.length,
            Icons.support_agent_rounded,
          ),
          const SizedBox(height: 12),
          ...agents.map((user) => _buildUserCard(user)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(User user) {
    final isOnline = widget.onlineUserIds.contains(user.id);
    final officeName = _getOfficeName(user.officeId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? AppTheme.success.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isOnline ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: user.role == 'boss'
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : AppTheme.info.withValues(alpha: 0.1),
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: user.role == 'boss'
                        ? AppTheme.primary
                        : AppTheme.info,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isOnline ? AppTheme.success : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (user.role == 'boss') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BOSS',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (user.role == 'agent')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_rounded, size: 14, color: AppTheme.info),
                  const SizedBox(width: 4),
                  Text(
                    officeName,
                    style: TextStyle(
                      color: AppTheme.info,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOnline ? 'En ligne' : 'Hors ligne',
              style: TextStyle(
                color: isOnline ? AppTheme.success : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
