# 状态颜色系统设计文档

## 概述

状态颜色系统负责为不同的记录状态提供主题自适应的情感色调。

## 设计原则

1. **情感基调不变**：每个状态的情感色调保持一致（如"错过"始终是灰蓝色调）
2. **主题自适应**：根据当前主题调整亮度/饱和度
3. **对比度保证**：确保在浅色和深色主题下都有足够的对比度
4. **架构清晰**：集中管理，易于维护和扩展

## 架构设计

```
core/theme/
├── status_colors.dart           # 核心颜色计算逻辑
├── status_color_extension.dart  # 便捷的扩展方法
├── app_theme.dart               # 应用主题定义
└── theme.dart                   # 统一导出
```

### 1. StatusColors 类

核心颜色计算类，负责根据状态、主题选项和亮度返回对应的颜色。

**方法**：
- `getColor(status, themeOption, brightness)` - 获取状态颜色

**设计特点**：
- 每个状态有独立的颜色计算方法
- 针对7种主题分别定义颜色
- 深色模式自动提高亮度，确保对比度

### 2. StatusColorExtension 扩展

为 `EncounterStatus` 枚举添加便捷的颜色获取方法。

**使用示例**：
```dart
// 在 ConsumerWidget 中使用
final color = record.status.getColor(context, ref);
```

**优势**：
- 语义清晰，调用简洁
- 自动获取当前主题和系统亮度
- 无需手动传递参数

## 状态颜色定义

### 错过 🌫️
- **情感基调**：朦胧、柔和、灰蓝色调
- **浅色模式**：`#7B9EB0`
- **深色模式**：`#9DB8C7`（提高亮度）
- **朦胧主题**：`#6B8E9F`（强化灰蓝）
- **深夜主题**：`#B0C4D0`（冷色调）
- **温暖主题**：`#8FAAB8`（加入暖色）
- **秋日主题**：`#8B9FA8`（加入棕色）

### 再遇 🌟
- **情感基调**：明亮、惊喜、金色点缀
- **浅色模式**：`#FFD700`（纯金色）
- **深色模式**：`#FFE066`（降低饱和度）
- **朦胧主题**：`#E8C547`（柔和金色）
- **深夜主题**：`#FFF176`（冷金色）
- **温暖主题**：`#FFCA28`（暖金色）
- **秋日主题**：`#FFB300`（琥珀金）

### 邂逅 💫
- **情感基调**：温暖、激动、粉橙色调
- **浅色模式**：`#FF9E80`
- **深色模式**：`#FFAB91`（提高亮度）
- **朦胧主题**：`#FF8A65`（柔和粉橙）
- **深夜主题**：`#FFB74D`（明亮粉橙）
- **温暖主题**：`#FF9E80`（暖橙色）
- **秋日主题**：`#FF7043`（深橙色）

### 重逢 💝
- **情感基调**：圆满、幸福、玫瑰金色调
- **浅色模式**：`#E91E63`
- **深色模式**：`#F06292`（提高亮度）
- **朦胧主题**：`#EC407A`（柔和玫瑰）
- **深夜主题**：`#F48FB1`（明亮玫瑰）
- **温暖主题**：`#E91E63`（暖玫瑰）
- **秋日主题**：`#C2185B`（深玫瑰）

### 别离 🥀
- **情感基调**：淡然、接受、玫瑰灰色调
- **浅色模式**：`#BCAAA4`
- **深色模式**：`#D7CCC8`（提高亮度）
- **朦胧主题**：`#B0A199`（冷灰色）
- **深夜主题**：`#E0D5D0`（明亮灰）
- **温暖主题**：`#C9B8B0`（暖灰色）
- **秋日主题**：`#A1887F`（棕灰色）

### 失联 🍂
- **情感基调**：平静、释怀、秋叶色调
- **浅色模式**：`#D4A574`
- **深色模式**：`#E0B589`（提高亮度）
- **朦胧主题**：`#C89F6F`（冷秋色）
- **深夜主题**：`#ECC89E`（明亮秋色）
- **温暖主题**：`#DDB87A`（暖秋色）
- **秋日主题**：`#BF8F5F`（深秋色）

## 使用指南

### 在页面中使用

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/status_color_extension.dart';

class MyPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ...;
    
    // 获取状态颜色
    final statusColor = record.status.getColor(context, ref);
    
    // 使用颜色
    return Container(
      color: statusColor.withOpacity(0.1),
      child: Text(
        record.status.label,
        style: TextStyle(color: statusColor),
      ),
    );
  }
}
```

### 添加新主题

如果需要添加新主题，只需在 `StatusColors` 类中为每个状态添加对应的颜色分支：

```dart
static Color _getMissedColor(ThemeOption themeOption, bool isDark) {
  switch (themeOption) {
    // ... 现有主题
    
    case ThemeOption.newTheme:
      return const Color(0xFFXXXXXX); // 新主题的颜色
  }
}
```

## 优势

1. **集中管理**：所有状态颜色定义在一个文件中，易于维护
2. **类型安全**：使用枚举和扩展方法，编译时检查
3. **易于使用**：一行代码即可获取主题自适应的颜色
4. **易于扩展**：添加新主题或新状态只需修改一个文件
5. **性能优化**：颜色计算简单，无需缓存

## 测试建议

1. **视觉测试**：在所有7种主题下检查每个状态的颜色
2. **对比度测试**：确保在浅色和深色模式下文字可读
3. **一致性测试**：确保同一状态在不同页面显示的颜色一致

## 未来优化

1. 可以考虑添加颜色动画过渡
2. 可以考虑添加用户自定义状态颜色功能（会员专属）
3. 可以考虑根据时间段自动调整颜色（如夜间模式更柔和）

