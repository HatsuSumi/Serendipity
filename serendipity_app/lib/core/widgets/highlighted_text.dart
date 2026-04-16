import 'package:flutter/material.dart';

/// 构建高亮文本 Widget
/// 
/// 职责：在文本中高亮指定的关键词
/// 
/// 参数：
/// - text: 原始文本
/// - keywords: 要高亮的关键词列表（为空时返回普通文本）
/// - highlightColor: 高亮背景色
/// - textStyle: 文本样式
/// - maxLines: 最大行数
/// - overflow: 溢出处理
/// 
/// 调用者：记录卡片、社区帖子卡片（高亮筛选关键词）
Widget buildHighlightedText(
  String text, {
  List<String>? keywords,
  required Color highlightColor,
  TextStyle? textStyle,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final keywordList = keywords ?? [];

  if (keywordList.isEmpty) {
    return Text(
      text,
      style: textStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  final sortedKeywords = [...keywordList]..sort((a, b) => b.length.compareTo(a.length));

  final pattern = sortedKeywords.map((k) => RegExp.escape(k)).join('|');
  final regex = RegExp(pattern, caseSensitive: false);
  final matches = regex.allMatches(text).toList();

  if (matches.isEmpty) {
    return Text(
      text,
      style: textStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  final children = <TextSpan>[];
  int lastMatchEnd = 0;

  for (final match in matches) {
    if (match.start > lastMatchEnd) {
      children.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
    }

    children.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: TextStyle(
        backgroundColor: highlightColor,
        fontWeight: FontWeight.bold,
      ),
    ));

    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < text.length) {
    children.add(TextSpan(text: text.substring(lastMatchEnd)));
  }

  return RichText(
    maxLines: maxLines,
    overflow: overflow ?? TextOverflow.clip,
    text: TextSpan(
      style: textStyle,
      children: children,
    ),
  );
}

