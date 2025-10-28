import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  final FirestoreService _firestoreService = FirestoreService();
  final VoiceService _voiceService = VoiceService();
  bool _isSending = false;
  bool _isLoading = true;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initializeTts();
    _voiceService.setOnSpeakComplete(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('[Chat Cache] Loading chat history for user: ${user.uid}');
        final chatData = await _firestoreService.getChatMessages(user.uid);
        debugPrint('[Chat Cache] Loaded ${chatData.length} messages from Firestore');
        setState(() {
          _messages.clear();
          _messages.addAll(
            chatData.map((msg) => ChatMessage(
              role: msg['role'] as String,
              content: msg['content'] as String,
            )),
          );
          _isLoading = false;
        });
      } else {
        debugPrint('[Chat Cache] No user logged in, skipping cache load');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[Chat Cache] Failed to load chat history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _stopSpeaking() async {
    await _voiceService.stop();
    setState(() {
      _isSpeaking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 800;
    final double maxWidth = isDesktop ? 1000 : double.infinity;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kDarkGradient,
        ) : null,
        color: isDark ? null : Colors.white,
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                _buildHeader(isDesktop),
                const SizedBox(height: 8),
                Expanded(child: _buildChatList(isDesktop)),
                _buildInputBar(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kAccentColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-TUTOR Chat',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: isDesktop ? 28 : 24,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask me anything about your learning journey',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: isDark ? Colors.white70 : Colors.grey,
                        fontSize: isDesktop ? 15 : 14,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_messages.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: isDesktop ? 80 : 64,
                  color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start the conversation',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  fontSize: isDesktop ? 20 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask any question to get started with your learning',
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey,
                  fontSize: isDesktop ? 15 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 12,
        vertical: isDesktop ? 16 : 8,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        final isUser = message.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop
                      ? 600
                      : MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: (isUser ? kAccentColor : Colors.white)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isUser
                        ? kAccentColor.withOpacity(0.3)
                        : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                            fontSize: isDesktop ? 15 : 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (!isUser)
                        IconButton(
                          icon: Icon(
                            _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                            size: 20,
                            color: _isSpeaking ? Colors.red : Colors.white70,
                          ),
                          onPressed: () => _isSpeaking ? _stopSpeaking() : _speakResponse(message.content),
                          tooltip: _isSpeaking ? 'Stop' : 'Listen',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 12,
        isDesktop ? 16 : 8,
        isDesktop ? 32 : 12,
        isDesktop ? 24 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                      fontSize: isDesktop ? 15 : 14,
                    ),
                    minLines: 1,
                    maxLines: isDesktop ? 5 : 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : 16,
                        vertical: isDesktop ? 16 : 12,
                      ),
                    ),
                    enabled: !_isSending,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(isDesktop),
        ],
      ),
    );
  }

  Widget _buildSendButton(bool isDesktop) {
    final double size = isDesktop ? 52 : 44;
    return SizedBox(
      height: size,
      width: size,
      child: ElevatedButton(
        onPressed: _isSending ? null : _handleSend,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        child: _isSending
            ? SizedBox(
                height: isDesktop ? 24 : 20,
                width: isDesktop ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.send, size: isDesktop ? 24 : 20),
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isSending = true;
      _messageController.clear();
    });

    if (user != null) {
      try {
        debugPrint('[Chat Cache] Saving user message to Firestore');
        await _firestoreService.saveChatMessage(
          userId: user.uid,
          role: 'user',
          content: text,
        );
      } catch (e) {
        debugPrint('[Chat Cache] Failed to save user message to Firestore: $e');
      }
    }

    try {
      debugPrint('[Chat] Sending message to AI service');
      final reply = await aiService.sendChatResponse(_messages);
      debugPrint('[Chat] Received reply from AI: ${reply.substring(0, reply.length > 50 ? 50 : reply.length)}...');

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: reply));
        });

        if (user != null) {
          try {
            debugPrint('[Chat Cache] Saving assistant response to Firestore');
            await _firestoreService.saveChatMessage(
              userId: user.uid,
              role: 'assistant',
              content: reply,
            );
          } catch (e) {
            debugPrint('[Chat Cache] Failed to save assistant message to Firestore: $e');
          }
        }

        if (!_isSpeaking) {
          _speakResponse(reply);
        }
      }
    } catch (e) {
      debugPrint('Chat error details: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant',
            content: 'Sorry, I encountered an error. Please try again.',
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get response: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _speakResponse(String text) async {
    if (_isSpeaking) {
      await _stopSpeaking();
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
          const SnackBar(content: Text('Unable to speak response')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }
}