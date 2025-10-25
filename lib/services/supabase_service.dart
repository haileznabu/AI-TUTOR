import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;

  bool get isInitialized => _client != null;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _client = Supabase.instance.client;
  }

  Future<void> createOrUpdateUserProfile(String userId, {String? email, String? displayName, bool? isAnonymous}) async {
    await client.from('user_profiles').upsert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'is_anonymous': isAnonymous ?? false,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getTopicDetails(String userId, String topicId) async {
    final response = await client
        .from('topic_details')
        .select()
        .eq('user_id', userId)
        .eq('topic_id', topicId)
        .maybeSingle();

    return response;
  }

  Future<void> saveTopicDetails({
    required String userId,
    required String topicId,
    required String topicTitle,
    required String summary,
    required List<Map<String, dynamic>> steps,
  }) async {
    await client.from('topic_details').upsert({
      'user_id': userId,
      'topic_id': topicId,
      'topic_title': topicTitle,
      'summary': summary,
      'steps': steps,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> recordTopicVisit(String userId, String topicId) async {
    final existing = await client
        .from('visited_topics')
        .select()
        .eq('user_id', userId)
        .eq('topic_id', topicId)
        .maybeSingle();

    if (existing != null) {
      await client.from('visited_topics').update({
        'visit_count': (existing['visit_count'] as int) + 1,
        'last_visited_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('topic_id', topicId);
    } else {
      await client.from('visited_topics').insert({
        'user_id': userId,
        'topic_id': topicId,
        'visit_count': 1,
        'last_visited_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateTopicProgress(String userId, String topicId, double progress) async {
    await client.from('visited_topics').update({
      'progress': progress,
    }).eq('user_id', userId).eq('topic_id', topicId);
  }

  Future<List<Map<String, dynamic>>> getVisitedTopics(String userId) async {
    final response = await client
        .from('visited_topics')
        .select()
        .eq('user_id', userId)
        .order('last_visited_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveChatMessage({
    required String userId,
    required String role,
    required String content,
  }) async {
    await client.from('chat_messages').insert({
      'user_id': userId,
      'role': role,
      'content': content,
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId, {int limit = 50}) async {
    final response = await client
        .from('chat_messages')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> clearChatMessages(String userId) async {
    await client.from('chat_messages').delete().eq('user_id', userId);
  }
}

final supabaseService = SupabaseService();
