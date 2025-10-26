import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import '../services/visited_topics_service.dart';
import '../services/learning_repository.dart';
import '../main.dart';
import 'quiz_screen.dart';

export '../services/ai_service.dart' show ChatMessage;

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  bool _isLoading = false;
  AITutorial? _tutorial;
  String? _error;
  int _currentStepIndex = 0;
  int _maxStepReached = 0;
  bool _isFromCache = false;
  final LearningRepository _repository = LearningRepository();
  bool _showChat = false;
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  bool _isSendingMessage = false;

  void _showQuiz() async {
    if (_tutorial == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );

    try {
      final quiz = await _repository.getQuizForTopic(widget.topic.id, widget.topic.title);
      if (!mounted) return;
      Navigator.pop(context);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            quiz: quiz,
            topicTitle: widget.topic.title,
            topicId: widget.topic.id,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate quiz: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndGenerateTutorial();
  }

  int _calculateProgressPercentage() {
    if (_tutorial == null || _tutorial!.steps.isEmpty) return 0;
    return ((_maxStepReached / _tutorial!.steps.length) * 100).round();
  }

  Future<void> _checkAndGenerateTutorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tutorial = await _repository.getTutorialForTopic(widget.topic.id, widget.topic.title);

      final minutesOld = DateTime.now().difference(tutorial.generatedAt).inMinutes;
      final isFromCache = minutesOld > 1;

      setState(() {
        _tutorial = tutorial;
        _isFromCache = isFromCache;
        _isLoading = false;
      });

      await _loadProgress();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProgress() async {
    try {
      final details = await _repository.getTopicProgressDetails(widget.topic.id);

      if (details != null) {
        final savedStepIndex = details['currentStepIndex'] as int? ?? 0;
        if (savedStepIndex >= 0 && savedStepIndex < (_tutorial?.steps.length ?? 0)) {
          setState(() {
            _currentStepIndex = savedStepIndex;
            _maxStepReached = savedStepIndex;
          });
        }
      } else {
        final localProgress = await VisitedTopicsService.getTopicProgress(widget.topic.id);
        if (localProgress > 0 && _tutorial != null) {
          final stepIndex = ((localProgress / 100) * _tutorial!.steps.length).floor();
          if (stepIndex < _tutorial!.steps.length) {
            setState(() {
              _currentStepIndex = stepIndex;
              _maxStepReached = stepIndex;
            });
          }
        }
      }

      await _saveProgress();
    } catch (e) {
      debugPrint('Failed to load progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    if (_tutorial == null) return;

    try {
      if(_currentStepIndex > _maxStepReached) {
        _maxStepReached = _currentStepIndex;
      }

      await _repository.saveProgress(
        widget.topic.id,
        _maxStepReached,
        _tutorial!.steps.length,
      );

      final progress = _calculateProgressPercentage();
      await VisitedTopicsService.recordVisit(
        widget.topic.id,
        progressPercentage: progress,
      );
    } catch (e) {
      debugPrint('Failed to save progress: $e');
    }
  }

  Future<void> _generateTutorial() async {
    await _checkAndGenerateTutorial();
  }

  // Removed navigation to API config; no longer needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kAccentColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.topic.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isFromCache && !_isLoading)
                  Row(
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Loaded from cache',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_tutorial == null) {
      return _buildEmptyState();
    }

    return _buildTutorialContent();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateTutorial,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          Text(
            'Generating your tutorial...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No tutorial available',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  Widget _buildTutorialContent() {
    return Column(
      children: [
        if (_tutorial!.steps.length > 1) _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStepIndex == 0) _buildSummaryCard(),
                if (_currentStepIndex == 0) const SizedBox(height: 16),
                _buildCurrentStep(),
              ],
            ),
          ),
        ),
        if (_showChat) _buildChatSection(),
        if (_tutorial!.steps.length > 1) _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(_tutorial!.steps.length, (index) {
          final isCompleted = index <= _maxStepReached;
          final isCurrent = index == _currentStepIndex;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _tutorial!.steps.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted
                    ? kPrimaryColor
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: kPrimaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'What you\'ll learn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _tutorial!.summary,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final step = _tutorial!.steps[_currentStepIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryColor, kAccentColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Step ${step.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                step.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              if (step.codeExample != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.code, color: kPrimaryColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Code Example',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.codeExample!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (step.explanation != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
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
                        child: Text(
                          step.explanation!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            child: _chatMessages.isEmpty
                ? Center(
                    child: Text(
                      'Ask a question about this topic',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      final isUser = message.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? kPrimaryColor
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask about this topic...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kPrimaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    enabled: !_isSendingMessage,
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSendingMessage ? null : _sendChatMessage,
                  icon: _isSendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: kPrimaryColor,
                          ),
                        )
                      : const Icon(Icons.send, color: kPrimaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty || _tutorial == null) return;

    final userMessage = _chatController.text.trim();
    _chatController.clear();

    setState(() {
      _chatMessages.add(ChatMessage(role: 'user', content: userMessage));
      _isSendingMessage = true;
    });

    try {
      final currentStep = _tutorial!.steps[_currentStepIndex];
      final contextMessages = [
        ChatMessage(
          role: 'user',
          content: 'I am learning about "${widget.topic.title}". Current step: "${currentStep.title}". Content: "${currentStep.content}". Please answer my question in the context of this topic.',
        ),
        ..._chatMessages,
      ];

      final response = await aiService.sendChatResponse(contextMessages);

      setState(() {
        _chatMessages.add(ChatMessage(role: 'assistant', content: response));
        _isSendingMessage = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add(ChatMessage(
          role: 'assistant',
          content: 'Sorry, I encountered an error: $e',
        ));
        _isSendingMessage = false;
      });
    }
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _showChat = !_showChat;
                if (!_showChat) {
                  _chatMessages.clear();
                }
              });
            },
            icon: Icon(
              _showChat ? Icons.close : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
            tooltip: _showChat ? 'Close Chat' : 'Ask Questions',
          ),
          const SizedBox(width: 8),
          if (_currentStepIndex > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStepIndex--;
                  });
                  _saveProgress();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentStepIndex > 0 && _currentStepIndex < _tutorial!.steps.length - 1)
            const SizedBox(width: 12),
          if (_currentStepIndex < _tutorial!.steps.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStepIndex++;
                  });
                  _saveProgress();
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentStepIndex == _tutorial!.steps.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showQuiz(),
                icon: const Icon(Icons.quiz),
                label: const Text('Take Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
