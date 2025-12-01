import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  // Initialize and connect to Socket.IO server
  static void connect() {
    if (_socket != null && _isConnected) {
      print('Socket already connected');
      return;
    }

    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      print('✅ Socket connected: ${_socket!.id}');
      _isConnected = true;
      
      // Join office room when connected
      final user = AuthService.currentUser;
      if (user?.officeId != null) {
        joinOfficeRoom(user!.officeId!, user.id);
      }
    });

    _socket!.on('disconnect', (_) {
      print('❌ Socket disconnected');
      _isConnected = false;
    });

    _socket!.on('connect_error', (error) {
      print('Socket connection error: $error');
      _isConnected = false;
    });
  }

  // Join office room
  static void joinOfficeRoom(String officeId, String userId) {
    if (_socket == null || !_isConnected) {
      print('Cannot join room: Socket not connected');
      return;
    }

    _socket!.emit('join_office', {
      'officeId': officeId,
      'userId': userId,
    });
    print('📍 Joined office room: $officeId');
  }

  // Listen for new parcel events
  static void onNewParcel(Function(Map<String, dynamic>) callback) {
    if (_socket == null) {
      print('Cannot listen: Socket not initialized');
      return;
    }

    _socket!.on('new_parcel', (data) {
      print('📦 New parcel received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  // Disconnect socket
  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      print('Socket disconnected');
    }
  }
}
