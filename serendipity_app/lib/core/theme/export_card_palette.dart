import 'package:flutter/material.dart';

/// 导出图片卡片共用配色。
///
/// 说明：
/// - 导出图属于品牌化卡片，不跟随运行时主题
/// - 统一在此维护浅色主题基底，避免各导出卡片重复硬编码
/// - 各卡片只传入自己的强调色，保留模块识别度
class ExportCardPalette {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color dividerColor;
  final Color accentColor;

  const ExportCardPalette({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.dividerColor,
    required this.accentColor,
  });

  factory ExportCardPalette.light({required Color accentColor}) {
    return ExportCardPalette(
      backgroundColor: const Color(0xFFF8F3EC),
      surfaceColor: Colors.white,
      primaryTextColor: const Color(0xFF2C241E),
      secondaryTextColor: const Color(0xFF7A6E66),
      dividerColor: const Color(0xFFE7D8CB),
      accentColor: accentColor,
    );
  }
}

