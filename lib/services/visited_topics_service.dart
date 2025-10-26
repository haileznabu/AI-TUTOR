import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VisitedTopicsService {
  static const String _prefsKey = 'visited_topics_v2';
  static const int _maxItems = 20;

  static Future<void> recordVisit(String topicId, {int progressPercentage = 0}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    List<dynamic> entries = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];

    entries = entries.where((e) => e is Map && e['id'] != null && e['ts'] != null).toList();

    entries.removeWhere((e) => e['id'] == topicId);

    entries.insert(0, <String, dynamic>{
      'id': topicId,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'progress': progressPercentage,
    });

    if (entries.length > _maxItems) {
      entries = entries.sublist(0, _maxItems);
    }

    await prefs.setString(_prefsKey, jsonEncode(entries));
  }

  static Future<List<String>> getVisitedIdsOrdered() async {
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
  }

  static Future<Map<String, int>> getVisitedTopicsWithProgress() async {
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
  }

  static Future<int> getTopicProgress(String topicId) async {
    final progressMap = await getVisitedTopicsWithProgress();
    return progressMap[topicId] ?? 0;
  }

  static Future<void> clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
