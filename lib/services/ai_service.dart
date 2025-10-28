import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firestore_service.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';

// Extract a JSON object from an AI text response using layered heuristics.
// Strategy:
// 0) Try to parse the whole text directly (Gemini often returns plain JSON)
// 1) Prefer fenced ```json blocks
// 2) Fallback to any fenced ``` block that looks like JSON
// 3) Scan for the first balanced {...} block that decodes (ignoring braces in strings)
Map<String, dynamic> extractAiJson(String text) {
  Map<String, dynamic>? tryDecode(String input) {
    try {
      final cleaned = input
          .replaceAll('\u200b', '') // zero width space
          .replaceAll('\ufeff', '') // BOM
          .trim();
      final dynamic decoded = jsonDecode(_stripTrailingCommas(cleaned));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  // 0) Direct attempt
  final direct = tryDecode(text);
  if (direct != null) return direct;

  String? candidate;

  // 1) ```json ... ```
  final jsonFence = RegExp(r"```json\s*([\s\S]*?)\s*```", multiLine: true);
  final jsonFenceMatch = jsonFence.firstMatch(text);
  if (jsonFenceMatch != null) {
    candidate = jsonFenceMatch.group(1)!.trim();
  }

  // 2) Any fenced block that looks like JSON
  if (candidate == null) {
    final anyFence = RegExp(r"```\s*([\s\S]*?)\s*```", multiLine: true);
    final anyFenceMatch = anyFence.firstMatch(text);
    if (anyFenceMatch != null) {
      final inner = anyFenceMatch.group(1)!.trim();
      if (inner.startsWith('{')) {
        candidate = inner;
      }
    }
  }

  if (candidate != null) {
    final parsed = tryDecode(candidate);
    if (parsed != null) return parsed;
  }

  // 3) Balanced braces scan that ignores braces within JSON strings
  {
    int depth = 0;
    int? startIndex;
    bool inString = false;
    bool isEscaped = false;

    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (inString) {
        if (isEscaped) {
          isEscaped = false; // current char is escaped, skip special handling
        } else if (ch == '\\') {
          isEscaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue; // ignore braces while inside strings
      }

      if (ch == '"') {
        inString = true;
        isEscaped = false;
        continue;
      }

      if (ch == '{') {
        depth++;
        startIndex ??= i;
      } else if (ch == '}') {
        depth--;
        if (depth == 0 && startIndex != null) {
          final sub = text.substring(startIndex, i + 1);
          final parsed = tryDecode(sub);
          if (parsed != null) return parsed;
          startIndex = null; // continue scanning for the next candidate
        }
      }
    }
  }

  throw Exception('failed to parse AI response');
}

// Remove trailing commas before } or ] which occasionally slip into LLM JSON
String _stripTrailingCommas(String input) {
  return input.replaceAll(RegExp(r",\s*(?=[}\]])"), '');
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});
}

class AIService {
  final FirestoreService _firestoreService = FirestoreService();
  String? _cachedApiKey;

  Future<String> get _apiKey async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }

    if (kIsWeb) {
      try {
        final key = await _firestoreService.getGeminiApiKey();
        if (key != null && key.isNotEmpty) {
          _cachedApiKey = key;
          return key;
        }
      } catch (e) {
        debugPrint('Failed to fetch API key from Firestore: $e');
      }
    }

    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isNotEmpty) {
      _cachedApiKey = apiKey;
      return apiKey;
    }

    final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _cachedApiKey = envKey;
    return envKey;
  }

  Future<bool> get isConfigured async {
    final key = await _apiKey;
    return key.isNotEmpty;
  }

  Future<AITutorial> generateTutorial(String topicTitle) async {
    if (!await isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }

    try {
      final String prompt = _buildPromptFromTitle(topicTitle);
      final Map<String, dynamic> response = await _callGeminiAPI(prompt);
      return _parseResponseFromTitle(response, topicTitle);
    } catch (e) {
      throw Exception('Failed to generate tutorial: $e');
    }
  }

  Future<Quiz> generateQuiz(String topicTitle) async {
    if (!await isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }

    try {
      final String prompt = _buildQuizPromptFromTitle(topicTitle);
      final Map<String, dynamic> response = await _callGeminiAPI(prompt);
      return Quiz.fromJson(response);
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }

  Future<Map<String, dynamic>> generateMindMap(String topicTitle, String summary) async {
    if (!await isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }

    try {
      final String prompt = _buildMindMapPrompt(topicTitle, summary);
      final Map<String, dynamic> response = await _callGeminiAPI(prompt);
      return response;
    } catch (e) {
      throw Exception('Failed to generate mind map: $e');
    }
  }

  String _buildMindMapPrompt(String topicTitle, String summary) {
    return '''
Create a hierarchical mind map structure for the topic: "$topicTitle"
Summary: "$summary"

Generate a tree structure with the topic as root and key concepts as branches.
Each node should have an id, label, and optional children.

Format the response as JSON with this structure:
{
  "id": "root",
  "label": "Topic Title",
  "children": [
    {
      "id": "concept1",
      "label": "Concept 1",
      "children": [
        {
          "id": "detail1",
          "label": "Detail 1",
          "children": []
        }
      ]
    }
  ]
}

Rules:
- Maximum 3 levels deep
- 3-5 main branches (children of root)
- 2-4 sub-branches per main branch
- Keep labels short (2-4 words)
- Return ONLY valid JSON
''';
  }

  // Simple chat API for AI tab
  Future<String> sendChatResponse(List<ChatMessage> messages) async {
    if (!await isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }
    try {
      return await _callGeminiChat(messages);
    } catch (e) {
      throw Exception('Failed to get chat response: $e');
    }
  }

  String _buildPromptFromTitle(String topicTitle) {
    return '''
Create a comprehensive step-by-step tutorial for the topic: "$topicTitle"

Please provide:
1. A brief summary of what the learner will achieve
2. 5-7 detailed steps, each with:
   - A clear title
   - Detailed explanation
   - Code examples (if applicable)
   - Key concepts to understand

Format the response as JSON with this structure:
{
  "summary": "Brief overview of the tutorial",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Step title",
      "content": "Detailed explanation",
      "codeExample": "code here (optional)",
      "explanation": "Why this matters"
    }
  ]
}
\nRules:\n- You must respond with ONLY valid JSON.\n- Do not include markdown, code fences, or commentary.\n- Keep each field under ~80 words to avoid truncation.
''';
  }

  String _buildQuizPromptFromTitle(String topicTitle) {
    return '''
Create a quiz to test understanding of the topic: "$topicTitle"

Generate 5 multiple-choice questions that test key concepts from this topic.

Format the response as JSON with this structure:
{
  "questions": [
    {
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswerIndex": 0,
      "explanation": "Why this is the correct answer"
    }
  ]
}

Rules:
- You must respond with ONLY valid JSON
- Each question should have exactly 4 options
- correctAnswerIndex is 0-based (0 for first option, 1 for second, etc.)
- Questions should test understanding, not just memorization
- Keep questions and explanations concise
''';
  }

  Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    // Try with a generous token budget first; retry on truncation.
    final first = await _postToGemini(prompt, maxTokens: 4096);
    final firstFinish = _readFinishReason(first);
    try {
      final String firstText = first['candidates'][0]['content']['parts'][0]['text'] as String;
      return extractAiJson(firstText);
    } catch (e) {
      // If the model hit token limit or we couldn't parse, try again with larger budget and concise prompt
      if (firstFinish == 'MAX_TOKENS') {
        final concisePrompt = _buildPromptConcise(prompt);
        final retry = await _postToGemini(concisePrompt, maxTokens: 8192);
        final String retryText = retry['candidates'][0]['content']['parts'][0]['text'] as String;
        return extractAiJson(retryText);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postToGemini(String prompt, {required int maxTokens}) async {
    final apiKey = await _apiKey;
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': maxTokens,
          'responseMimeType': 'application/json'
        }
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      debugPrint('Gemini API error: ${response.statusCode} - $errorBody');
      throw Exception('Gemini API error: ${response.statusCode}. ${errorBody.length > 100 ? errorBody.substring(0, 100) : errorBody}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String? _readFinishReason(Map<String, dynamic> data) {
    try {
      return data['candidates'][0]['finishReason'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Add a more concise version of the prompt for retries when the
  // model hits token limits.
  String _buildPromptConcise(String originalPrompt) {
    return "${originalPrompt}\n\nCONCISE MODE:\n- Use at most 5 steps.\n- Keep each string under 60 words.\n- Return ONLY JSON, no markdown.";
  }

  Future<String> _callGeminiChat(List<ChatMessage> messages) async {
    final apiKey = await _apiKey;
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    // Map messages to Gemini's content format
    final contents = messages.map((m) => {
          'role': m.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': m.content}
          ]
        }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text as String;
    } else {
      final errorBody = response.body;
      debugPrint('Gemini API chat error: ${response.statusCode} - $errorBody');
      throw Exception('Gemini API error: ${response.statusCode}. ${errorBody.length > 100 ? errorBody.substring(0, 100) : errorBody}');
    }
  }

  AITutorial _parseResponseFromTitle(Map<String, dynamic> response, String topicTitle) {
    return AITutorial(
      topicId: topicTitle.toLowerCase().replaceAll(' ', '_'),
      topicTitle: topicTitle,
      steps: (response['steps'] as List)
          .map((step) => TutorialStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      summary: response['summary'] as String,
      generatedAt: DateTime.now(),
    );
  }
}

final aiService = AIService();
