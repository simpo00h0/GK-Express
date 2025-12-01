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
      case 'livré':
        return 'Livré';
      case 'problème':
        return 'Problème';
      default:
        return 'Créé';
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
      case 'livré':
        return const Color(0xFF4CAF50);
      case 'problème':
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
      case 'livré':
        return Icons.check_circle_rounded;
      case 'problème':
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
      case 'livré':
        return 'Le colis a été livré';
      case 'problème':
        return 'Un problème est survenu';
      default:
        return '';
    }
  }

  static List<String> getAllStatuses() {
    return ['created', 'intransit', 'arrived', 'livré', 'problème'];
  }
}
