import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TopicUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<TopicUploadResult> uploadTopicsFromJson() async {
    try {
      final jsonString = await rootBundle.loadString('topics_data.json');
      final List<dynamic> topicsJson = json.decode(jsonString);

      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];

      for (final topicData in topicsJson) {
        try {
          final Map<String, dynamic> topicMap = {
            'id': topicData['id'],
            'title': topicData['title'],
            'description': topicData['description'],
            'category': topicData['category'],
            'iconCodePoint': topicData['iconCodePoint'],
            'iconFontFamily': topicData['iconFontFamily'],
            'estimatedMinutes': topicData['estimatedMinutes'],
            'difficulty': topicData['difficulty'],
            'createdAt': FieldValue.serverTimestamp(),
          };

          await _firestore
              .collection('topics')
              .doc(topicData['id'])
              .set(topicMap);

          successCount++;
        } catch (e) {
          failCount++;
          errors.add('Failed to upload ${topicData['title']}: $e');
        }
      }

      return TopicUploadResult(
        totalTopics: topicsJson.length,
        successCount: successCount,
        failCount: failCount,
        errors: errors,
      );
    } catch (e) {
      return TopicUploadResult(
        totalTopics: 0,
        successCount: 0,
        failCount: 0,
        errors: ['Failed to load topics_data.json: $e'],
      );
    }
  }
}

class TopicUploadResult {
  final int totalTopics;
  final int successCount;
  final int failCount;
  final List<String> errors;

  TopicUploadResult({
    required this.totalTopics,
    required this.successCount,
    required this.failCount,
    required this.errors,
  });

  bool get isSuccess => failCount == 0 && totalTopics > 0;
  bool get hasErrors => errors.isNotEmpty;
}
