import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../models/office.dart';
import '../models/client.dart';
import '../theme/app_theme.dart';

class ClientsScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final List<Office> offices;
  final bool isBoss;
  final String? currentOfficeId;

  const ClientsScreen({
    super.key,
    required this.parcels,
    required this.offices,
    this.isBoss = false,
    this.currentOfficeId,
  });

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _searchQuery = '';
  String _sortBy = 'parcels';

  List<Client> _buildClientsList() {
    var parcels = widget.parcels;
    if (!widget.isBoss && widget.currentOfficeId != null) {
      parcels = parcels
          .where((p) => p.originOfficeId == widget.currentOfficeId)
          .toList();
    }

    final Map<String, List<Parcel>> senderParcels = {};
    for (final parcel in parcels) {
      senderParcels.putIfAbsent(parcel.senderPhone, () => []).add(parcel);
    }

    final clients = <Client>[];
    for (final entry in senderParcels.entries) {
      final phone = entry.key;
      final parcelList = entry.value;
      parcelList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final name = parcelList.first.senderName;

      int paidAtSending = 0, paidAtReception = 0, unpaid = 0;
      double totalAmount = 0, paidAmount = 0;

      for (final p in parcelList) {
        totalAmount += p.price;
        if (p.isPaid) {
          paidAmount += p.price;
          if (p.paidAtOfficeId == p.originOfficeId) {
            paidAtSending++;
          } else {
            paidAtReception++;
          }
        } else {
          unpaid++;
        }
      }

      final Map<String, List<Parcel>> receiverMap = {};
      for (final p in parcelList) {
        receiverMap.putIfAbsent(p.receiverPhone, () => []).add(p);
      }

      final receivers = receiverMap.entries.map((e) {
        final rParcels = e.value
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ClientReceiver(
          name: rParcels.first.receiverName,
          phone: e.key,
          parcelCount: rParcels.length,
          totalAmount: rParcels.fold(0.0, (sum, p) => sum + p.price),
        );
      }).toList()..sort((a, b) => b.parcelCount.compareTo(a.parcelCount));

      clients.add(
        Client(
          phone: phone,
          name: name,
          totalParcels: parcelList.length,
          paidAtSending: paidAtSending,
          paidAtReception: paidAtReception,
          unpaid: unpaid,
          totalAmount: totalAmount,
          paidAmount: paidAmount,
          receivers: receivers,
          lastActivity: parcelList.first.createdAt,
        ),
      );
    }

    var filtered = clients.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();

    switch (_sortBy) {
      case 'amount':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'recent':
        filtered.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        break;
      default:
        filtered.sort((a, b) => b.totalParcels.compareTo(a.totalParcels));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final clients = _buildClientsList();
    final fmt = NumberFormat('#,###', 'fr_FR');
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Clients')),
      body: Column(
        children: [
          _buildHeader(clients.length),
          Expanded(child: _buildList(clients, fmt)),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(
                    value: 'parcels',
                    child: Text('📦 Nb Colis'),
                  ),
                  DropdownMenuItem(value: 'amount', child: Text('💰 Montant')),
                  DropdownMenuItem(value: 'name', child: Text('🔤 Nom')),
                  DropdownMenuItem(value: 'recent', child: Text('🕐 Récent')),
                ],
                onChanged: (v) => setState(() => _sortBy = v!),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$count clients',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Client> clients, NumberFormat fmt) {
    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun client trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: clients.length,
      itemBuilder: (context, index) => _buildClientCard(clients[index], fmt),
    );
  }

  Widget _buildClientCard(Client client, NumberFormat fmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client.phone, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                _stat('📦', '${client.totalParcels}', Colors.blue),
                const SizedBox(width: 8),
                _stat('✅', '${client.paidAtSending}', Colors.green),
                const SizedBox(width: 8),
                _stat('📥', '${client.paidAtReception}', Colors.orange),
                const SizedBox(width: 8),
                _stat('⏳', '${client.unpaid}', Colors.red),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${fmt.format(client.totalAmount)} CFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (client.unpaidAmount > 0)
              Text(
                'Impayé: ${fmt.format(client.unpaidAmount)} CFA',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        children: [
          const Divider(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '📍 Destinataires:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          ...client.receivers.take(5).map((r) => _receiverRow(r, fmt)),
          if (client.receivers.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${client.receivers.length - 5} autres',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String val, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$emoji $val', style: TextStyle(fontSize: 11, color: c)),
    );
  }

  Widget _receiverRow(ClientReceiver r, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              r.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            r.phone,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${r.parcelCount} colis',
              style: const TextStyle(fontSize: 11, color: Colors.blue),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${fmt.format(r.totalAmount)} CFA',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
