import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';
import 'firestore_service.dart';
import 'firebase_auth_service.dart';
import 'ai_service.dart';

class LearningRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final AIService _aiService = AIService();
  Future<UserProfile> fetchUserProfile() async {
    final String fallbackName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Learner';
    return Future<UserProfile>.delayed(
      const Duration(milliseconds: 400),
      () => UserProfile(
        name: fallbackName,
        avatarUrl:
            'https://api.dicebear.com/8.x/identicon/svg?seed=${Uri.encodeComponent(fallbackName)}',
        streakDays: 7,
        hasActiveLesson: true,
      ),
    );
  }

  Future<AdaptiveMetrics> fetchAdaptiveMetrics() async {
    return Future<AdaptiveMetrics>.delayed(
      const Duration(milliseconds: 380),
      () => const AdaptiveMetrics(
        level: 'Intermediate',
        mastery: 0.76,
        pace: 'Steady',
        weeklyTime: Duration(hours: 3, minutes: 20),
      ),
    );
  }

  Future<List<Recommendation>> fetchRecommendations() async {
    return Future<List<Recommendation>>.delayed(
      const Duration(milliseconds: 420),
      () => const [
        Recommendation(
          id: 'r1',
          title: 'Fractions Mastery',
          reason: 'Perfect for your pace and performance',
          estimatedTime: Duration(minutes: 18),
          difficultyMatch: 0.9,
          topic: 'Math',
        ),
        Recommendation(
          id: 'r2',
          title: 'Photosynthesis Basics',
          reason: 'Builds on your strengths in visuals',
          estimatedTime: Duration(minutes: 22),
          difficultyMatch: 0.8,
          topic: 'Biology',
        ),
        Recommendation(
          id: 'r3',
          title: 'Grammar: Complex Sentences',
          reason: 'Targets a small knowledge gap',
          estimatedTime: Duration(minutes: 15),
          difficultyMatch: 0.85,
          topic: 'English',
        ),
      ],
    );
  }

  Future<ActiveLesson?> fetchActiveLesson() async {
    return Future<ActiveLesson?>.delayed(
      const Duration(milliseconds: 350),
      () => const ActiveLesson(
        id: 'al1',
        title: 'Quadratic Equations',
        topic: 'Math',
        progress: 0.65,
        timeSpent: Duration(minutes: 24),
      ),
    );
  }

  Future<WeeklyActivity> fetchWeeklyActivity() async {
    return Future<WeeklyActivity>.delayed(
      const Duration(milliseconds: 400),
      () => const WeeklyActivity(
        lessonsPerDay: [3, 5, 2, 6, 4, 7, 5],
        avgTimePerLessonMinutes: [18, 22, 20, 25, 19, 23, 21],
        paceTrend: 'accelerating',
        fasterVsLastWeek: 0.15,
      ),
    );
  }

  Future<List<Achievement>> fetchAchievements() async {
    return Future<List<Achievement>>.delayed(
      const Duration(milliseconds: 380),
      () => const [
        Achievement(
          id: 'a1',
          title: 'First Steps',
          description: 'Complete your first lesson',
          earned: true,
          icon: Icons.star,
        ),
        Achievement(
          id: 'a2',
          title: '7-Day Streak',
          description: 'Learn for 7 consecutive days',
          earned: true,
          icon: Icons.local_fire_department,
        ),
        Achievement(
          id: 'a3',
          title: 'Speed Demon',
          description: 'Complete 5 lessons in one day',
          earned: false,
          icon: Icons.flash_on,
        ),
      ],
    );
  }

  Future<DailyChallenge> fetchDailyChallenge() async {
    return Future<DailyChallenge>.delayed(
      const Duration(milliseconds: 400),
      () => const DailyChallenge(
        id: 'dc1',
        title: 'Algebra Sprint',
        description: 'Solve 10 algebra problems in 15 minutes',
        difficulty: 'Intermediate',
        estimatedTime: Duration(minutes: 15),
        rewardXp: 50,
      ),
    );
  }

  Future<List<Insight>> fetchInsights() async {
    return Future<List<Insight>>.delayed(
      const Duration(milliseconds: 420),
      () => const [
        Insight(id: 'i1', text: 'You learn best in the morning. Keep it up!'),
        Insight(
          id: 'i2',
          text: 'Your visual learning style is improving your scores.',
        ),
      ],
    );
  }

  Future<List<NextTopic>> fetchNextTopics() async {
    return Future<List<NextTopic>>.delayed(
      const Duration(milliseconds: 400),
      () => const [
        NextTopic(
          id: 't1',
          title: 'Calculus Fundamentals',
          prerequisiteCompletion: 85,
          estimatedTime: Duration(hours: 3),
          difficulty: 'Intermediate',
        ),
        NextTopic(
          id: 't2',
          title: 'Human Anatomy Basics',
          prerequisiteCompletion: 60,
          estimatedTime: Duration(hours: 2, minutes: 30),
          difficulty: 'Beginner',
        ),
        NextTopic(
          id: 't3',
          title: 'Essay Writing Techniques',
          prerequisiteCompletion: 40,
          estimatedTime: Duration(hours: 2),
          difficulty: 'Beginner',
        ),
      ],
    );
  }

  Future<AITutorial> getTutorialForTopic(String topicId, String topicTitle) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('[Tutorial Cache] Checking cache for topicId: $topicId');
    final cachedTutorial = await _firestoreService.getTutorial(
      userId: userId,
      topicId: topicId,
    );

    if (cachedTutorial != null) {
      debugPrint('[Tutorial Cache] Found cached tutorial for: $topicId');
      return cachedTutorial;
    }

    debugPrint('[Tutorial Cache] No cache found. Generating tutorial for: $topicTitle');
    final generatedTutorial = await _aiService.generateTutorial(topicTitle);

    debugPrint('[Tutorial Cache] Saving tutorial to Firestore for: $topicId');
    await _firestoreService.saveTutorial(
      userId: userId,
      topicId: topicId,
      tutorial: generatedTutorial,
    );

    await _firestoreService.addVisitedTopic(
      userId: userId,
      topicId: topicId,
    );

    return generatedTutorial;
  }

  Future<Quiz> getQuizForTopic(String topicId, String topicTitle) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('[Quiz Cache] Checking cache for topicId: $topicId');
    final cachedQuiz = await _firestoreService.getQuiz(
      userId: userId,
      topicId: topicId,
    );

    if (cachedQuiz != null) {
      debugPrint('[Quiz Cache] Found cached quiz for: $topicId');
      return cachedQuiz;
    }

    debugPrint('[Quiz Cache] No cache found. Generating quiz for: $topicTitle');
    final generatedQuiz = await _aiService.generateQuiz(topicTitle);

    debugPrint('[Quiz Cache] Saving quiz to Firestore for: $topicId');
    await _firestoreService.saveQuiz(
      userId: userId,
      topicId: topicId,
      quiz: generatedQuiz,
    );

    return generatedQuiz;
  }

  Future<void> saveProgress(
    String topicId,
    int currentStepIndex,
    int totalSteps,
  ) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final progressPercentage = totalSteps > 0
        ? ((currentStepIndex / totalSteps) * 100).round()
        : 0;

    await _firestoreService.saveUserProgress(
      userId: userId,
      topicId: topicId,
      progressPercentage: progressPercentage,
      currentStepIndex: currentStepIndex,
      totalSteps: totalSteps,
    );
  }

  Future<Map<String, int>> getUserProgress() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return {};
    }

    return await _firestoreService.getUserProgress(userId);
  }

  Future<Map<String, dynamic>?> getTopicProgressDetails(String topicId) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return null;
    }

    return await _firestoreService.getTopicProgressDetails(userId, topicId);
  }

  Future<List<String>> getVisitedTopics() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      return [];
    }

    return await _firestoreService.getVisitedTopics(userId);
  }

  Future<void> saveQuizResult(String topicId, int score, int totalQuestions) async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _firestoreService.saveQuizResult(
      userId: userId,
      topicId: topicId,
      score: score,
      totalQuestions: totalQuestions,
    );
  }
}
