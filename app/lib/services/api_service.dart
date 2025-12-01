import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/parcel.dart';
import '../models/office.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

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

  // Update parcel status
  static Future<bool> updateParcelStatus(String id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/parcels/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
        body: json.encode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating parcel status: $e');
      return false;
    }
  }
}
