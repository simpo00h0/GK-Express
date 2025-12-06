import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parcel_status_history.dart';

// Helper to run async operations without awaiting
void unawaited(Future<void> future) {
  // Ignore errors silently
  future.catchError((_) {});
}

class HistoryCacheService {
  static const String _cachePrefix = 'parcel_history_';
  static const String _cacheTimestampPrefix = 'parcel_history_ts_';
  static const int _cacheExpirationMinutes = 5; // Cache valide 5 minutes

  // Get cached history for a parcel (optimized for performance)
  static Future<List<ParcelStatusHistory>?> getCachedHistory(String parcelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$parcelId';
      final timestampKey = '$_cacheTimestampPrefix$parcelId';

      // Check if cache exists (single read operation)
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) {
        return null;
      }

      final cachedTimestamp = prefs.getInt(timestampKey);
      if (cachedTimestamp == null) {
        return null;
      }

      // Check if cache is still valid
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheAge = now - cachedTimestamp;
      final cacheAgeMinutes = cacheAge / (1000 * 60);

      if (cacheAgeMinutes > _cacheExpirationMinutes) {
        // Cache expired, remove it asynchronously (don't block)
        prefs.remove(cacheKey);
        prefs.remove(timestampKey);
        return null;
      }

      // Parse and return cached data (fast operation)
      final List<dynamic> jsonList = json.decode(cachedData);
      return jsonList.map((json) => ParcelStatusHistory.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Cache history for a parcel (non-blocking)
  static Future<void> cacheHistory(String parcelId, List<ParcelStatusHistory> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$parcelId';
      final timestampKey = '$_cacheTimestampPrefix$parcelId';

      // Convert to JSON
      final jsonList = history.map((h) => h.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Save cache (non-blocking, don't await if not critical)
      unawaited(prefs.setString(cacheKey, jsonString));
      unawaited(prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch));
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Add a new history entry to cache (for immediate update)
  static Future<void> addHistoryEntry(String parcelId, ParcelStatusHistory entry) async {
    try {
      final cached = await getCachedHistory(parcelId);
      if (cached != null) {
        // Add new entry at the beginning
        final updated = [entry, ...cached];
        await cacheHistory(parcelId, updated);
      }
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Invalidate cache for a parcel
  static Future<void> invalidateCache(String parcelId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$parcelId';
      final timestampKey = '$_cacheTimestampPrefix$parcelId';
      await prefs.remove(cacheKey);
      await prefs.remove(timestampKey);
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Clear all history caches
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
  }
}

