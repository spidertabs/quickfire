// lib/services/offline_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class OfflineService {
  static const String _pendingSavesKey = 'pending_saves';
  static Timer? _syncTimer;
  static bool _syncing = false;

  // Queue a pending answer save
  static Future<void> queueSave({
    required int attemptId,
    required int questionId,
    required String? answerText,
    required bool? isCorrect,
    required int marksObtained,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pending = prefs.getStringList(_pendingSavesKey) ?? [];
    
    final Map<String, dynamic> saveItem = {
      'attemptId': attemptId,
      'questionId': questionId,
      'answerText': answerText,
      'isCorrect': isCorrect,
      'marksObtained': marksObtained,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Remove any existing pending save for this same question in this same attempt
    pending.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['attemptId'] == attemptId && decoded['questionId'] == questionId;
    });

    pending.add(jsonEncode(saveItem));
    await prefs.setStringList(_pendingSavesKey, pending);
    debugPrint('Queued offline save for question $questionId');
  }

  // Start periodic background sync
  static void startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      syncPendingSaves();
    });
  }

  // Manually trigger sync
  static Future<void> syncPendingSaves() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pending = prefs.getStringList(_pendingSavesKey) ?? [];
      
      if (pending.isEmpty) {
        _syncing = false;
        return;
      }

      debugPrint('Syncing ${pending.length} pending saves...');
      final List<String> stillPending = [];

      for (final item in pending) {
        final data = jsonDecode(item);
        final success = await SupabaseService.saveAnswer(
          attemptId: data['attemptId'],
          questionId: data['questionId'],
          answerText: data['answerText'],
          isCorrect: data['isCorrect'],
          marksObtained: data['marksObtained'],
        );

        if (!success) {
          stillPending.add(item);
        }
      }

      await prefs.setStringList(_pendingSavesKey, stillPending);
      if (stillPending.isEmpty) {
        debugPrint('All offline saves synced successfully!');
      } else {
        debugPrint('${stillPending.length} saves still pending sync.');
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _syncing = false;
    }
  }

  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pendingSavesKey) ?? []).length;
  }
}
