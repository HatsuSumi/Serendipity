# 代码拆分任务清单

> 生成时间：2026-03-28
> 基于 `count_lines.ps1` 扫描结果，聚焦 Flutter dart 源码文件
> 非空行数阈值：Page > 400 / Widget > 150 / Provider > 200 / Service > 300

---

## 🔴 优先级 P0（严重超标，影响可维护性）

### 1. `create_record_page.dart` — 2343 行
- **路径**：`serendipity_app/lib/features/record/create_record_page.dart`
- **类型**：Page
- **问题**：整个项目最大单文件，远超合理范围
- **拆分方向**：
  - 提取位置选择区域 → `widgets/location_section.dart`
  - 提取标签区域（已有 `tags_section.dart`，检查是否还有内联逻辑）
  - 提取天气选择区域（已有 `weather_selection_section.dart`，同上）
  - 提取故事线关联区域 → `widgets/story_line_section.dart`
  - 提取表单验证逻辑 → 移至 Provider 或独立 helper
  - 主页面精简为组装层

### 2. `timeline_page.dart` — 862 行
- **路径**：`serendipity_app/lib/features/timeline/timeline_page.dart`
- **类型**：Page
- **问题**：核心功能页，UI + 筛选 + 卡片构建全部内联
- **拆分方向**：
  - 提取记录卡片 → `widgets/timeline_record_card.dart`
  - 提取筛选栏 → `widgets/timeline_filter_bar.dart`
  - 筛选逻辑已有 `record_filter_dialog.dart`，检查是否还有冗余

### 3. `statistics/widgets/basic_statistics_section.dart` — 738 行
- **路径**：`serendipity_app/lib/features/statistics/widgets/basic_statistics_section.dart`
- **类型**：Widget
- **问题**：一个 Widget 组件 738 行，职责严重过重
- **拆分方向**：
  - 按统计卡片类型拆分为多个子 Widget
  - 参考同目录已有的细粒度 widget（`monthly_chart_card.dart` 等）

---

## 🔴 优先级 P1（明显超标）

### 4. `record_detail_page.dart` — 780 行
- **路径**：`serendipity_app/lib/features/record/record_detail_page.dart`
- **类型**：Page
- **拆分方向**：
  - 提取详情头部卡片 → `widgets/record_detail_header.dart`
  - 提取标签展示区 → `widgets/record_tags_view.dart`
  - 提取操作按钮组 → `widgets/record_action_bar.dart`

### 5. `core/widgets/common_filter_widgets.dart` — 645 行
- **路径**：`serendipity_app/lib/core/widgets/common_filter_widgets.dart`
- **类型**：Widget 集合
- **问题**：多个不相关 widget 堆在一个文件
- **拆分方向**：按 widget 类型拆分为独立文件

### 6. `core/services/storage_service.dart` — 617 行
- **路径**：`serendipity_app/lib/core/services/storage_service.dart`
- **类型**：Service
- **拆分方向**：
  - 按存储域拆分（记录存储、设置存储、同步历史存储等）
  - 或提取为多个 repository 方法

### 7. `story_line/story_lines_page.dart` — 616 行
- **路径**：`serendipity_app/lib/features/story_line/story_lines_page.dart`
- **类型**：Page
- **拆分方向**：
  - 提取故事线卡片 → `widgets/story_line_card.dart`
  - 提取空状态/加载状态

### 8. `story_line/story_line_detail_page.dart` — 539 行
- **路径**：`serendipity_app/lib/features/story_line/story_line_detail_page.dart`
- **类型**：Page
- **拆分方向**：
  - 提取统计概览区域
  - 提取记录列表区域

### 9. `core/providers/records_provider.dart` — 538 行
- **路径**：`serendipity_app/lib/core/providers/records_provider.dart`
- **类型**：Provider
- **拆分方向**：
  - 拆分读取逻辑与写入逻辑
  - 筛选相关 provider 已有 `records_filter_provider.dart`，检查是否还有冗余

### 10. `check_in/check_in_page.dart` — 514 行
- **路径**：`serendipity_app/lib/features/check_in/check_in_page.dart`
- **类型**：Page
- **拆分方向**：
  - 提取签到历史列表区域
  - 提取签到按钮区域（已有 `check_in_button.dart`，检查主页面是否还有内联）

### 11. `sync_service.dart` — 892 行
- **路径**：`serendipity_app/lib/core/services/sync_service.dart`
- **类型**：Service
- **拆分方向**：
  - 已有 `sync_orchestrator.dart`，检查职责边界是否清晰
  - 按同步方向拆分（上传逻辑 / 下载逻辑 / 冲突处理）

---

## 🟡 优先级 P2（接近上限，可观察）

| 文件 | 非空行数 | 备注 |
|---|---|---|
| `settings/pages/account_settings_page.dart` | 534 | 对话框密集型，暂可接受 |
| `core/providers/user_settings_provider.dart` | 484 | 接近 Provider 上限 |
| `core/providers/auth_provider.dart` | 477 | 接近 Provider 上限 |
| `community/widgets/region_picker_dialog.dart` | 424 | Widget 超标 |
| `statistics/widgets/monthly_chart_card.dart` | 412 | Widget 超标 |
| `core/services/sync_service.dart` | 892 | 已列 P1 |

---

## ✅ 已完成的拆分

| 原文件 | 拆分结果 | 完成时间 |
|---|---|---|
| `settings/profile_page.dart`（1880行） | `profile_page.dart` + `pages/notification_settings_page.dart` + `pages/theme_settings_page.dart` + `pages/account_settings_page.dart` + `pages/dev_tools_page.dart` | 2026-03-28 |
| `settings/favorites_page.dart` | 迁移至 `features/favorites/favorites_page.dart` | 2026-03-28 |
| `settings/dialogs/favorites_intro_dialog.dart` | 迁移至 `features/favorites/favorites_intro_dialog.dart` | 2026-03-28 |

---

## 📝 拆分原则

1. **语义归属**：文件放在功能域目录下，而非入口目录
2. **职责单一**：一个文件只做一件事
3. **子页面优于内联**：设置类、管理类功能统一跳转子页面
4. **Widget 粒度**：独立可复用的 UI 块提取为独立文件
5. **禁止用 PowerShell Get-Content/Set-Content 修改 UTF-8 文件**（会乱码，用 Write 工具）

