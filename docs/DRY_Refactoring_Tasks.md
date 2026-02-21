# DRY 重构任务追踪

> **创建时间**: 2026-02-21  
> **目标**: 消除项目中的跨文件代码重复问题  
> **预期收益**: 减少 500-800 行重复代码，提升可维护性和一致性

---

## 📊 任务概览

| 任务ID | 任务名称 | 优先级 | 状态 | 预计行数减少 |
|--------|---------|--------|------|-------------|
| DRY-1 | 日期时间格式化工具类 | P0 | ⏳ 待开始 | ~60 行 |
| DRY-2 | 地点文本获取工具类 | P0 | ⏳ 待开始 | ~36 行 |
| DRY-3 | 空状态UI通用组件 | P1 | ⏳ 待开始 | ~100 行 |
| DRY-4 | 删除确认对话框 | P0 | ⏳ 待开始 | ~120 行 |
| DRY-5 | 重命名对话框 | P1 | ⏳ 待开始 | ~70 行 |
| DRY-6 | 页面导航工具方法 | P0 | ⏳ 待开始 | ~150 行 |
| DRY-7 | 排序逻辑工具类 | P2 | ⏳ 待开始 | ~60 行 |

**总计**: 预计减少约 **596 行**重复代码

---

## 🔴 P0 优先级任务（必须立即修复）

### ✅ DRY-1: 日期时间格式化工具类

**问题描述**:  
日期格式化函数在多个文件中重复实现，包括 `_formatDate`、`_formatTime`、`_formatDateTime` 等。

**重复位置**:
- [x] `lib/features/story_line/story_line_detail_page.dart:565` - `_formatDate()`
- [x] `lib/features/story_line/add_existing_records_dialog.dart:238` - `_formatDate()`
- [x] `lib/features/timeline/timeline_page.dart:467` - `_formatTime()`
- [x] `lib/features/record/record_detail_page.dart:766` - `_formatDateTime()`

**解决方案**:
1. 创建 `lib/core/utils/date_time_helper.dart`
2. 实现以下静态方法：
   - `formatShortDate(DateTime)` - 格式化为 `2024.01.15`
   - `formatDateTime(DateTime)` - 格式化为 `2024-01-15 14:30`
   - `formatRelativeTime(DateTime)` - 格式化为相对时间（今天、昨天、X天前）
3. 替换所有使用位置

**修改文件**:
- [x] 新建: `lib/core/utils/date_time_helper.dart`
- [x] 修改: `lib/features/story_line/story_line_detail_page.dart`
- [x] 修改: `lib/features/story_line/add_existing_records_dialog.dart`
- [x] 修改: `lib/features/timeline/timeline_page.dart`
- [x] 修改: `lib/features/record/record_detail_page.dart`

**测试要点**:
- [x] 验证日期格式化输出正确
- [x] 验证相对时间计算准确（今天、昨天、X天前）
- [x] 验证所有页面显示一致

**代码减少**: 约 60 行

**状态**: ✅ 已完成 (2026-02-21)

---

### ✅ DRY-2: 地点文本获取工具类

**问题描述**:  
`_getLocationText()` 函数在多个文件中完全重复。

**重复位置**:
- [x] `lib/features/story_line/story_line_detail_page.dart:571`
- [x] `lib/features/story_line/add_existing_records_dialog.dart:244`
- [x] `lib/features/timeline/timeline_page.dart` (简化版本)

**解决方案**:
1. 创建 `lib/core/utils/record_helper.dart`
2. 实现 `getLocationText(EncounterRecord)` 静态方法
3. 替换所有使用位置

**修改文件**:
- [x] 新建: `lib/core/utils/record_helper.dart`
- [x] 修改: `lib/features/story_line/story_line_detail_page.dart`
- [x] 修改: `lib/features/story_line/add_existing_records_dialog.dart`
- [x] 修改: `lib/features/timeline/timeline_page.dart`

**测试要点**:
- [x] 验证地点名称优先级正确（placeName > address > placeType > 未知地点）
- [x] 验证所有页面显示一致

**代码减少**: 约 36 行

**状态**: ✅ 已完成 (2026-02-21)

---

### ✅ DRY-4: 删除确认对话框

**问题描述**:  
删除确认对话框在多个文件中重复实现，结构高度相似。

**重复位置**:
- [ ] `lib/features/story_line/story_lines_page.dart:442`
- [ ] `lib/features/story_line/story_line_detail_page.dart:488`
- [ ] `lib/features/record/record_detail_page.dart:735`
- [ ] `lib/features/timeline/timeline_page.dart:413`

**解决方案**:
1. 在 `lib/core/utils/dialog_helper.dart` 中添加 `showDeleteConfirm()` 方法
2. 支持自定义标题和内容
3. 返回 `Future<bool?>` 表示用户选择
4. 替换所有使用位置

**修改文件**:
- [ ] 修改: `lib/core/utils/dialog_helper.dart`
- [ ] 修改: `lib/features/story_line/story_lines_page.dart`
- [ ] 修改: `lib/features/story_line/story_line_detail_page.dart`
- [ ] 修改: `lib/features/record/record_detail_page.dart`
- [ ] 修改: `lib/features/timeline/timeline_page.dart`

**测试要点**:
- [ ] 验证对话框正确显示
- [ ] 验证取消操作返回 false
- [ ] 验证确认操作返回 true
- [ ] 验证对话框动画正常

**状态**: ⏳ 待开始

---

### ✅ DRY-6: 页面导航工具方法

**问题描述**:  
页面导航代码在多个文件中重复，包括动画类型选择和 PageRouteBuilder 构建。

**重复位置**:
- [ ] `lib/features/story_line/story_lines_page.dart:213`
- [ ] `lib/features/story_line/story_line_detail_page.dart:398, 520`
- [ ] `lib/features/timeline/timeline_page.dart:349, 388`
- [ ] `lib/features/record/record_detail_page.dart:68, 113`

**解决方案**:
1. 在 `lib/core/utils/navigation_helper.dart` 中添加 `pushWithTransition()` 方法
2. 自动处理动画类型选择和 PageRouteBuilder 构建
3. 替换所有使用位置

**修改文件**:
- [ ] 修改: `lib/core/utils/navigation_helper.dart`
- [ ] 修改: `lib/features/story_line/story_lines_page.dart`
- [ ] 修改: `lib/features/story_line/story_line_detail_page.dart`
- [ ] 修改: `lib/features/timeline/timeline_page.dart`
- [ ] 修改: `lib/features/record/record_detail_page.dart`

**测试要点**:
- [ ] 验证页面跳转动画正常
- [ ] 验证随机动画模式工作正常
- [ ] 验证无动画模式工作正常
- [ ] 验证返回值正确传递

**状态**: ⏳ 待开始

---

## 🟡 P1 优先级任务（重要但不紧急）

### ✅ DRY-3: 空状态UI通用组件

**问题描述**:  
空状态UI在多个页面中重复实现，结构完全相同，仅图标和文本不同。

**重复位置**:
- [ ] `lib/features/story_line/story_lines_page.dart:167`
- [ ] `lib/features/story_line/story_line_detail_page.dart:137`
- [ ] `lib/features/timeline/timeline_page.dart:127`
- [ ] `lib/features/story_line/add_existing_records_dialog.dart:109`

**解决方案**:
1. 创建 `lib/core/widgets/empty_state_widget.dart`
2. 支持自定义图标、标题、描述
3. 替换所有使用位置

**修改文件**:
- [ ] 新建: `lib/core/widgets/empty_state_widget.dart`
- [ ] 修改: `lib/features/story_line/story_lines_page.dart`
- [ ] 修改: `lib/features/story_line/story_line_detail_page.dart`
- [ ] 修改: `lib/features/timeline/timeline_page.dart`
- [ ] 修改: `lib/features/story_line/add_existing_records_dialog.dart`

**测试要点**:
- [ ] 验证空状态UI正确显示
- [ ] 验证主题适配正常
- [ ] 验证所有页面样式一致

**状态**: ⏳ 待开始

---

### ✅ DRY-5: 重命名对话框

**问题描述**:  
重命名对话框在两个文件中重复实现。

**重复位置**:
- [ ] `lib/features/story_line/story_lines_page.dart:407`
- [ ] `lib/features/story_line/story_line_detail_page.dart:454`

**解决方案**:
1. 在 `lib/core/utils/dialog_helper.dart` 中添加 `showRenameDialog()` 方法
2. 支持自定义标题、初始值、提示文本
3. 返回 `Future<String?>` 表示新名称
4. 替换所有使用位置

**修改文件**:
- [ ] 修改: `lib/core/utils/dialog_helper.dart`
- [ ] 修改: `lib/features/story_line/story_lines_page.dart`
- [ ] 修改: `lib/features/story_line/story_line_detail_page.dart`

**测试要点**:
- [ ] 验证对话框正确显示
- [ ] 验证初始值正确填充
- [ ] 验证空值验证正常
- [ ] 验证返回值正确

**状态**: ⏳ 待开始

---

## 🟢 P2 优先级任务（可选优化）

### ✅ DRY-7: 排序逻辑工具类

**问题描述**:  
排序逻辑（包括置顶处理）在两个文件中重复。

**重复位置**:
- [ ] `lib/features/story_line/story_lines_page.dart:138`
- [ ] `lib/features/timeline/timeline_page.dart:95`

**解决方案**:
1. 创建 `lib/core/utils/sort_helper.dart`
2. 实现 `sortWithPin()` 泛型方法
3. 替换所有使用位置

**修改文件**:
- [ ] 新建: `lib/core/utils/sort_helper.dart`
- [ ] 修改: `lib/features/story_line/story_lines_page.dart`
- [ ] 修改: `lib/features/timeline/timeline_page.dart`

**测试要点**:
- [ ] 验证排序逻辑正确
- [ ] 验证置顶项始终在前
- [ ] 验证稳定排序

**状态**: ⏳ 待开始

---

## 📝 修改日志

### 2026-02-21

#### 第一阶段：地点文本获取重构 (DRY-2)
- ✅ 创建 DRY 重构任务追踪文档
- ✅ 创建 `RecordHelper` 工具类
- ✅ 实现 `getLocationText()` 静态方法，支持完整的优先级逻辑
- ✅ 替换 `add_existing_records_dialog.dart` 中的重复代码
- ✅ 替换 `story_line_detail_page.dart` 中的重复代码
- ✅ 替换 `timeline_page.dart` 中的简化版本，统一为完整逻辑
- ✅ 删除 3 个重复的 `_getLocationText()` 方法
- 📊 减少约 36 行重复代码

#### 第二阶段：日期时间格式化重构 (DRY-1)
- ✅ 创建 `DateTimeHelper` 工具类
- ✅ 实现 `formatShortDate()` - 格式化为 `2024.01.15`
- ✅ 实现 `formatDateTime()` - 格式化为 `2024-01-15 14:30`
- ✅ 实现 `formatRelativeTime()` - 相对时间（今天、昨天、X天前）
- ✅ 替换 `add_existing_records_dialog.dart` 中的 `_formatDate()`
- ✅ 替换 `story_line_detail_page.dart` 中的 `_formatDate()`
- ✅ 替换 `record_detail_page.dart` 中的 `_formatDateTime()`
- ✅ 替换 `timeline_page.dart` 中的 `_formatTime()`
- ✅ 删除 4 个重复的日期格式化方法
- 📊 减少约 60 行重复代码

---

## 📈 进度统计

- **总任务数**: 7
- **已完成**: 2 (DRY-1, DRY-2)
- **进行中**: 0
- **待开始**: 5
- **完成率**: 28.6%
- **代码减少**: 96 行 / 596 行 (16.1%)

---

## 🎯 下一步行动

1. 按照 P0 → P1 → P2 的优先级顺序执行
2. 每完成一个任务，更新此文档的状态
3. 每个任务完成后进行充分测试
4. 所有任务完成后，进行全面回归测试

---

## 📚 相关文档

- [代码质量审查报告](./Code_Quality_Review.md)
- [Smart Navigator 使用指南](./smart_navigator_guide.md)
- [Records & Storyline 重构测试计划](./testing/records_storyline_refactoring_test_plan.md)

