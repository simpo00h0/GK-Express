import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/parcel.dart';
import '../models/office.dart';
import '../models/user.dart';
import '../models/parcel_status_history.dart';
import '../models/message.dart';
import 'auth_service.dart';
import 'history_cache_service.dart';

class ApiService {
  static const String baseUrl = 'https://gk-express.onrender.com/api';

  // Fetch all offices
  static Future<List<Office>> fetchOffices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/offices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Office.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load offices');
      }
    } catch (e) {
      debugPrint('Error fetching offices: $e');
      return [];
    }
  }

  // Fetch all parcels (with optional office filter)
  static Future<List<Parcel>> fetchParcels({String? officeId}) async {
    try {
      var url = '$baseUrl/parcels';
      if (officeId != null) {
        url += '?officeId=$officeId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Parcel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load parcels');
      }
    } catch (e) {
      debugPrint('Error fetching parcels: $e');
      return [];
    }
  }

  // Fetch all users (Boss only)
  static Future<List<User>> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  // Create a new parcel
  static Future<Parcel?> createParcel({
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required String destination,
    required double price,
    required bool isPaid,
    required String originOfficeId,
    required String destinationOfficeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/parcels'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
        body: json.encode({
          'senderName': senderName,
          'senderPhone': senderPhone,
          'receiverName': receiverName,
          'receiverPhone': receiverPhone,
          'destination': destination,
          'price': price,
          'isPaid': isPaid,
          'originOfficeId': originOfficeId,
          'destinationOfficeId': destinationOfficeId,
        }),
      );

      if (response.statusCode == 201) {
        return Parcel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create parcel');
      }
    } catch (e) {
      debugPrint('Error creating parcel: $e');
      return null;
    }
  }

  // Fetch single parcel by ID
  static Future<Parcel?> fetchParcelById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parcels/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        return Parcel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load parcel');
      }
    } catch (e) {
      debugPrint('Error fetching parcel: $e');
      return null;
    }
  }

  // Update parcel status
  static Future<bool> updateParcelStatus(String id, String status, {String? notes}) async {
    try {
      // Normalize status to lowercase (backend expects lowercase)
      final normalizedStatus = status.toLowerCase();
      
      final response = await http.patch(
        Uri.parse('$baseUrl/parcels/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
        body: json.encode({
          'status': normalizedStatus,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        // Invalidate cache for this parcel to force refresh
        await HistoryCacheService.invalidateCache(id);
        return true;
      } else {
        final errorBody = json.decode(response.body);
        debugPrint('Error updating parcel status: ${errorBody['message'] ?? response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating parcel status: $e');
      return false;
    }
  }

  // Fetch parcel status history
  static Future<List<ParcelStatusHistory>> fetchParcelStatusHistory(String parcelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parcels/$parcelId/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      debugPrint('History API Response Status: ${response.statusCode}');
      debugPrint('History API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('History entries found: ${data.length}');
        return data.map((json) => ParcelStatusHistory.fromJson(json)).toList();
      } else {
        final errorBody = json.decode(response.body);
        debugPrint('Error fetching history: ${errorBody['message'] ?? response.statusCode}');
        throw Exception('Failed to load parcel status history: ${errorBody['message'] ?? response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching parcel status history: $e');
      return [];
    }
  }

  // ========== MESSAGES ==========

  // Créer un nouveau message
  static Future<Message?> createMessage({
    required String toOfficeId,
    required String subject,
    required String content,
    String? relatedParcelId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
        body: json.encode({
          'toOfficeId': toOfficeId,
          'subject': subject,
          'content': content,
          if (relatedParcelId != null) 'relatedParcelId': relatedParcelId,
        }),
      );

      if (response.statusCode == 201) {
        return Message.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        debugPrint('Error creating message: ${errorBody['message'] ?? response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating message: $e');
      return null;
    }
  }

  // Récupérer les messages reçus
  static Future<List<Message>> fetchReceivedMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/received'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load received messages');
      }
    } catch (e) {
      debugPrint('Error fetching received messages: $e');
      return [];
    }
  }

  // Récupérer les messages envoyés
  static Future<List<Message>> fetchSentMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/sent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sent messages');
      }
    } catch (e) {
      debugPrint('Error fetching sent messages: $e');
      return [];
    }
  }

  // Récupérer une conversation avec un bureau
  static Future<List<Message>> fetchConversation(String officeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/conversation/$officeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversation');
      }
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      return [];
    }
  }

  // Marquer un message comme lu
  static Future<bool> markMessageAsRead(String messageId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/messages/$messageId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking message as read: $e');
      return false;
    }
  }

  // Récupérer le nombre de messages non lus
  static Future<int> getUnreadMessageCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/unread/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint('Error fetching unread message count: $e');
      return 0;
    }
  }
}
