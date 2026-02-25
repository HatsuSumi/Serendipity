# Supabase 迁移指南

## 📋 概述

本文档说明如何从 Firebase 迁移到 Supabase，解决 Firestore 复合索引的问题。

## 🎯 为什么迁移到 Supabase？

### Firestore 的问题

- ❌ 复合索引必须预创建
- ❌ 多条件筛选需要大量索引（5 个条件 = 24+ 个索引）
- ❌ 索引管理复杂
- ❌ 查询灵活性差

### Supabase 的优势

- ✅ 基于 PostgreSQL，查询灵活
- ✅ 不需要预创建复合索引
- ✅ 支持任意组合的筛选条件
- ✅ 支持复杂查询（JOIN、子查询、全文搜索）
- ✅ 免费额度更大
- ✅ 有完整的 Flutter SDK

## 📦 迁移步骤

### 第一步：创建 Supabase 项目（5 分钟）

1. 访问 https://supabase.com
2. 注册并创建新项目
3. 记录以下信息：
   - Project URL: `https://xxxxx.supabase.co`
   - Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 第二步：创建数据库表（10 分钟）

在 Supabase Dashboard → SQL Editor 中执行以下 SQL：

```sql
-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 用户记录表
CREATE TABLE encounter_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  person_name TEXT NOT NULL,
  encounter_time TIMESTAMPTZ NOT NULL,
  location TEXT,
  description TEXT,
  tags TEXT[],
  status INTEGER DEFAULT 1,
  timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引（可选，用于优化查询）
CREATE INDEX idx_encounter_records_user_id ON encounter_records(user_id);
CREATE INDEX idx_encounter_records_timestamp ON encounter_records(timestamp DESC);

-- 2. 故事线表
CREATE TABLE story_lines (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  record_ids UUID[],
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引（可选）
CREATE INDEX idx_story_lines_user_id ON story_lines(user_id);

-- 3. 社区帖子表
CREATE TABLE community_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL,
  author_name TEXT NOT NULL,
  author_avatar TEXT,
  description TEXT NOT NULL,
  images TEXT[],
  city_name TEXT,
  place_type TEXT,
  tags TEXT[],
  status INTEGER DEFAULT 1,
  timestamp TIMESTAMPTZ NOT NULL,
  published_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引（可选，用于优化排序）
CREATE INDEX idx_community_posts_published_at ON community_posts(published_at DESC);

-- 注意：不需要创建复合索引！PostgreSQL 会自动优化查询
```

### 第三步：添加依赖（1 分钟）

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  supabase_flutter: ^2.5.0
```

运行：
```bash
flutter pub get
```

### 第四步：配置 Supabase（5 分钟）

#### 4.1 创建配置文件

创建 `lib/core/config/supabase_config.dart`：

```dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

#### 4.2 初始化 Supabase

在 `lib/main.dart` 中初始化：

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  // ... 其他初始化代码
  
  runApp(const MyApp());
}
```

### 第五步：切换 Repository（2 行代码）⭐

#### 5.1 修改认证 Provider

在 `lib/core/providers/auth_provider.dart` 中：

```dart
import '../repositories/supabase_auth_repository.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return SupabaseAuthRepository(); // 只改这一行！
});
```

#### 5.2 修改数据 Provider

在 `lib/core/services/sync_service.dart` 中：

```dart
import '../repositories/supabase_remote_data_repository.dart';

final remoteDataRepositoryProvider = Provider<IRemoteDataRepository>((ref) {
  return SupabaseRemoteDataRepository(); // 只改这一行！
});
```

### 第六步：数据迁移（可选）

如果你已有 Firestore 数据，需要迁移：

#### 6.1 导出 Firestore 数据

```bash
# 使用 Firebase CLI 导出数据
firebase firestore:export gs://your-bucket/firestore-export
```

#### 6.2 编写迁移脚本

创建 `scripts/migrate_to_supabase.dart`：

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> migrateData() async {
  // 初始化 Firebase
  final firestore = FirebaseFirestore.instance;
  
  // 初始化 Supabase
  await Supabase.initialize(
    url: 'YOUR_URL',
    anonKey: 'YOUR_KEY',
  );
  final supabase = Supabase.instance.client;
  
  // 迁移社区帖子
  final posts = await firestore.collection('community_posts').get();
  
  for (final doc in posts.docs) {
    final data = doc.data();
    await supabase.from('community_posts').insert({
      'id': doc.id,
      'user_id': data['userId'],
      'author_name': data['authorName'],
      'description': data['description'],
      'images': data['images'],
      'city_name': data['cityName'],
      'place_type': data['placeType'],
      'tags': data['tags'],
      'status': data['status'],
      'timestamp': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
      'published_at': (data['publishedAt'] as Timestamp).toDate().toIso8601String(),
    });
  }
  
  print('迁移完成！');
}
```

### 第七步：测试验证（1-2 小时）

#### 7.1 测试认证功能

- [ ] 邮箱注册
- [ ] 邮箱登录
- [ ] 手机号登录
- [ ] 登出
- [ ] 密码重置

#### 7.2 测试数据同步

- [ ] 创建记录
- [ ] 更新记录
- [ ] 删除记录
- [ ] 数据同步

#### 7.3 测试社区功能

- [ ] 发布帖子
- [ ] 获取帖子列表
- [ ] 筛选帖子（重点测试多条件组合）
- [ ] 删除帖子

## 🎉 筛选功能对比

### Firestore（迁移前）

```dart
// ❌ 需要预创建索引
await firestore
  .collection('community_posts')
  .where('cityName', isEqualTo: '广州市')
  .where('placeType', isEqualTo: 'cafe')
  .where('status', isEqualTo: 1)
  .orderBy('publishedAt', descending: true)
  .limit(20)
  .get();

// 错误：需要创建复合索引
// 5 个筛选条件 = 24+ 个索引组合
```

### Supabase（迁移后）

```dart
// ✅ 不需要任何索引！
await supabase
  .from('community_posts')
  .select()
  .eq('city_name', '广州市')
  .eq('place_type', 'cafe')
  .eq('status', 1)
  .order('published_at', descending: true)
  .limit(20);

// 随便组合，想加多少条件都行！
```

## 📊 性能对比

| 指标 | Firestore | Supabase |
|------|-----------|----------|
| 简单查询 | 快（~50ms） | 快（~80ms） |
| 复杂筛选 | 需要索引 | 不需要索引 |
| 索引管理 | 复杂 | 简单 |
| 查询灵活性 | 低 | 高 |
| 免费额度 | 50K 读/天 | 500MB 数据库 |
| 全文搜索 | 不支持 | 支持 |
| JOIN 查询 | 不支持 | 支持 |

## 💰 成本对比

### Firestore

- 读取：$0.06 / 100K 次
- 写入：$0.18 / 100K 次
- 存储：$0.18 / GB
- **索引存储额外收费**

### Supabase

- 免费版：500MB 数据库 + 2GB 带宽
- Pro 版：$25/月，8GB 数据库 + 50GB 带宽
- **不需要为索引额外付费**

## 🚀 迁移后的优势

### 1. 查询灵活性

```dart
// 任意组合筛选条件
await supabase
  .from('community_posts')
  .select()
  .eq('city_name', cityName)           // 可选
  .eq('place_type', placeType)         // 可选
  .eq('status', status)                // 可选
  .gte('timestamp', startDate)         // 可选
  .lte('timestamp', endDate)           // 可选
  .contains('tags', [tag])             // 可选
  .order('published_at', descending: true)
  .limit(20);

// 不需要任何预创建的索引！
```

### 2. 全文搜索

```dart
// Supabase 支持全文搜索
await supabase
  .from('community_posts')
  .select()
  .textSearch('description', '咖啡', config: 'chinese');
```

### 3. 复杂查询

```sql
-- 可以直接写 SQL
SELECT 
  p.*,
  COUNT(l.id) as like_count
FROM community_posts p
LEFT JOIN post_likes l ON p.id = l.post_id
WHERE p.city_name = '广州市'
GROUP BY p.id
ORDER BY like_count DESC
LIMIT 20;
```

### 4. 实时订阅

```dart
// Supabase 也支持实时订阅（类似 Firestore）
supabase
  .from('community_posts')
  .stream(primaryKey: ['id'])
  .listen((data) {
    print('数据更新：$data');
  });
```

## ⚠️ 注意事项

### 1. 认证差异

- Firestore 使用 Firebase Auth
- Supabase 使用 Supabase Auth
- 用户需要重新注册（或迁移用户数据）

### 2. 数据模型差异

- Firestore：文档数据库（NoSQL）
- Supabase：关系数据库（PostgreSQL）
- 需要调整数据结构（如数组字段）

### 3. 离线支持

- Firestore：原生支持离线
- Supabase：需要自己实现离线缓存

### 4. 安全规则

- Firestore：使用 Security Rules
- Supabase：使用 Row Level Security (RLS)

需要在 Supabase 中配置 RLS：

```sql
-- 启用 RLS
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- 允许所有人读取
CREATE POLICY "允许所有人读取帖子"
ON community_posts FOR SELECT
USING (true);

-- 只允许作者删除
CREATE POLICY "只允许作者删除帖子"
ON community_posts FOR DELETE
USING (auth.uid() = user_id);
```

## 📝 总结

### 迁移工作量

- ✅ 修改 Provider：2 行代码
- ✅ 实现 Repository：已完成（700 行代码）
- ✅ 创建数据库表：10 分钟
- ✅ 配置初始化：5 分钟
- ⚠️ 数据迁移：视数据量而定
- ⚠️ 测试验证：1-2 小时

### 是否值得迁移？

**强烈推荐迁移！**

- ✅ 彻底解决索引问题
- ✅ 查询灵活性大幅提升
- ✅ 支持更复杂的功能
- ✅ 成本更低
- ✅ 架构已经支持，切换成本低

### 下一步

1. 创建 Supabase 项目
2. 创建数据库表
3. 修改 2 行代码切换 Repository
4. 测试验证
5. 数据迁移（如果有现有数据）
6. 上线

**预计总耗时：半天到一天**

## 📦 文件存储方案

### 方案对比

迁移到 Supabase 后，文件存储有多种选择：

| 方案 | 存储成本 | 流量成本 | 总成本/月 | 需要服务器 | 推荐度 |
|------|---------|---------|-----------|-----------|--------|
| **Supabase Storage** | $25（含数据库） | 包含 50GB | ¥175 | ❌ | ⭐⭐⭐⭐⭐ |
| **阿里云 OSS** | ¥2.4（20GB） | ¥10（20GB） | ¥12 | ❌ | ⭐⭐⭐⭐ |
| **Cloudflare R2** | ¥2（20GB） | 免费 | ¥2 | ❌ | ⭐⭐⭐⭐⭐ |
| **自建服务器** | 包含在服务器 | 包含在服务器 | ¥150+ | ✅ | ⭐⭐ |

### 推荐：Supabase Storage（一站式）

**优点**：
- ✅ 与数据库无缝集成
- ✅ 自动 CDN 加速
- ✅ 自动图片转换（缩略图）
- ✅ 权限控制集成
- ✅ 零配置

**使用示例**：

```dart
// 上传图片
final file = File('path/to/image.jpg');
await supabase.storage
    .from('community-images')
    .upload('public/$fileName', file);

// 获取 URL
final imageUrl = supabase.storage
    .from('community-images')
    .getPublicUrl('public/$fileName');

// 获取缩略图（自动生成）
final thumbnailUrl = supabase.storage
    .from('community-images')
    .getPublicUrl(
      'public/$fileName',
      transform: TransformOptions(
        width: 300,
        height: 300,
      ),
    );
```

**配置存储桶**：

在 Supabase Dashboard → Storage 中：

1. 创建 bucket：`community-images`
2. 设置为 Public（公开访问）
3. 配置存储策略：

```sql
-- 允许认证用户上传
CREATE POLICY "认证用户可以上传图片"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'community-images' 
  AND auth.role() = 'authenticated'
);

-- 允许所有人读取
CREATE POLICY "所有人可以读取图片"
ON storage.objects FOR SELECT
USING (bucket_id = 'community-images');

-- 只允许作者删除
CREATE POLICY "只允许作者删除图片"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'community-images' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### 替代方案：Cloudflare R2（最省钱）

如果想节省成本，可以使用 Cloudflare R2：

**优点**：
- ✅ 流量完全免费
- ✅ 存储超便宜（¥0.1/GB）
- ✅ 全球 CDN

**配置**：

```dart
// 使用 S3 兼容 API
import 'package:minio/minio.dart';

final minio = Minio(
  endPoint: 'your-account.r2.cloudflarestorage.com',
  accessKey: 'your-access-key',
  secretKey: 'your-secret-key',
);

// 上传
await minio.fPutObject('bucket', 'images/$fileName', file.path);

// 获取 URL
final imageUrl = 'https://your-domain.com/images/$fileName';
```

**成本对比**：

```
Supabase 全家桶：¥175/月
- 数据库 8GB
- 存储 100GB
- 带宽 50GB

Supabase 免费版 + Cloudflare R2：¥2/月
- 数据库 500MB（Supabase 免费）
- 存储 20GB（R2）
- 带宽无限（R2 免费）
```

## 🔗 相关资源

- Supabase 官网：https://supabase.com
- Supabase Flutter SDK：https://pub.dev/packages/supabase_flutter
- PostgreSQL 文档：https://www.postgresql.org/docs/
- Supabase Storage 文档：https://supabase.com/docs/guides/storage
- Cloudflare R2：https://www.cloudflare.com/products/r2/

