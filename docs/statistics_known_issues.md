# 统计模块已确认问题清单

> 仅记录已通过源码核实的问题。
> 最后更新：2026-03-23

---

## ✅ 已修复

### 1. 地点统计口径不统一

`topPlaces` 走 GPS 聚类 + 多级名称优先级逻辑，与基础统计的 `mostCommonPlace`（只统计 `placeName` 字符串）口径不同。

**修复**：删除 `topPlaces` 相关代码，统一口径为 `placeName` 字符串统计。

---

### 2. GPS 聚类精度过粗

`_calculateTopPlaces()` 中经纬度保留 1 位小数聚类，实际粒度约 10 公里级别。

**修复**：随问题 1 一并删除，不再存在。

---

### 3. `topPlaces` 已计算但页面未展示

`AdvancedStatistics.topPlaces` 有计算，但 `statistics_page.dart` 中没有任何卡片渲染该字段。

**修复**：随问题 1 一并删除，不再存在。

---

### 4. 统计页 UI 层类型系统过松（大量 `dynamic`）

统计页原先在基础统计卡片、高级统计卡片、月度记录表、情绪强度分布、天气分布、场所类型分布、成功率趋势等位置大量使用 `dynamic`。

**修复**：已全部替换为明确类型，包括 `BasicStatistics`、`AdvancedStatistics`、`TagCloudItem`、`MonthlyRecord`、`EmotionIntensityItem`、`WeatherDistributionItem`、`PlaceTypeDistributionItem`、`MonthlySuccessRate` 以及对应的强类型 `Map` / `List`。

---

### 5. `calculateBasicStatistics()` 注释与实现不一致

注释写「地点聚类：GPS < 100米范围内算同一地点」，但实现只按 `placeName` 字符串统计，从未有 GPS 聚类逻辑。

**修复**：删除误导性注释。
