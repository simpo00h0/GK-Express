import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_service.dart';

class SocketService {
  static io.Socket? _socket;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

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

      // Join office room when connected
      final user = AuthService.currentUser;
      if (user?.officeId != null) {
        joinOfficeRoom(user!.officeId!, user.id);
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
