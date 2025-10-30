import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';

class OfflineCacheService {
  static const String _tutorialsKey = 'cached_tutorials';
  static const String _quizzesKey = 'cached_quizzes';
  static const String _summariesKey = 'cached_summaries';
  static const String _topicsKey = 'cached_topics';
  static const String _progressKey = 'cached_progress';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _pendingSyncKey = 'pending_sync';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> cacheTutorial(String topicId, AITutorial tutorial) async {
    try {
      final prefs = await _prefs;
      final cachedTutorials = await _getCachedTutorials();

      cachedTutorials[topicId] = tutorial.toJson();

      await prefs.setString(_tutorialsKey, jsonEncode(cachedTutorials));
      await _updateCacheMetadata(topicId, 'tutorial');

      debugPrint('[Offline Cache] Tutorial cached for: $topicId');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to cache tutorial: $e');
    }
  }

  Future<AITutorial?> getCachedTutorial(String topicId) async {
    try {
      final cachedTutorials = await _getCachedTutorials();

      if (cachedTutorials.containsKey(topicId)) {
        debugPrint('[Offline Cache] Retrieved tutorial from cache: $topicId');
        return AITutorial.fromJson(cachedTutorials[topicId]);
      }

      return null;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to retrieve cached tutorial: $e');
      return null;
    }
  }

  Future<void> cacheQuiz(String topicId, Quiz quiz) async {
    try {
      final prefs = await _prefs;
      final cachedQuizzes = await _getCachedQuizzes();

      cachedQuizzes[topicId] = {
        'questions': quiz.questions.map((q) => q.toJson()).toList(),
      };

      await prefs.setString(_quizzesKey, jsonEncode(cachedQuizzes));
      await _updateCacheMetadata(topicId, 'quiz');

      debugPrint('[Offline Cache] Quiz cached for: $topicId');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to cache quiz: $e');
    }
  }

  Future<Quiz?> getCachedQuiz(String topicId) async {
    try {
      final cachedQuizzes = await _getCachedQuizzes();

      if (cachedQuizzes.containsKey(topicId)) {
        debugPrint('[Offline Cache] Retrieved quiz from cache: $topicId');
        return Quiz.fromJson(cachedQuizzes[topicId]);
      }

      return null;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to retrieve cached quiz: $e');
      return null;
    }
  }

  Future<void> cacheSummary(String topicId, String summary) async {
    try {
      final prefs = await _prefs;
      final cachedSummaries = await _getCachedSummaries();

      cachedSummaries[topicId] = {
        'summary': summary,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_summariesKey, jsonEncode(cachedSummaries));
      await _updateCacheMetadata(topicId, 'summary');

      debugPrint('[Offline Cache] Summary cached for: $topicId');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to cache summary: $e');
    }
  }

  Future<String?> getCachedSummary(String topicId) async {
    try {
      final cachedSummaries = await _getCachedSummaries();

      if (cachedSummaries.containsKey(topicId)) {
        debugPrint('[Offline Cache] Retrieved summary from cache: $topicId');
        return cachedSummaries[topicId]['summary'] as String;
      }

      return null;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to retrieve cached summary: $e');
      return null;
    }
  }

  Future<void> cacheTopics(List<Topic> topics) async {
    try {
      final prefs = await _prefs;
      final topicsJson = topics.map((t) => t.toFirestore()).toList();

      await prefs.setString(_topicsKey, jsonEncode(topicsJson));

      debugPrint('[Offline Cache] Cached ${topics.length} topics');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to cache topics: $e');
    }
  }

  Future<List<Topic>?> getCachedTopics() async {
    try {
      final prefs = await _prefs;
      final topicsStr = prefs.getString(_topicsKey);

      if (topicsStr != null) {
        final topicsJson = jsonDecode(topicsStr) as List;
        final topics = topicsJson
            .map((json) => Topic.fromFirestore(json as Map<String, dynamic>))
            .toList();

        debugPrint('[Offline Cache] Retrieved ${topics.length} topics from cache');
        return topics;
      }

      return null;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to retrieve cached topics: $e');
      return null;
    }
  }

  Future<void> cacheProgress(String topicId, Map<String, dynamic> progress) async {
    try {
      final prefs = await _prefs;
      final cachedProgress = await _getCachedProgress();

      cachedProgress[topicId] = progress;

      await prefs.setString(_progressKey, jsonEncode(cachedProgress));
      await _markPendingSync(topicId, 'progress', progress);

      debugPrint('[Offline Cache] Progress cached for: $topicId');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to cache progress: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedProgress(String topicId) async {
    try {
      final cachedProgress = await _getCachedProgress();

      if (cachedProgress.containsKey(topicId)) {
        debugPrint('[Offline Cache] Retrieved progress from cache: $topicId');
        return cachedProgress[topicId];
      }

      return null;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to retrieve cached progress: $e');
      return null;
    }
  }

  Future<Map<String, int>> getAllCachedProgress() async {
    try {
      final cachedProgress = await _getCachedProgress();

      final result = <String, int>{};
      cachedProgress.forEach((topicId, progressData) {
        if (progressData is Map && progressData.containsKey('progressPercentage')) {
          result[topicId] = progressData['progressPercentage'] as int;
        }
      });

      return result;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to retrieve all cached progress: $e');
      return {};
    }
  }

  Future<void> markForDownload(String topicId, String topicTitle) async {
    try {
      final prefs = await _prefs;
      final downloadList = await _getDownloadList();

      if (!downloadList.any((item) => item['id'] == topicId)) {
        downloadList.add({
          'id': topicId,
          'title': topicTitle,
          'markedAt': DateTime.now().toIso8601String(),
        });

        await prefs.setString('download_list', jsonEncode(downloadList));

        debugPrint('[Offline Cache] Marked for download: $topicId');
      }
    } catch (e) {
      debugPrint('[Offline Cache] Failed to mark for download: $e');
    }
  }

  Future<void> removeFromDownloadList(String topicId) async {
    try {
      final prefs = await _prefs;
      final downloadList = await _getDownloadList();

      downloadList.removeWhere((item) => item['id'] == topicId);

      await prefs.setString('download_list', jsonEncode(downloadList));

      debugPrint('[Offline Cache] Removed from download list: $topicId');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to remove from download list: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadList() async {
    return await _getDownloadList();
  }

  Future<Map<String, dynamic>> getCacheMetadata(String topicId) async {
    try {
      final prefs = await _prefs;
      final metadataStr = prefs.getString(_cacheMetadataKey);

      if (metadataStr != null) {
        final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;

        if (metadata.containsKey(topicId)) {
          return metadata[topicId] as Map<String, dynamic>;
        }
      }

      return {};
    } catch (e) {
      debugPrint('[Offline Cache] Failed to get cache metadata: $e');
      return {};
    }
  }

  Future<bool> isTopicFullyCached(String topicId) async {
    try {
      final metadata = await getCacheMetadata(topicId);

      return metadata.containsKey('tutorial') &&
             metadata.containsKey('quiz') &&
             metadata.containsKey('summary');
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getFullyCachedTopics() async {
    try {
      final prefs = await _prefs;
      final metadataStr = prefs.getString(_cacheMetadataKey);

      if (metadataStr != null) {
        final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;

        final fullyyCached = <String>[];
        metadata.forEach((topicId, data) {
          final topicMeta = data as Map<String, dynamic>;
          if (topicMeta.containsKey('tutorial') &&
              topicMeta.containsKey('quiz') &&
              topicMeta.containsKey('summary')) {
            fullyyCached.add(topicId);
          }
        });

        return fullyyCached;
      }

      return [];
    } catch (e) {
      debugPrint('[Offline Cache] Failed to get fully cached topics: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    try {
      final prefs = await _prefs;
      final pendingSyncStr = prefs.getString(_pendingSyncKey);

      if (pendingSyncStr != null) {
        final items = jsonDecode(pendingSyncStr) as List;
        return items.map((item) => item as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      debugPrint('[Offline Cache] Failed to get pending sync items: $e');
      return [];
    }
  }

  Future<void> clearPendingSync(String topicId, String type) async {
    try {
      final prefs = await _prefs;
      final pendingItems = await getPendingSyncItems();

      pendingItems.removeWhere((item) =>
        item['topicId'] == topicId && item['type'] == type
      );

      await prefs.setString(_pendingSyncKey, jsonEncode(pendingItems));

      debugPrint('[Offline Cache] Cleared pending sync: $topicId ($type)');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to clear pending sync: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await _prefs;

      await prefs.remove(_tutorialsKey);
      await prefs.remove(_quizzesKey);
      await prefs.remove(_summariesKey);
      await prefs.remove(_topicsKey);
      await prefs.remove(_progressKey);
      await prefs.remove(_cacheMetadataKey);
      await prefs.remove('download_list');

      debugPrint('[Offline Cache] Cache cleared');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to clear cache: $e');
    }
  }

  Future<void> clearTopicCache(String topicId) async {
    try {
      final prefs = await _prefs;

      final tutorials = await _getCachedTutorials();
      tutorials.remove(topicId);
      await prefs.setString(_tutorialsKey, jsonEncode(tutorials));

      final quizzes = await _getCachedQuizzes();
      quizzes.remove(topicId);
      await prefs.setString(_quizzesKey, jsonEncode(quizzes));

      final summaries = await _getCachedSummaries();
      summaries.remove(topicId);
      await prefs.setString(_summariesKey, jsonEncode(summaries));

      final metadataStr = prefs.getString(_cacheMetadataKey);
      if (metadataStr != null) {
        final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
        metadata.remove(topicId);
        await prefs.setString(_cacheMetadataKey, jsonEncode(metadata));
      }

      debugPrint('[Offline Cache] Cleared cache for: $topicId');
    } catch (e) {
      debugPrint('[Offline Cache] Failed to clear topic cache: $e');
    }
  }

  Future<int> getCacheSizeInBytes() async {
    try {
      final prefs = await _prefs;

      int totalSize = 0;

      final tutorialsStr = prefs.getString(_tutorialsKey);
      if (tutorialsStr != null) totalSize += tutorialsStr.length;

      final quizzesStr = prefs.getString(_quizzesKey);
      if (quizzesStr != null) totalSize += quizzesStr.length;

      final summariesStr = prefs.getString(_summariesKey);
      if (summariesStr != null) totalSize += summariesStr.length;

      final topicsStr = prefs.getString(_topicsKey);
      if (topicsStr != null) totalSize += topicsStr.length;

      final progressStr = prefs.getString(_progressKey);
      if (progressStr != null) totalSize += progressStr.length;

      return totalSize;
    } catch (e) {
      debugPrint('[Offline Cache] Failed to calculate cache size: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> _getCachedTutorials() async {
    try {
      final prefs = await _prefs;
      final tutorialsStr = prefs.getString(_tutorialsKey);

      if (tutorialsStr != null) {
        return jsonDecode(tutorialsStr) as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCachedQuizzes() async {
    try {
      final prefs = await _prefs;
      final quizzesStr = prefs.getString(_quizzesKey);

      if (quizzesStr != null) {
        return jsonDecode(quizzesStr) as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCachedSummaries() async {
    try {
      final prefs = await _prefs;
      final summariesStr = prefs.getString(_summariesKey);

      if (summariesStr != null) {
        return jsonDecode(summariesStr) as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getCachedProgress() async {
    try {
      final prefs = await _prefs;
      final progressStr = prefs.getString(_progressKey);

      if (progressStr != null) {
        return jsonDecode(progressStr) as Map<String, dynamic>;
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getDownloadList() async {
    try {
      final prefs = await _prefs;
      final downloadListStr = prefs.getString('download_list');

      if (downloadListStr != null) {
        final list = jsonDecode(downloadListStr) as List;
        return list.map((item) => item as Map<String, dynamic>).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateCacheMetadata(String topicId, String type) async {
    try {
      final prefs = await _prefs;
      final metadataStr = prefs.getString(_cacheMetadataKey);

      Map<String, dynamic> metadata = {};
      if (metadataStr != null) {
        metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
      }

      if (!metadata.containsKey(topicId)) {
        metadata[topicId] = {};
      }

      (metadata[topicId] as Map<String, dynamic>)[type] = DateTime.now().toIso8601String();

      await prefs.setString(_cacheMetadataKey, jsonEncode(metadata));
    } catch (e) {
      debugPrint('[Offline Cache] Failed to update cache metadata: $e');
    }
  }

  Future<void> _markPendingSync(String topicId, String type, dynamic data) async {
    try {
      final prefs = await _prefs;
      final pendingItems = await getPendingSyncItems();

      pendingItems.removeWhere((item) =>
        item['topicId'] == topicId && item['type'] == type
      );

      pendingItems.add({
        'topicId': topicId,
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_pendingSyncKey, jsonEncode(pendingItems));
    } catch (e) {
      debugPrint('[Offline Cache] Failed to mark pending sync: $e');
    }
  }
}
