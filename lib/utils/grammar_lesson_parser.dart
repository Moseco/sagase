import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sagase/datamodels/grammar_content.dart';

class GrammarLessonParser {
  static Future<GrammarLesson> parseFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return parseFromJson(jsonString);
  }

  static GrammarLesson parseFromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return _parseGrammarLesson(json);
  }

  static GrammarLesson _parseGrammarLesson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? '';
    final description = json['description'] as String? ?? '';
    final contentList = json['content'] as List<dynamic>? ?? [];
    final practice = json['practice'] as List<dynamic>? ?? [];

    final content = contentList
        .map((item) => _parseContentBlock(item as Map<String, dynamic>))
        .toList();

    return GrammarLesson(
      title: title,
      description: description,
      content: content,
      practice: practice,
    );
  }

  static ContentBlock _parseContentBlock(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'paragraph':
        return _parseParagraphBlock(json);
      case 'header':
        return _parseHeaderBlock(json);
      case 'subheader':
        return _parseSubheaderBlock(json);
      case 'example':
        return _parseExampleBlock(json);
      case 'bulleted-list':
        return _parseBulletedListBlock(json);
      default:
        return ParagraphBlock(const []);
    }
  }

  static ParagraphBlock _parseParagraphBlock(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    final textSpans = <TextSpan>[];

    for (final item in contentList) {
      if (item is Map<String, dynamic>) {
        final itemType = item['type'] as String?;
        final text = item['text'] as String?;

        if (itemType == 'text' && text != null) {
          textSpans.add(TextSpan(text: text));
        }
      }
    }

    return ParagraphBlock(textSpans);
  }

  static HeaderBlock _parseHeaderBlock(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    return HeaderBlock(content);
  }

  static SubheaderBlock _parseSubheaderBlock(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    return SubheaderBlock(content);
  }

  static ExampleBlock _parseExampleBlock(Map<String, dynamic> json) {
    final japaneseObj = json['japanese'] as Map<String, dynamic>?;
    final englishText = json['english'] as String? ?? '';

    final japanese = JapaneseText(
      text: japaneseObj?['text'] as String? ?? '',
      romaji: japaneseObj?['romaji'] as String? ?? '',
    );

    return ExampleBlock(
      japanese: japanese,
      english: englishText,
    );
  }

  static BulletedListBlock _parseBulletedListBlock(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    final items = <String>[];

    for (final item in contentList) {
      if (item is Map<String, dynamic>) {
        final itemType = item['type'] as String?;
        final text = item['text'] as String?;

        if (itemType == 'text' && text != null) {
          items.add(text);
        }
      }
    }

    return BulletedListBlock(items);
  }
}
