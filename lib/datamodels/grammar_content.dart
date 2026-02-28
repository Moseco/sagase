import 'package:flutter/material.dart';

abstract class ContentBlock {
  const ContentBlock();
}

class ParagraphBlock extends ContentBlock {
  final List<TextSpan> textSpans;

  const ParagraphBlock(this.textSpans);
}

class HeaderBlock extends ContentBlock {
  final String content;

  const HeaderBlock(this.content);
}

class SubheaderBlock extends ContentBlock {
  final String content;

  const SubheaderBlock(this.content);
}

class BulletedListBlock extends ContentBlock {
  final List<String> items;

  const BulletedListBlock(this.items);
}

class ExampleBlock extends ContentBlock {
  final JapaneseText japanese;
  final String english;

  const ExampleBlock({
    required this.japanese,
    required this.english,
  });
}

class JapaneseText {
  final String text;
  final String romaji;

  JapaneseText({
    required this.text,
    required this.romaji,
  });
}

class GrammarLesson {
  final String title;
  final String description;
  final List<ContentBlock> content;
  final List<dynamic> practice;

  GrammarLesson({
    required this.title,
    required this.description,
    required this.content,
    required this.practice,
  });
}
