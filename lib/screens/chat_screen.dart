import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/ai_service.dart';
import '../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  bool _isSending = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && supabaseService.isInitialized) {
        final chatData = await supabaseService.getChatMessages(user.uid);
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
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildChatList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: kPrimaryColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Chat v2',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              Text(
                'Ask me anything',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                'Start the conversation below',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        final isUser = message.role == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isUser ? kAccentColor : Colors.white)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    message.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    enabled: !_isSending,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
          
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      height: 44,
      width: 44,
      child: ElevatedButton(
        onPressed: _isSending ? null : _handleSend,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        child: _isSending
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
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

    if (user != null && supabaseService.isInitialized) {
      try {
        await supabaseService.saveChatMessage(
          userId: user.uid,
          role: 'user',
          content: text,
        );
      } catch (e) {
        debugPrint('Failed to save user message to Supabase: $e');
      }
    }

    try {
      final reply = await aiService.sendChatResponse(_messages);
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });

      if (user != null && supabaseService.isInitialized) {
        try {
          await supabaseService.saveChatMessage(
            userId: user.uid,
            role: 'assistant',
            content: reply,
          );
        } catch (e) {
          debugPrint('Failed to save assistant message to Supabase: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}