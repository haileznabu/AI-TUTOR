import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final String fallbackName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Learner';

    final streakDays = await _calculateStreak(userId);
    final hasActiveLesson = await _hasActiveLesson(userId);

    return UserProfile(
      name: fallbackName,
      avatarUrl:
          'https://api.dicebear.com/8.x/identicon/svg?seed=${Uri.encodeComponent(fallbackName)}',
      streakDays: streakDays,
      hasActiveLesson: hasActiveLesson,
    );
  }

  Future<AdaptiveMetrics> fetchAdaptiveMetrics() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final progress = await _firestoreService.getUserProgress(userId);
    final quizResultsCount = await _getQuizResultsCount(userId);
    final weeklyTime = await _calculateWeeklyTime(userId);

    final totalProgress = progress.values.fold<int>(0, (sum, val) => sum + val);
    final completedTopics = progress.values.where((p) => p >= 100).length;
    final avgProgress = progress.isNotEmpty ? totalProgress / progress.length : 0;

    final mastery = quizResultsCount > 0 ? (avgProgress / 100).clamp(0.0, 1.0) : 0.0;
    final level = completedTopics >= 10
        ? 'Advanced'
        : completedTopics >= 3
            ? 'Intermediate'
            : 'Beginner';
    final pace = weeklyTime.inMinutes >= 180
        ? 'Fast'
        : weeklyTime.inMinutes >= 60
            ? 'Steady'
            : 'Slow';

    return AdaptiveMetrics(
      level: level,
      mastery: mastery,
      pace: pace,
      weeklyTime: weeklyTime,
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
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final lessonsPerDay = <int>[];
    final avgTimePerLessonMinutes = <double>[];

    debugPrint('[Weekly Activity] Calculating activity for past 7 days');

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final lessons = await _getLessonsForDate(userId, date);
      lessonsPerDay.add(lessons);

      final timeSpent = await _getTimeSpentForDate(userId, date);
      final avgTime = lessons > 0 ? (timeSpent.inMinutes / lessons).toDouble() : 0.0;
      avgTimePerLessonMinutes.add(avgTime);
    }

    final recentLessons = lessonsPerDay.length >= 7
        ? lessonsPerDay.sublist(4, 7).fold<int>(0, (sum, val) => sum + val)
        : lessonsPerDay.fold<int>(0, (sum, val) => sum + val);

    final earlierLessons = lessonsPerDay.length >= 7
        ? lessonsPerDay.sublist(0, 3).fold<int>(0, (sum, val) => sum + val)
        : 0;

    String paceTrend;
    if (earlierLessons == 0 && recentLessons > 0) {
      paceTrend = 'Growing';
    } else if (recentLessons > earlierLessons) {
      final percentIncrease = ((recentLessons - earlierLessons) / earlierLessons * 100).round();
      paceTrend = percentIncrease > 50 ? 'Accelerating' : 'Increasing';
    } else if (recentLessons == earlierLessons) {
      paceTrend = 'Steady';
    } else {
      final percentDecrease = ((earlierLessons - recentLessons) / earlierLessons * 100).round();
      paceTrend = percentDecrease > 50 ? 'Declining' : 'Slowing';
    }

    final thisWeekTotal = lessonsPerDay.fold<int>(0, (sum, val) => sum + val);
    final lastWeekTotal = await _getLastWeekTotal(userId);
    final fasterVsLastWeek = lastWeekTotal > 0
        ? ((thisWeekTotal - lastWeekTotal) / lastWeekTotal * 100)
        : 0.0;

    debugPrint('[Weekly Activity] This week: $thisWeekTotal, Last week: $lastWeekTotal, Trend: $paceTrend');

    return WeeklyActivity(
      lessonsPerDay: lessonsPerDay,
      avgTimePerLessonMinutes: avgTimePerLessonMinutes,
      paceTrend: paceTrend,
      fasterVsLastWeek: fasterVsLastWeek,
    );
  }

  Future<List<Achievement>> fetchAchievements() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final progress = await _firestoreService.getUserProgress(userId);
    final streak = await _calculateStreak(userId);
    final completedTopics = progress.values.where((p) => p >= 100).length;

    return [
      Achievement(
        id: 'a1',
        title: 'First Steps',
        description: 'Complete your first lesson',
        earned: progress.isNotEmpty,
        icon: Icons.star,
      ),
      Achievement(
        id: 'a2',
        title: '7-Day Streak',
        description: 'Learn for 7 consecutive days',
        earned: streak >= 7,
        icon: Icons.local_fire_department,
      ),
      Achievement(
        id: 'a3',
        title: 'Speed Demon',
        description: 'Complete 5 topics',
        earned: completedTopics >= 5,
        icon: Icons.flash_on,
      ),
      Achievement(
        id: 'a4',
        title: 'Knowledge Seeker',
        description: 'Complete 10 topics',
        earned: completedTopics >= 10,
        icon: Icons.emoji_events,
      ),
      Achievement(
        id: 'a5',
        title: 'Dedicated Learner',
        description: 'Achieve a 30-day streak',
        earned: streak >= 30,
        icon: Icons.workspace_premium,
      ),
      Achievement(
        id: 'a6',
        title: 'Master',
        description: 'Complete 25 topics',
        earned: completedTopics >= 25,
        icon: Icons.school,
      ),
    ];
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

  Future<int> _calculateStreak(String userId) async {
    try {
      final now = DateTime.now();
      int streak = 0;

      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final hasActivity = await _hasActivityOnDate(userId, date);

        if (hasActivity) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error calculating streak: $e');
      return 0;
    }
  }

  Future<bool> _hasActivityOnDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .where('lastUpdated', isGreaterThanOrEqualTo: startOfDay)
          .where('lastUpdated', isLessThan: endOfDay)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasActiveLesson(String userId) async {
    try {
      final progress = await _firestoreService.getUserProgress(userId);
      return progress.values.any((p) => p > 0 && p < 100);
    } catch (e) {
      return false;
    }
  }

  Future<int> _getQuizResultsCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Duration> _calculateWeeklyTime(String userId) async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .where('lastUpdated', isGreaterThanOrEqualTo: weekAgo)
          .get();

      final totalMinutes = snapshot.docs.length * 20;
      return Duration(minutes: totalMinutes);
    } catch (e) {
      return Duration.zero;
    }
  }

  Future<Duration> _getTimeSpentForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .where('lastUpdated', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('lastUpdated', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      final estimatedMinutesPerSession = 15;
      final totalSessions = progressSnapshot.docs.length;

      return Duration(minutes: totalSessions * estimatedMinutesPerSession);
    } catch (e) {
      debugPrint('Error getting time spent for date: $e');
      return Duration.zero;
    }
  }

  Future<int> _getLastWeekTotal(String userId) async {
    try {
      final now = DateTime.now();
      int totalLessons = 0;

      for (int i = 7; i <= 13; i++) {
        final date = now.subtract(Duration(days: i));
        final lessons = await _getLessonsForDate(userId, date);
        totalLessons += lessons;
      }

      return totalLessons;
    } catch (e) {
      debugPrint('Error getting last week total: $e');
      return 0;
    }
  }

  Future<int> _getLessonsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final uniqueTopics = <String>{};

      final visitedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('visitedTopics')
          .where('visitedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('visitedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in visitedSnapshot.docs) {
        final topicId = doc.data()['topicId'] as String?;
        if (topicId != null) {
          uniqueTopics.add(topicId);
        }
      }

      final quizSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in quizSnapshot.docs) {
        final topicId = doc.data()['topicId'] as String?;
        if (topicId != null) {
          uniqueTopics.add(topicId);
        }
      }

      debugPrint('[Weekly Activity] Date: ${date.toString().split(' ')[0]}, Topics: ${uniqueTopics.length}');
      return uniqueTopics.length;
    } catch (e) {
      debugPrint('Error getting lessons for date ${date.toString()}: $e');
      return 0;
    }
  }
}
