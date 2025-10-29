import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class VisitedTopicsService {
  static const String _prefsKey = 'visited_topics_v2';
  static const int _maxItems = 20;
  static final FirestoreService _firestoreService = FirestoreService();

  static Future<void> recordVisit(String topicId, {int progressPercentage = 0}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      List<dynamic> entries = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];

      entries = entries.where((e) => e is Map && e['id'] != null && e['ts'] != null).toList();

      final existingIndex = entries.indexWhere((e) => e['id'] == topicId);
      final existingProgress = existingIndex >= 0 ? (entries[existingIndex]['progress'] ?? 0) as int : 0;

      final maxProgress = progressPercentage > existingProgress ? progressPercentage : existingProgress;

      entries.removeWhere((e) => e['id'] == topicId);

      entries.insert(0, <String, dynamic>{
        'id': topicId,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'progress': maxProgress,
      });

      if (entries.length > _maxItems) {
        entries = entries.sublist(0, _maxItems);
      }

      await prefs.setString(_prefsKey, jsonEncode(entries));

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _firestoreService.addVisitedTopic(userId: userId, topicId: topicId);
      }
    } catch (e) {
      // Fallback to Firestore only if local storage fails
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        try {
          await _firestoreService.addVisitedTopic(userId: userId, topicId: topicId);
        } catch (firestoreError) {
          // Silent fail for web compatibility
        }
      }
    }
  }

  static Future<List<String>> getVisitedIdsOrdered() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw == null) return <String>[];
      try {
        final List<dynamic> entries = jsonDecode(raw) as List<dynamic>;
        final List<Map<String, dynamic>> normalized = entries
            .where((e) => e is Map && e['id'] != null && e['ts'] != null)
            .map<Map<String, dynamic>>((e) => <String, dynamic>{
              'id': e['id'] as String,
              'ts': e['ts'] as int,
              'progress': e['progress'] ?? 0,
            })
            .toList();
        normalized.sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));
        return normalized.map((e) => e['id'] as String).toList();
      } catch (_) {
        return <String>[];
      }
    } catch (_) {
      return <String>[];
    }
  }

  static Future<Map<String, int>> getVisitedTopicsWithProgress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw == null) return <String, int>{};
      try {
        final List<dynamic> entries = jsonDecode(raw) as List<dynamic>;
        final Map<String, int> result = {};
        for (final e in entries) {
          if (e is Map && e['id'] != null) {
            result[e['id'] as String] = (e['progress'] ?? 0) as int;
          }
        }
        return result;
      } catch (_) {
        return <String, int>{};
      }
    } catch (_) {
      return <String, int>{};
    }
  }

  static Future<int> getTopicProgress(String topicId) async {
    try {
      final progressMap = await getVisitedTopicsWithProgress();
      return progressMap[topicId] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> updateProgress(String topicId, int progressPercentage) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      try {
        final List<dynamic> entries = jsonDecode(raw) as List<dynamic>;
        final index = entries.indexWhere((e) => e is Map && e['id'] == topicId);

        if (index >= 0) {
          final existingProgress = (entries[index]['progress'] ?? 0) as int;
          if (progressPercentage > existingProgress) {
            entries[index]['progress'] = progressPercentage;
            entries[index]['ts'] = DateTime.now().millisecondsSinceEpoch;
            await prefs.setString(_prefsKey, jsonEncode(entries));
          }
        }
      } catch (_) {
      }
    } catch (_) {
    }
  }

  static Future<void> clearAll() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {
    }
  }
}
