import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/advanced_statistics_section.dart';
import 'widgets/basic_statistics_section.dart';

/// 统计页面
/// 
/// 职责：
/// - 展示用户的记录统计数据
/// - 支持基础统计（免费）和高级统计（会员）
/// - 提供会员升级入口
/// 
/// 设计原则：
/// - 分层约束：只负责 UI 展示，不涉及业务逻辑
/// - 单一职责：只展示统计数据，不处理数据计算
/// - 依赖倒置：依赖 Provider，不依赖具体的数据源
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 24),
            const SizedBox(width: 8),
            const Text('我的记录统计'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BasicStatisticsSection(),
              const SizedBox(height: 24),
              const AdvancedStatisticsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
