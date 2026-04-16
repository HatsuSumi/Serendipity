/// 标签解析工具函数
/// 
/// 职责：解析用户输入的逗号分隔关键词字符串
/// 
/// 调用者：各筛选对话框
List<String>? parseCommaSeparatedKeywords(String input) {
  if (input.isEmpty) return null;

  final keywords = input
      .replaceAll('，', ',')
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();

  return keywords.isEmpty ? null : keywords;
}

/// 标签解析工具函数
/// 
/// 职责：解析用户输入的标签字符串
/// 
/// 调用者：各筛选对话框
List<String>? parseTags(String input) {
  return parseCommaSeparatedKeywords(input);
}

