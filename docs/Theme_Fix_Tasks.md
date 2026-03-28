# 主题响应修复任务清单

> 生成时间：2026-03-28  
> 问题：`Theme.of(context).colorScheme` / `Theme.of(context).textTheme` 在 `ConsumerStatefulWidget` 子方法里存在竞态条件，导致主题切换后颜色间歇性不更新。  
> 修复方案：使用 `appColorSchemeProvider` / `appTextThemeProvider`，结果存为 `_colorScheme` / `_textTheme` 实例变量，子方法直接使用。  
> 对话框例外：对话框有独立 widget 树和 context，`Theme.of(context)` 可以正确响应，**不需要修改**。

---

## 修复模板

### StatefulWidget 页面 / Widget

```dart
// 1. 添加实例变量
late ColorScheme _colorScheme;
late TextTheme _textTheme;

// 2. build 顶部 watch
_colorScheme = ref.watch(appColorSchemeProvider);
_textTheme = ref.watch(appTextThemeProvider);

// 3. import
import '../../core/providers/theme_provider.dart' show appColorSchemeProvider, appTextThemeProvider;

// 4. 子方法里用 _colorScheme / _textTheme 替换 Theme.of(context).colorScheme / textTheme
```

### StatelessWidget / ConsumerWidget

```dart
// 直接在 build 里 watch
final colorScheme = ref.watch(appColorSchemeProvider);
final textTheme = ref.watch(appTextThemeProvider);
```

---

## ✅ 已完成

| 文件 | 类型 | 完成时间 |
|---|---|---|
| `features/timeline/timeline_page.dart` | Page (StatefulWidget) | 2026-03-28 |
| `features/story_line/story_lines_page.dart` | Page (StatefulWidget) | 2026-03-28 |

---

## 🔴 待修复 — Pages（优先）

> 页面是用户直接看到的，优先修复

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 1 | `features/record/create_record_page.dart` | Page | 创建记录页，最大单文件 |
| 2 | `features/record/record_detail_page.dart` | Page | 记录详情页 |
| 3 | `features/favorites/favorites_page.dart` | Page | 收藏页 |
| 4 | `features/story_line/story_line_detail_page.dart` | Page | 故事线详情页 |
| 5 | `features/settings/profile_page.dart` | Page | 我的页面 |
| 6 | `features/settings/pages/account_settings_page.dart` | Page | 账号设置页 |
| 7 | `features/settings/pages/notification_settings_page.dart` | Page | 通知设置页 |
| 8 | `features/settings/pages/theme_settings_page.dart` | Page | 主题设置页 |
| 9 | `features/membership/membership_page.dart` | Page | 会员页 |
| 10 | `features/membership/payment_page.dart` | Page | 支付页 |
| 11 | `features/auth/login_page.dart` | Page | 登录页 |
| 12 | `features/auth/register_page.dart` | Page | 注册页 |
| 13 | `features/auth/forgot_password_page.dart` | Page | 忘记密码页 |

---

## 🟡 待修复 — Widgets（次优先）

> Widget 被页面复用，修复后所有引用页面都受益

| # | 文件 | 类型 | 说明 |
|---|---|---|---|
| 14 | `features/statistics/widgets/basic_statistics_section.dart` | Widget | 基础统计区（738行，最复杂）|
| 15 | `features/statistics/widgets/monthly_chart_card.dart` | Widget | 月度图表卡片 |
| 16 | `features/statistics/widgets/advanced_statistics_section.dart` | Widget | 高级统计区 |
| 17 | `features/statistics/widgets/emotion_intensity_card.dart` | Widget | 情绪强度卡片 |
| 18 | `features/statistics/widgets/field_ranking_card.dart` | Widget | 字段排名卡片 |
| 19 | `features/statistics/widgets/place_type_distribution_card.dart` | Widget | 地点类型分布卡片 |
| 20 | `features/statistics/widgets/success_rate_trend_card.dart` | Widget | 成功率趋势卡片 |
| 21 | `features/statistics/widgets/tag_cloud_card.dart` | Widget | 标签云卡片 |
| 22 | `features/statistics/widgets/weather_distribution_card.dart` | Widget | 天气分布卡片 |
| 23 | `features/record/widgets/tags_section.dart` | Widget | 标签区域 |
| 24 | `features/record/widgets/weather_selection_section.dart` | Widget | 天气选择区域 |
| 25 | `features/community/widgets/record_preview_card.dart` | Widget | 社区记录预览卡片 |
| 26 | `features/about/widgets/about_section_card.dart` | Widget | 关于页区域卡片 |
| 27 | `features/about/widgets/about_support_cards.dart` | Widget | 关于页支持卡片 |
| 28 | `features/auth/widgets/auth_text_field.dart` | Widget | 认证输入框 |
| 29 | `core/widgets/empty_state_widget.dart` | Widget | 空状态组件（全局复用）|
| 30 | `core/utils/message_helper.dart` | Util | 消息提示工具 |

---

## 🟢 对话框（不需要修改）

> 对话框有独立 widget 树，`Theme.of(context)` 在对话框 context 下能正确响应主题。

| 文件 | 说明 |
|---|---|
| `features/auth/widgets/recovery_key_dialog.dart` | 恢复密钥对话框 |
| `features/community/dialogs/publish_confirm_dialog.dart` | 发布确认对话框 |
| `features/community/dialogs/publish_to_community_dialog.dart` | 发布到社区对话框 |
| `features/community/dialogs/publish_warning_dialog.dart` | 发布警告对话框 |
| `features/home/anniversary_reminder_dialog.dart` | 纪念日提醒对话框 |
| `features/record/widgets/location_permission_dialog.dart` | 位置权限对话框 |
| `features/record/widgets/place_history_dialog.dart` | 地点历史对话框 |
| `features/record/widgets/story_line_selection_dialog.dart` | 故事线选择对话框 |
| `features/settings/dialogs/manual_sync_dialog.dart` | 手动同步对话框 |
| `features/settings/dialogs/sync_history_dialog.dart` | 同步历史对话框 |
| `features/settings/dialogs/sync_info_dialog.dart` | 同步信息对话框 |
| `features/story_line/add_existing_records_dialog.dart` | 添加已有记录对话框 |
| `features/story_line/link_to_story_line_dialog.dart` | 关联故事线对话框 |

---

## 📝 注意事项

1. **对话框不需要改**：对话框的 context 是独立的，`Theme.of(context)` 在对话框内是正确的
2. **`system` 主题**：`appColorSchemeProvider` 在 system 主题下返回浅色 ColorScheme，深色由 `MaterialApp.darkTheme` 处理，页面整体背景色正确，只有显式用 colorScheme 的颜色值会固定为浅色——如果有问题再单独处理
3. **`statusColor`**：已由 `status_color_extension.dart` 单独处理，不在此任务范围内
4. **修完一个 commit 一次**，便于回滚

