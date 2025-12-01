import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_service.dart';

class SocketService {
  static io.Socket? _socket;
  static bool _isConnected = false;
  static final Set<String> _onlineUserIds = {};
  static Function(Set<String>)? _onPresenceUpdate;

  static bool get isConnected => _isConnected;
  static Set<String> get onlineUserIds => Set.from(_onlineUserIds);

  // Initialize and connect to Socket.IO server
  static void connect() {
    if (_socket != null && _isConnected) {
      debugPrint('Socket already connected');
      return;
    }

    _socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      debugPrint('✅ Socket connected: ${_socket!.id}');
      _isConnected = true;

      // Join office room and register presence when connected
      final user = AuthService.currentUser;
      if (user != null) {
        if (user.officeId != null) {
          joinOfficeRoom(user.officeId!, user.id);
        }
        // Register user presence
        _socket!.emit('user_online', {'userId': user.id, 'role': user.role});
      }
    });

    _socket!.on('disconnect', (_) {
      debugPrint('❌ Socket disconnected');
      _isConnected = false;
    });

    _socket!.on('connect_error', (error) {
      debugPrint('Socket connection error: $error');
      _isConnected = false;
    });

    // Listen for presence updates
    _socket!.on('presence_update', (data) {
      if (data is Map) {
        final List<dynamic> onlineIds = data['onlineUserIds'] ?? [];
        _onlineUserIds.clear();
        _onlineUserIds.addAll(onlineIds.cast<String>());
        _onPresenceUpdate?.call(_onlineUserIds);
      }
    });

    _socket!.on('user_connected', (data) {
      if (data is Map && data['userId'] != null) {
        _onlineUserIds.add(data['userId']);
        _onPresenceUpdate?.call(_onlineUserIds);
      }
    });

    _socket!.on('user_disconnected', (data) {
      if (data is Map && data['userId'] != null) {
        _onlineUserIds.remove(data['userId']);
        _onPresenceUpdate?.call(_onlineUserIds);
      }
    });
  }

  // Set callback for presence updates
  static void onPresenceUpdate(Function(Set<String>) callback) {
    _onPresenceUpdate = callback;
  }

  // Request current online users list
  static void requestOnlineUsers() {
    if (_socket != null && _isConnected) {
      _socket!.emit('get_online_users');
    }
  }

  // Join office room
  static void joinOfficeRoom(String officeId, String userId) {
    if (_socket == null || !_isConnected) {
      debugPrint('Cannot join room: Socket not connected');
      return;
    }

    _socket!.emit('join_office', {'officeId': officeId, 'userId': userId});
    debugPrint('📍 Joined office room: $officeId');
  }

  // Listen for new parcel events
  static void onNewParcel(Function(Map<String, dynamic>) callback) {
    if (_socket == null) {
      debugPrint('Cannot listen: Socket not initialized');
      return;
    }

    _socket!.on('new_parcel', (data) {
      debugPrint('📦 New parcel received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  // Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      debugPrint('Socket disconnected');
    }
  }
}
