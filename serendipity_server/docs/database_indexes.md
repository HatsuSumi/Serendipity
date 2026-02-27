# Serendipity 数据库索引优化说明

## 📊 索引概览

数据库共有 **9 个表**，**27 个索引**（不含主键和唯一约束）。

---

## 🔍 索引详情

### 1. users 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| users_email_idx | email | B-tree | 邮箱登录查询 |
| users_phone_number_idx | phone_number | B-tree | 手机号登录查询 |

**查询优化：**
- `SELECT * FROM users WHERE email = ?` - 使用 email 索引
- `SELECT * FROM users WHERE phone_number = ?` - 使用 phone_number 索引

---

### 2. records 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| records_user_id_idx | user_id | B-tree | 查询用户的所有记录 |
| records_updated_at_idx | updated_at | B-tree | 增量同步查询 |
| records_story_line_id_idx | story_line_id | B-tree | 查询故事线的记录 |
| records_timestamp_idx | timestamp | B-tree | 按时间排序查询 |

**查询优化：**
- `SELECT * FROM records WHERE user_id = ? AND updated_at > ?` - 使用复合索引
- `SELECT * FROM records WHERE story_line_id = ?` - 使用 story_line_id 索引

---

### 3. story_lines 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| story_lines_user_id_idx | user_id | B-tree | 查询用户的故事线 |
| story_lines_updated_at_idx | updated_at | B-tree | 增量同步查询 |

---

### 4. community_posts 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| community_posts_published_at_idx | published_at DESC | B-tree | 按发布时间倒序查询 |
| community_posts_user_id_idx | user_id | B-tree | 查询用户的帖子 |
| community_posts_city_name_idx | city_name | B-tree | 按城市筛选 |
| community_posts_place_type_idx | place_type | B-tree | 按场所类型筛选 |
| community_posts_status_idx | status | B-tree | 按状态筛选 |

**查询优化：**
- `SELECT * FROM community_posts WHERE city_name = ? AND place_type = ?` - 可能需要复合索引
- `SELECT * FROM community_posts ORDER BY published_at DESC LIMIT 20` - 使用 published_at 索引

---

### 5. memberships 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| memberships_user_id_idx | user_id | B-tree | 查询用户会员状态 |
| memberships_expires_at_idx | expires_at | B-tree | 查询即将过期的会员 |

---

### 6. payment_orders 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| payment_orders_user_id_idx | user_id | B-tree | 查询用户的订单 |
| payment_orders_status_idx | status | B-tree | 按状态查询订单 |
| payment_orders_transaction_id_idx | transaction_id | B-tree | 支付回调查询 |

---

### 7. refresh_tokens 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| refresh_tokens_user_id_idx | user_id | B-tree | 查询用户的 token |
| refresh_tokens_token_idx | token | B-tree | Token 验证查询 |
| refresh_tokens_expires_at_idx | expires_at | B-tree | 清理过期 token |

---

### 8. verification_codes 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| verification_codes_target_idx | target | B-tree | 查询邮箱/手机号的验证码 |
| verification_codes_expires_at_idx | expires_at | B-tree | 清理过期验证码 |

---

### 9. user_settings 表

| 索引名 | 字段 | 类型 | 用途 |
|--------|------|------|------|
| user_settings_user_id_idx | user_id | B-tree | 查询用户设置 |

---

## 🚀 性能优化建议

### 1. 复合索引优化

**records 表：**
```sql
-- 增量同步查询优化
CREATE INDEX idx_records_user_updated ON records(user_id, updated_at);
```

**community_posts 表：**
```sql
-- 城市 + 场所类型筛选优化
CREATE INDEX idx_community_city_place ON community_posts(city_name, place_type);

-- 城市 + 状态筛选优化
CREATE INDEX idx_community_city_status ON community_posts(city_name, status);
```

### 2. 定期维护

```sql
-- 清理过期的 refresh_tokens
DELETE FROM refresh_tokens WHERE expires_at < NOW();

-- 清理过期的 verification_codes
DELETE FROM verification_codes WHERE expires_at < NOW();

-- 分析表统计信息
ANALYZE users;
ANALYZE records;
ANALYZE community_posts;
```

### 3. 查询优化

**避免全表扫描：**
```sql
-- ❌ 不好：没有索引
SELECT * FROM records WHERE description LIKE '%关键词%';

-- ✅ 好：使用索引
SELECT * FROM records WHERE user_id = ? AND updated_at > ?;
```

**使用 EXPLAIN 分析查询：**
```sql
EXPLAIN ANALYZE SELECT * FROM records WHERE user_id = ? AND updated_at > ?;
```

---

## 📈 监控指标

### 索引使用率

```sql
-- 查看索引使用情况
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

### 表大小

```sql
-- 查看表大小
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

**创建时间**：2026-02-26  
**维护者**：AI Assistant + 开发者

