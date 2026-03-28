# 主题响应修复任务清单

> 生成时间：2026-03-28  
> 完成时间：2026-03-28  
> 问题：`Theme.of(context).colorScheme` / `Theme.of(context).textTheme` 在 `ConsumerStatefulWidget` 子方法里存在竞态条件，导致主题切换后颜色间歇性不更新。  
> 修复方案：使用 `appColorSchemeProvider` / `appTextThemeProvider`，结果存为 `_colorScheme` / `_textTheme` 实例变量，子方法直接使用。  
> 对话框例外：对话框有独立 widget 树和 context，`Theme.of(context)` 可以正确响应，**不需要修改**。
> `StatelessWidget` 例外：父级 rebuild 后子 widget 自动 rebuild，不需要修改。

---

## 修复模板

### ConsumerStatefulWidget 页面

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

### ConsumerWidget

```dart
// build 顶部加两行 watch，子方法里 Theme.of(context) 即可
ref.watch(appColorSchemeProvider);
ref.watch(appTextThemeProvider);
```

---

## ✅ 全部完成

### Pages（13个）

| 文件 | 类型 | 说明 |
|---|---|---|
| `features/timeline/timeline_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/story_line/story_lines_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/record/create_record_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/record/record_detail_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/favorites/favorites_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/story_line/story_line_detail_page.dart` | ConsumerWidget | ✅ |
| `features/settings/profile_page.dart` | ConsumerWidget | ✅ |
| `features/settings/pages/account_settings_page.dart` | ConsumerWidget | ✅ |
| `features/settings/pages/notification_settings_page.dart` | ConsumerWidget | ✅ |
| `features/settings/pages/theme_settings_page.dart` | ConsumerWidget | ✅ |
| `features/membership/membership_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/membership/payment_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/auth/login_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/auth/register_page.dart` | ConsumerStatefulWidget | ✅ |
| `features/auth/forgot_password_page.dart` | ConsumerStatefulWidget | ✅ |

### Widgets（需修改的）

| 文件 | 类型 | 说明 |
|---|---|---|
| `features/statistics/widgets/basic_statistics_section.dart` | ConsumerWidget | ✅ |
| `features/statistics/widgets/monthly_chart_card.dart` | ConsumerWidget | ✅ |
| `features/statistics/widgets/advanced_statistics_section.dart` | ConsumerWidget | ✅ |
| `features/statistics/widgets/field_ranking_card.dart` | ConsumerWidget | ✅ |
| `features/statistics/widgets/success_rate_trend_card.dart` | ConsumerWidget | ✅ |
| `features/community/widgets/record_preview_card.dart` | ConsumerWidget | ✅ |

### Widgets（不需要修改）

| 文件 | 原因 |
|---|---|
| `features/statistics/widgets/emotion_intensity_card.dart` | StatelessWidget，父级 rebuild 后自动重建 |
| `features/statistics/widgets/place_type_distribution_card.dart` | StatelessWidget |
| `features/statistics/widgets/success_rate_trend_card.dart` | StatelessWidget |
| `features/statistics/widgets/tag_cloud_card.dart` | StatelessWidget |
| `features/statistics/widgets/weather_distribution_card.dart` | StatelessWidget |
| `features/record/widgets/tags_section.dart` | StatefulWidget（无 ref） |
| `features/record/widgets/weather_selection_section.dart` | StatefulWidget（无 ref） |
| `features/about/widgets/about_section_card.dart` | StatelessWidget |
| `features/about/widgets/about_support_cards.dart` | StatelessWidget |
| `features/auth/widgets/auth_text_field.dart` | StatelessWidget |
| `core/widgets/empty_state_widget.dart` | StatelessWidget |
| `core/utils/message_helper.dart` | 静态工具类，context 由调用方传入，无竞态 |

---

## 🟢 对话框（不需要修改）

> 对话框有独立 widget 树，`Theme.of(context)` 在对话框 context 下能正确响应主题。

| 文件 |
|---|
| `features/auth/widgets/recovery_key_dialog.dart` |
| `features/community/dialogs/publish_confirm_dialog.dart` |
| `features/community/dialogs/publish_to_community_dialog.dart` |
| `features/community/dialogs/publish_warning_dialog.dart` |
| `features/home/anniversary_reminder_dialog.dart` |
| `features/record/widgets/location_permission_dialog.dart` |
| `features/record/widgets/place_history_dialog.dart` |
| `features/record/widgets/story_line_selection_dialog.dart` |
| `features/settings/dialogs/manual_sync_dialog.dart` |
| `features/settings/dialogs/sync_history_dialog.dart` |
| `features/settings/dialogs/sync_info_dialog.dart` |
| `features/story_line/add_existing_records_dialog.dart` |
| `features/story_line/link_to_story_line_dialog.dart` |

---

## 📝 注意事项

1. **对话框不需要改**：对话框的 context 是独立的
2. **StatelessWidget 不需要改**：父级 ConsumerWidget/ConsumerStatefulWidget 已 watch Provider，rebuild 时子 StatelessWidget 自动重建
3. **`system` 主题**：`appColorSchemeProvider` 在 system 主题下返回浅色 ColorScheme，深色由 `MaterialApp.darkTheme` 处理
4. **`statusColor`**：已由 `status_color_extension.dart` 单独处理，不在此任务范围内
