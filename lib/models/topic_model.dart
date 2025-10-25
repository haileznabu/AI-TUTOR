import 'package:flutter/material.dart';

@immutable
class Topic {
  final String id;
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final int estimatedMinutes;
  final String difficulty;

  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.estimatedMinutes,
    required this.difficulty,
  });
}

@immutable
class TutorialStep {
  final int stepNumber;
  final String title;
  final String content;
  final String? codeExample;
  final String? explanation;

  const TutorialStep({
    required this.stepNumber,
    required this.title,
    required this.content,
    this.codeExample,
    this.explanation,
  });

  factory TutorialStep.fromJson(Map<String, dynamic> json) {
    final dynamic rawStep = json['stepNumber'];
    final int stepNo = rawStep is int
        ? rawStep
        : int.tryParse(rawStep.toString()) ?? 1;
    return TutorialStep(
      stepNumber: stepNo,
      title: json['title'] as String,
      content: json['content'] as String,
      codeExample: json['codeExample'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'content': content,
      'codeExample': codeExample,
      'explanation': explanation,
    };
  }
}

@immutable
class AITutorial {
  final String topicId;
  final String topicTitle;
  final List<TutorialStep> steps;
  final String summary;
  final DateTime generatedAt;

  const AITutorial({
    required this.topicId,
    required this.topicTitle,
    required this.steps,
    required this.summary,
    required this.generatedAt,
  });

  factory AITutorial.fromJson(Map<String, dynamic> json) {
    return AITutorial(
      topicId: json['topicId'] as String,
      topicTitle: json['topicTitle'] as String,
      steps: (json['steps'] as List)
          .map((step) => TutorialStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicTitle': topicTitle,
      'steps': steps.map((step) => step.toJson()).toList(),
      'summary': summary,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
