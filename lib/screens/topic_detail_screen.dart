import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/topic_model.dart';
import '../services/ai_service.dart';
import '../services/visited_topics_service.dart';
import '../services/learning_repository.dart';
import '../services/voice_service.dart';
import '../main.dart';
import 'quiz_screen.dart';
import '../services/ad_service.dart';

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
  final AdService _adService = AdService();
  final VoiceService _voiceService = VoiceService();
  bool _isSpeaking = false;

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
    _adService.loadInterstitialAd();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initializeTts();
    _voiceService.setOnSpeakComplete(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _adService.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    if (_isSpeaking) {
      await _voiceService.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    try {
      await _voiceService.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read text')),
        );
      }
    }
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
    final bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? kDarkGradient : [Colors.grey[50]!, Colors.grey[100]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDesktop),
              Expanded(
                child: isDesktop
                  ? _buildDesktopContent()
                  : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: textColor,
              size: isDesktop ? 28 : 24,
            ),
            onPressed: () {
              _adService.showInterstitialAd(
                onAdClosed: () => Navigator.pop(context),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kAccentColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.topic.icon,
              color: Colors.white,
              size: isDesktop ? 32 : 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: isDesktop ? 24 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category,
                          size: isDesktop ? 16 : 14,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.topic.category,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: isDesktop ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                    if (_isFromCache && !_isLoading)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_bolt,
                            size: isDesktop ? 16 : 14,
                            color: subtextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cached',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: isDesktop ? 14 : 12,
                            ),
                          ),
                        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: subtextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          Text(
            'Generating your tutorial...',
            style: TextStyle(
              color: subtextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Center(
      child: Text(
        'No tutorial available',
        style: TextStyle(color: subtextColor, fontSize: 16),
      ),
    );
  }

  Widget _buildDesktopContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_tutorial == null) {
      return _buildEmptyState();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (_tutorial!.steps.length > 1) _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentStepIndex == 0) _buildSummaryCard(),
                      if (_currentStepIndex == 0) const SizedBox(height: 24),
                      _buildCurrentStep(),
                    ],
                  ),
                ),
              ),
              if (_tutorial!.steps.length > 1) _buildNavigationButtons(),
            ],
          ),
        ),
        if (_showChat)
          Container(
            width: 450,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey[200],
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            child: _buildDesktopChatSection(),
          ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    : isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final bgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: kPrimaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'What you\'ll learn',
                    style: TextStyle(
                      color: textColor,
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
                  color: subtextColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final bgColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);
    final codeBgColor = isDark ? Colors.black.withOpacity(0.3) : Colors.grey[100]!;
    final codeTextColor = isDark ? Colors.white : Colors.black87;
    final codeLabelColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                      color: _isSpeaking ? Colors.red : kPrimaryColor,
                      size: 24,
                    ),
                    onPressed: () => _speakText('${step.title}. ${step.content}'),
                    tooltip: _isSpeaking ? 'Stop' : 'Listen',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                step.content,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              if (step.codeExample != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: codeBgColor,
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
                              color: codeLabelColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.codeExample!,
                        style: TextStyle(
                          color: codeTextColor,
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
                            color: subtextColor,
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

  Widget _buildDesktopChatSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
    final bgOverlay = isDark ? Colors.black.withOpacity(0.2) : Colors.grey[100]!;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble, color: kPrimaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ask Questions',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () {
                  setState(() {
                    _showChat = false;
                    _chatMessages.clear();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.question_answer,
                          size: 64,
                          color: isDark ? Colors.white.withOpacity(0.3) : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask follow-up questions',
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Get clarification on this step',
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final isUser = message.role == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: const BoxConstraints(maxWidth: 350),
                        decoration: BoxDecoration(
                          color: isUser
                              ? kPrimaryColor.withOpacity(0.2)
                              : isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUser
                                ? kPrimaryColor.withOpacity(0.3)
                                : borderColor,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                message.content,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            if (!isUser)
                              IconButton(
                                icon: Icon(
                                  _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                                  size: 16,
                                  color: _isSpeaking ? Colors.red : kPrimaryColor,
                                ),
                                onPressed: () => _speakText(message.content),
                                tooltip: _isSpeaking ? 'Stop' : 'Listen',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgOverlay,
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Ask a question...',
                    hintStyle: TextStyle(color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kPrimaryColor),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  enabled: !_isSendingMessage,
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSendingMessage ? null : _sendChatMessage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withOpacity(0.5) : Colors.black45;
    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15);
    final bgOverlay = isDark ? Colors.black.withOpacity(0.3) : Colors.grey[200]!;
    final bgOverlay2 = isDark ? Colors.black.withOpacity(0.2) : Colors.grey[100]!;

    return Container(
      decoration: BoxDecoration(
        color: bgOverlay,
        border: Border(
          top: BorderSide(color: borderColor),
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
                      'Ask follow-up...',
                      style: TextStyle(
                        color: subtextColor,
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
                                : isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  message.content,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : textColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (!isUser)
                                IconButton(
                                  icon: Icon(
                                    _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                                    size: 16,
                                    color: _isSpeaking ? Colors.red : Colors.white70,
                                  ),
                                  onPressed: () => _speakText(message.content),
                                  tooltip: _isSpeaking ? 'Stop' : 'Listen',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgOverlay2,
              border: Border(
                top: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Ask follow-up questions about this topic...',
                      hintStyle: TextStyle(color: subtextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

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
              color: iconColor,
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
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
                  foregroundColor: isDark ? Colors.white : Colors.black87,
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
