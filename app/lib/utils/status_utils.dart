import 'package:flutter/material.dart';

class StatusUtils {
  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return 'Créé';
      case 'intransit':
        return 'En Transit';
      case 'arrived':
        return 'Arrivé';
      case 'delivered':
        return 'Livré';
      case 'issue':
        return 'Problème';
      default:
        return status;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return const Color(0xFF9E9E9E);
      case 'intransit':
        return const Color(0xFFFF9800);
      case 'arrived':
        return const Color(0xFF2196F3);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'issue':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Icons.add_circle_outline_rounded;
      case 'intransit':
        return Icons.local_shipping_rounded;
      case 'arrived':
        return Icons.flight_land_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'issue':
        return Icons.warning_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static String getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return 'Le colis a été enregistré';
      case 'intransit':
        return 'Le colis est en cours de transport';
      case 'arrived':
        return 'Le colis est arrivé à destination';
      case 'delivered':
        return 'Le colis a été livré';
      case 'issue':
        return 'Un problème est survenu';
      default:
        return '';
    }
  }

  static List<String> getAllStatuses() {
    return ['created', 'intransit', 'arrived', 'delivered', 'issue'];
  }
}
