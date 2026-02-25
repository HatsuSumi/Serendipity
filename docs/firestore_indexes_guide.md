# Firestore 索引配置指南

## 📋 概述

社区筛选功能需要创建 Firestore 复合索引。本文档提供了所有需要的索引配置。

## 🔧 创建方式

### 方式 1：通过错误链接创建（推荐）⭐

当你在 App 中触发筛选时，Firestore 会抛出错误并提供创建链接：

```
Exception: Failed to filter community posts: The query requires an index. 
You can create it here: https://console.firebase.google.com/...
```

**步骤**：
1. 点击错误信息中的链接
2. 在 Firebase Console 中点击"创建索引"
3. 等待索引构建完成（通常 1-5 分钟）

### 方式 2：手动创建索引

访问：https://console.firebase.google.com/project/serendipity-f3f75/firestore/indexes

## 📝 需要的索引列表

### 索引 1：城市 + 发布时间
```
集合 ID: community_posts
字段:
  - cityName (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 2：场所类型 + 发布时间
```
集合 ID: community_posts
字段:
  - placeType (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 3：状态 + 发布时间
```
集合 ID: community_posts
字段:
  - status (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 4：时间范围 + 发布时间
```
集合 ID: community_posts
字段:
  - timestamp (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 5：城市 + 场所类型 + 发布时间
```
集合 ID: community_posts
字段:
  - cityName (升序)
  - placeType (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 6：城市 + 状态 + 发布时间
```
集合 ID: community_posts
字段:
  - cityName (升序)
  - status (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 7：场所类型 + 状态 + 发布时间
```
集合 ID: community_posts
字段:
  - placeType (升序)
  - status (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 8：城市 + 时间范围 + 发布时间
```
集合 ID: community_posts
字段:
  - cityName (升序)
  - timestamp (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 9：场所类型 + 时间范围 + 发布时间
```
集合 ID: community_posts
字段:
  - placeType (升序)
  - timestamp (升序)
  - publishedAt (降序)
查询范围: 集合
```

### 索引 10：状态 + 时间范围 + 发布时间
```
集合 ID: community_posts
字段:
  - status (升序)
  - timestamp (升序)
  - publishedAt (降序)
查询范围: 集合
```

## 🎯 推荐策略

### 阶段 1：最小索引集（立即创建）

只创建最常用的 3 个索引：

1. **城市 + 发布时间**（最常用）
2. **场所类型 + 发布时间**
3. **状态 + 发布时间**

### 阶段 2：按需创建

当用户使用组合筛选时，根据错误提示创建对应的索引。

### 阶段 3：完整索引集

如果用户频繁使用组合筛选，创建所有 10 个索引。

## 📊 索引状态监控

在 Firebase Console 中可以看到：
- ✅ 已启用：索引可用
- 🔄 正在构建：等待 1-5 分钟
- ❌ 错误：需要重新创建

## 🚀 快速开始

**推荐流程**：

1. **先测试单个筛选条件**
   - 只选城市 → 创建索引 1
   - 只选场所类型 → 创建索引 2
   - 只选状态 → 创建索引 3

2. **再测试组合筛选**
   - 城市 + 场所类型 → 创建索引 5
   - 城市 + 状态 → 创建索引 6
   - 等等...

3. **按需创建**
   - 每次遇到索引错误，点击链接创建
   - 等待索引构建完成
   - 重新测试

## 💡 优化建议

### 如果索引太多

可以考虑：
1. 限制筛选条件的组合（如最多选 2 个条件）
2. 使用客户端筛选（性能略差但灵活）
3. 使用专业搜索服务（Algolia）

### 如果索引构建失败

1. 检查字段名是否正确
2. 检查字段类型是否匹配
3. 删除旧索引重新创建

## 📌 注意事项

1. **索引构建时间**：通常 1-5 分钟，数据量大时可能更长
2. **索引数量限制**：Firebase 免费版最多 200 个索引
3. **索引大小**：每个索引会占用存储空间
4. **查询性能**：有索引的查询速度 < 100ms，无索引会报错

## 🔗 相关链接

- Firebase Console: https://console.firebase.google.com/project/serendipity-f3f75/firestore/indexes
- Firestore 索引文档: https://firebase.google.com/docs/firestore/query-data/indexing
- 索引最佳实践: https://firebase.google.com/docs/firestore/query-data/index-overview

---

**最后更新**：2026-02-25

