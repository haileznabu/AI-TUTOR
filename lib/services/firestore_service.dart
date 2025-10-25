import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserProgress({
    required String userId,
    required String topicId,
    required int progress,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(topicId)
          .set({
        'topicId': topicId,
        'progress': progress,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user progress: $e');
    }
  }

  Future<Map<String, int>> getUserProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();

      return Map.fromEntries(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return MapEntry(
            data['topicId'] as String,
            data['progress'] as int,
          );
        }),
      );
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  Future<void> addVisitedTopic({
    required String userId,
    required String topicId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('visitedTopics')
          .doc(topicId)
          .set({
        'topicId': topicId,
        'visitedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add visited topic: $e');
    }
  }

  Future<List<String>> getVisitedTopics(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('visitedTopics')
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['topicId'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to get visited topics: $e');
    }
  }

  Future<void> saveTutorial({
    required String userId,
    required String topicId,
    required AITutorial tutorial,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tutorials')
          .doc(topicId)
          .set({
        'topicId': tutorial.topicId,
        'topicTitle': tutorial.topicTitle,
        'steps': tutorial.steps.map((step) => step.toJson()).toList(),
        'summary': tutorial.summary,
        'generatedAt': Timestamp.fromDate(tutorial.generatedAt),
      });
    } catch (e) {
      throw Exception('Failed to save tutorial: $e');
    }
  }

  Future<AITutorial?> getTutorial({
    required String userId,
    required String topicId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tutorials')
          .doc(topicId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return AITutorial(
        topicId: data['topicId'] as String,
        topicTitle: data['topicTitle'] as String,
        steps: (data['steps'] as List)
            .map((step) => TutorialStep.fromJson(step as Map<String, dynamic>))
            .toList(),
        summary: data['summary'] as String,
        generatedAt: (data['generatedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw Exception('Failed to get tutorial: $e');
    }
  }

  Future<void> saveQuiz({
    required String userId,
    required String topicId,
    required Quiz quiz,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizzes')
          .doc(topicId)
          .set({
        'topicId': topicId,
        'questions': quiz.questions.map((q) => q.toJson()).toList(),
        'generatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save quiz: $e');
    }
  }

  Future<Quiz?> getQuiz({
    required String userId,
    required String topicId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizzes')
          .doc(topicId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      return Quiz(
        questions: (data['questions'] as List)
            .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  Future<void> saveQuizResult({
    required String userId,
    required String topicId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .add({
        'topicId': topicId,
        'score': score,
        'totalQuestions': totalQuestions,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save quiz result: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getQuizResults({
    required String userId,
    required String topicId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .where('topicId', isEqualTo: topicId)
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'score': data['score'],
          'totalQuestions': data['totalQuestions'],
          'completedAt': (data['completedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to get quiz results: $e');
    }
  }
}
