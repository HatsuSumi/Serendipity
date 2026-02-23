# 成就系统 & 签到功能修复计划

**修复日期**：2026-02-23  
**修复范围**：9个问题（2个高优先级 + 3个中优先级 + 4个低优先级）

---

## 📋 修复清单

### 🔥 高优先级（必须修复）

- [ ] **问题1**：重构 `AchievementDetector` 类
  - [ ] 创建 `GeoHelper` 工具类
  - [ ] 创建 `AddressHelper` 工具类
  - [ ] 创建 `HolidayHelper` 工具类
  - [ ] 创建 `RecordAchievementChecker` 检测器
  - [ ] 创建 `CheckInAchievementChecker` 检测器
  - [ ] 创建 `StoryLineAchievementChecker` 检测器
  - [ ] 重构 `AchievementDetector` 为协调器
  - [ ] 更新 Provider 依赖
  - [ ] 测试所有成就检测逻辑

- [ ] **问题2**：添加缺失的"签到大师"成就
  - [ ] 在 `achievement_definitions.dart` 中添加成就定义
  - [ ] 在 `AchievementDetector` 中添加检测逻辑
  - [ ] 更新文档中的成就总数

### ⚡ 中优先级（建议修复）

- [ ] **问题3**：优化签到逻辑，防止重复签到
  - [ ] 在 `CheckInCard` 中添加防抖逻辑
  - [ ] 在 `CheckInPage` 中添加防抖逻辑

- [ ] **问题4**：改进成就进度更新逻辑
  - [ ] 修改 `AchievementRepository.updateProgress()` 方法

- [ ] **问题5**：优化连续签到计算性能
  - [ ] 修改 `CheckInRepository.calculateConsecutiveDays()` 方法

### 💡 低优先级（可选优化）

- [ ] **问题6**：放宽成就构造函数断言
  - [ ] 修改 `Achievement` 构造函数

- [ ] **问题7**：使用枚举表示徽章等级
  - [ ] 创建 `CheckInBadgeLevel` 枚举
  - [ ] 修改 `CheckInBadgeHelper`

- [ ] **问题8**：检查 Flutter 版本兼容性
  - [ ] 检查 `pubspec.yaml` 中的 Flutter 版本
  - [ ] 决定是否需要替换 `withValues()` 为 `withOpacity()`

- [ ] **问题9**：改进节日判断逻辑
  - [ ] 移除不准确的农历节日判断
  - [ ] 只保留固定日期节日

---

## 🏗️ 重构架构设计

### 当前架构（问题）
```
AchievementDetector (600+ 行)
├── checkRecordAchievements()
├── checkCheckInAchievements()
├── checkStoryLineAchievements()
├── _countRecordsAtSameLocation()
├── _calculateDistance()
├── _countUniqueCities()
├── _extractCityFromAddress()
├── _isHoliday()
├── _calculateSuccessRate()
└── _toRadians()
```

### 重构后架构（优雅）
```
工具层（Utils）
├── GeoHelper
│   ├── calculateDistance()
│   ├── countRecordsAtSameLocation()
│   └── toRadians()
├── AddressHelper
│   ├── extractCity()
│   └── countUniqueCities()
└── HolidayHelper
    └── isHoliday()

检测器层（Checkers）
├── RecordAchievementChecker
│   ├── check()
│   ├── _checkRecordCountAchievements()
│   ├── _checkStatusAchievements()
│   ├── _checkTimeAchievements()
│   ├── _checkWeatherAchievements()
│   ├── _checkLocationAchievements()
│   └── _calculateSuccessRate()
├── CheckInAchievementChecker
│   └── check()
└── StoryLineAchievementChecker
    └── check()

协调器层（Coordinator）
└── AchievementDetector
    ├── checkRecordAchievements()
    ├── checkCheckInAchievements()
    └── checkStoryLineAchievements()
```

---

## 📝 修复顺序

1. **先修复低优先级问题**（简单，不影响架构）
2. **再修复中优先级问题**（局部优化）
3. **最后修复高优先级问题**（大重构）

这样可以确保：
- ✅ 每一步都可以独立测试
- ✅ 如果出现问题，容易回滚
- ✅ 逐步提高代码质量

---

**开始时间**：2026-02-23  
**预计完成时间**：2小时

