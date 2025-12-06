import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/office.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';
import 'create_message_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Message> _receivedMessages = [];
  List<Message> _sentMessages = [];
  List<Office> _offices = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  String? _selectedOfficeId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSocketListener();
    _startPeriodicRefresh();
  }

  void _setupSocketListener() {
    SocketService.onNewMessage((data) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [received, sent, offices, unreadCount] = await Future.wait([
        ApiService.fetchReceivedMessages(),
        ApiService.fetchSentMessages(),
        ApiService.fetchOffices(),
        ApiService.getUnreadMessageCount(),
      ]);

      setState(() {
        _receivedMessages = received as List<Message>;
        _sentMessages = sent as List<Message>;
        _offices = offices as List<Office>;
        _unreadCount = unreadCount as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadData();
        _startPeriodicRefresh();
      }
    });
  }

  // Grouper les messages par bureau pour créer des conversations
  Map<String, ConversationData> _getConversations() {
    final Map<String, ConversationData> conversations = {};

    // Traiter les messages reçus
    for (final message in _receivedMessages) {
      final officeId = message.fromOfficeId;
      if (!conversations.containsKey(officeId)) {
        conversations[officeId] = ConversationData(
          officeId: officeId,
          officeName: _getOfficeName(officeId),
          office: _getOffice(officeId),
          messages: [],
          unreadCount: 0,
        );
      }
      conversations[officeId]!.messages.add(message);
      if (!message.isRead) {
        conversations[officeId]!.unreadCount++;
      }
    }

    // Traiter les messages envoyés
    for (final message in _sentMessages) {
      final officeId = message.toOfficeId;
      if (!conversations.containsKey(officeId)) {
        conversations[officeId] = ConversationData(
          officeId: officeId,
          officeName: _getOfficeName(officeId),
          office: _getOffice(officeId),
          messages: [],
          unreadCount: 0,
        );
      }
      conversations[officeId]!.messages.add(message);
    }

    // Trier les messages de chaque conversation
    for (final conv in conversations.values) {
      conv.messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return conversations;
  }

  String _getOfficeName(String officeId) {
    final office = _offices.firstWhere(
      (o) => o.id == officeId,
      orElse: () => Office(
        id: officeId,
        name: 'Bureau inconnu',
        country: '',
        countryCode: '',
      ),
    );
    return office.name;
  }

  Office? _getOffice(String officeId) {
    try {
      return _offices.firstWhere((o) => o.id == officeId);
    } catch (e) {
      return null;
    }
  }

  List<ConversationData> _getFilteredConversations() {
    final conversations = _getConversations().values.toList();
    
    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      return conversations.where((conv) {
        return conv.officeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               conv.messages.any((msg) => 
                 msg.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 msg.content.toLowerCase().contains(_searchQuery.toLowerCase())
               );
      }).toList();
    }

    // Trier par dernière activité
    conversations.sort((a, b) {
      final aLastMessage = a.messages.isNotEmpty ? a.messages.first.createdAt : DateTime(1970);
      final bLastMessage = b.messages.isNotEmpty ? b.messages.first.createdAt : DateTime(1970);
      return bLastMessage.compareTo(aLastMessage);
    });

    return conversations;
  }

  @override
  Widget build(BuildContext context) {
    final conversations = _getFilteredConversations();
    final selectedConversation = _selectedOfficeId != null
        ? conversations.firstWhere(
            (c) => c.officeId == _selectedOfficeId,
            orElse: () => conversations.isNotEmpty ? conversations.first : ConversationData(
              officeId: '',
              officeName: '',
              messages: [],
              unreadCount: 0,
            ),
          )
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          // Sidebar des conversations
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // En-tête avec recherche
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Messages',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (_unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher une conversation...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ],
                  ),
                ),
                // Liste des conversations
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : conversations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune conversation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Commencez une nouvelle conversation',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                itemCount: conversations.length,
                                itemBuilder: (context, index) {
                                  final conv = conversations[index];
                                  final isSelected = conv.officeId == _selectedOfficeId;
                                  final lastMessage = conv.messages.isNotEmpty
                                      ? conv.messages.first
                                      : null;

                                  return InkWell(
                                    onTap: () {
                                      setState(() => _selectedOfficeId = conv.officeId);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primary.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        border: Border(
                                          left: BorderSide(
                                            color: isSelected
                                                ? AppTheme.primary
                                                : Colors.transparent,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                conv.office?.flag ?? '🏢',
                                                style: const TextStyle(fontSize: 24),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Contenu
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        conv.officeName,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: conv.unreadCount > 0
                                                              ? FontWeight.bold
                                                              : FontWeight.w600,
                                                          color: AppTheme.textPrimary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (lastMessage != null)
                                                      Text(
                                                        lastMessage.formattedDate,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                if (lastMessage != null)
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          lastMessage.content,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: conv.unreadCount > 0
                                                                ? AppTheme.textPrimary
                                                                : Colors.grey.shade600,
                                                            fontWeight: conv.unreadCount > 0
                                                                ? FontWeight.w600
                                                                : FontWeight.normal,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (conv.unreadCount > 0)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.primary,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Text(
                                                            '${conv.unreadCount > 9 ? '9+' : conv.unreadCount}',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
                // Bouton nouveau message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateMessageScreen(offices: _offices),
                          ),
                        );
                        if (result == true && mounted) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Nouveau message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Zone principale de conversation
          Expanded(
            child: selectedConversation != null &&
                    selectedConversation.officeId.isNotEmpty
                ? ConversationScreen(
                    officeId: selectedConversation.officeId,
                    officeName: selectedConversation.officeName,
                    office: selectedConversation.office,
                    onMessageSent: () => _loadData(),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sélectionnez une conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choisissez une conversation dans la liste\npour commencer à échanger',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class ConversationData {
  final String officeId;
  final String officeName;
  final Office? office;
  final List<Message> messages;
  int unreadCount;

  ConversationData({
    required this.officeId,
    required this.officeName,
    this.office,
    required this.messages,
    required this.unreadCount,
  });
}
