import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_model.dart';
import '../main.dart';
import '../services/visited_topics_service.dart';
import '../services/firestore_service.dart';
import '../services/ad_service.dart';
import '../providers/theme_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Quiz quiz;
  final String topicTitle;
  final String topicId;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.topicTitle,
    required this.topicId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;
  int _correctAnswers = 0;
  bool _quizCompleted = false;
  final FirestoreService _firestoreService = FirestoreService();
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _adService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;

      if (index == widget.quiz.questions[_currentQuestionIndex].correctAnswerIndex) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() async {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasAnswered = false;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
      await _markTopicAsCompleted();
    }
  }

  Future<void> _markTopicAsCompleted() async {
    try {
      await VisitedTopicsService.recordVisit(
        widget.topicId,
        progressPercentage: 100,
      );

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _firestoreService.saveUserProgress(
          userId: userId,
          topicId: widget.topicId,
          progressPercentage: 100,
          currentStepIndex: 0,
          totalSteps: 1,
        );
      }
    } catch (e) {
      debugPrint('Failed to mark topic as completed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    if (_quizCompleted) {
      return _buildResultsScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? kDarkGradient : kLightGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuestionCard(),
                ),
              ),
              if (_hasAnswered) _buildNextButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topicTitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final progress = (_currentQuestionIndex + 1) / widget.quiz.questions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
        minHeight: 4,
      ),
    );
  }

  Widget _buildQuestionCard() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final question = widget.quiz.questions[_currentQuestionIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.question,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(question.options.length, (index) {
                return _buildOptionButton(index, question);
              }),
              if (_hasAnswered) ...[
                const SizedBox(height: 20),
                _buildExplanation(question),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, QuizQuestion question) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final isSelected = _selectedAnswerIndex == index;
    final isCorrect = index == question.correctAnswerIndex;
    final showResult = _hasAnswered;

    Color getButtonColor() {
      if (!showResult) {
        return isSelected
            ? kPrimaryColor.withOpacity(0.3)
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03));
      }

      if (isCorrect) {
        return Colors.green.withOpacity(0.3);
      }

      if (isSelected && !isCorrect) {
        return Colors.red.withOpacity(0.3);
      }

      return isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
    }

    Color getBorderColor() {
      if (!showResult) {
        return isSelected ? kPrimaryColor : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15));
      }

      if (isCorrect) {
        return Colors.green;
      }

      if (isSelected && !isCorrect) {
        return Colors.red;
      }

      return isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAnswer(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getButtonColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: getBorderColor(), width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getBorderColor().withOpacity(0.2),
                    border: Border.all(color: getBorderColor()),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.options[index],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (showResult && isCorrect)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (showResult && isSelected && !isCorrect)
                  const Icon(Icons.cancel, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(QuizQuestion question) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explanation',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.explanation,
                  style: TextStyle(
                    color: textColor.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _nextQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _currentQuestionIndex < widget.quiz.questions.length - 1
                ? 'Next Question'
                : 'View Results',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final percentage = (_correctAnswers / widget.quiz.questions.length * 100).round();
    final isPassed = percentage >= 70;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? kDarkGradient : kLightGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isPassed
                            ? [Colors.green, Colors.lightGreen]
                            : [Colors.orange, Colors.deepOrange],
                      ),
                    ),
                    child: Icon(
                      isPassed ? Icons.check_circle : Icons.refresh,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isPassed ? 'Great Job!' : 'Keep Learning!',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You scored',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_correctAnswers out of ${widget.quiz.questions.length} correct',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _adService.showInterstitialAd(
                          onAdClosed: () => Navigator.pop(context),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Complete',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
