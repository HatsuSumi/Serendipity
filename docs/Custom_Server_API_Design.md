# Serendipity 自建服务器 API 接口设计

**项目名称**：Serendipity（错过了么）  
**API 版本**：v1.0  
**创建时间**：2026-02-25  
**最后更新**：2026-02-25（修正版）  
**Base URL**：`https://api.serendipity.com`

---

## 📋 API 概览

### 接口分类

| 分类 | 接口数量 | 说明 |
|------|---------|------|
| 认证相关 | 12 个 | 注册、登录、Token 管理、密码/邮箱/手机号修改 |
| 数据同步 | 10 个 | 记录、故事线同步 |
| 社区相关 | 5 个 | 社区帖子发布、浏览、筛选 |
| ~~支付相关~~ | ~~5 个~~ | ~~支付订单、回调、会员状态~~ ❌ 已删除 |
| 用户相关 | 3 个 | 用户信息、设置 |
| **总计** | **30 个** | - |

---

## 🔐 认证机制

### JWT Token 认证

**Token 结构：**
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "iat": 1234567890,
  "exp": 1234567890
}
```

**Token 使用：**
```http
Authorization: Bearer <access_token>
```

**Token 刷新机制：**
- Access Token 有效期：7 天
- Refresh Token 有效期：30 天
- Access Token 过期后使用 Refresh Token 刷新

---

## 📡 通用响应格式

### 成功响应

```json
{
  "success": true,
  "data": {
    // 响应数据
  },
  "message": "操作成功"
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {}
  }
}
```

### 错误码列表

| 错误码 | HTTP 状态码 | 说明 |
|--------|------------|------|
| `INVALID_REQUEST` | 400 | 请求参数错误 |
| `UNAUTHORIZED` | 401 | 未授权（Token 无效或过期） |
| `FORBIDDEN` | 403 | 无权限访问 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `CONFLICT` | 409 | 资源冲突（如邮箱已存在） |
| `INTERNAL_ERROR` | 500 | 服务器内部错误 |
| `SERVICE_UNAVAILABLE` | 503 | 服务暂时不可用 |

---

## 🔑 认证相关 API

### 1. 邮箱注册

**接口**：`POST /api/v1/auth/register/email`

**说明**：使用邮箱和密码注册新账号，需要先调用发送验证码接口获取验证码

**请求参数**：
```json
{
  "email": "user@example.com",
  "password": "password123",
  "verificationCode": "123456"
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "createdAt": "2026-02-25T10:00:00Z"
    },
    "tokens": {
      "accessToken": "jwt_token",
      "refreshToken": "refresh_token",
      "expiresIn": 604800
    }
  }
}
```

**错误码**：
- `EMAIL_ALREADY_EXISTS`：邮箱已存在
- `INVALID_VERIFICATION_CODE`：验证码错误
- `WEAK_PASSWORD`：密码强度不足

---

### 2. 手机号注册

**接口**：`POST /api/v1/auth/register/phone`

**请求参数**：
```json
{
  "phoneNumber": "+8613800138000",
  "password": "password123",
  "verificationCode": "123456"
}
```

**响应**：同邮箱注册

**错误码**：
- `PHONE_ALREADY_EXISTS`：手机号已存在
- `INVALID_VERIFICATION_CODE`：验证码错误

---

### 3. 邮箱登录

**接口**：`POST /api/v1/auth/login/email`

**请求参数**：
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**：同注册接口

**错误码**：
- `INVALID_CREDENTIALS`：邮箱或密码错误
- `ACCOUNT_DISABLED`：账号已被禁用

---

### 4. 手机号登录

**接口**：`POST /api/v1/auth/login/phone`

**请求参数**：
```json
{
  "phoneNumber": "+8613800138000",
  "password": "password123"
}
```

**响应**：同注册接口

---

### 5. 发送验证码

**接口**：`POST /api/v1/auth/send-verification-code`

**请求参数**：
```json
{
  "type": "email",  // email | phone
  "target": "user@example.com",  // 邮箱地址（type=email时）、手机号（type=phone时）
  "purpose": "register"  // register | login | reset_password
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "expiresIn": 300,  // 5分钟
    "message": "验证码已发送"
  }
}
```

**错误码**：
- `RATE_LIMIT_EXCEEDED`：发送频率过高
- `INVALID_TARGET`：邮箱或手机号格式错误

---

### 6. 重置密码

**接口**：`POST /api/v1/auth/reset-password`

**请求参数**：
```json
{
  "email": "user@example.com",
  "verificationCode": "123456",
  "newPassword": "new_password123"
}
```

**响应**：
```json
{
  "success": true,
  "message": "密码重置成功"
}
```

---

### 7. 刷新 Token

**接口**：`POST /api/v1/auth/refresh-token`

**请求参数**：
```json
{
  "refreshToken": "refresh_token"
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "accessToken": "new_jwt_token",
    "refreshToken": "new_refresh_token",
    "expiresIn": 604800
  }
}
```

**错误码**：
- `INVALID_REFRESH_TOKEN`：Refresh Token 无效或过期

---

### 8. 获取当前用户

**接口**：`GET /api/v1/auth/me`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "phoneNumber": "+8613800138000",
    "displayName": "用户昵称",
    "createdAt": "2026-02-25T10:00:00Z",
    "membership": {
      "tier": "premium",
      "status": "active",
      "expiresAt": "2026-03-25T10:00:00Z"
    }
  }
}
```

---

### 9. 登出

**接口**：`POST /api/v1/auth/logout`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**响应**：
```json
{
  "success": true,
  "message": "登出成功"
}
```

---

### 10. 修改密码

**接口**：`PUT /api/v1/auth/password`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "currentPassword": "old_password123",
  "newPassword": "new_password123"
}
```

**响应**：
```json
{
  "success": true,
  "message": "密码修改成功"
}
```

**错误码**：
- `INVALID_CURRENT_PASSWORD`：当前密码错误
- `WEAK_PASSWORD`：新密码强度不足
- `UNAUTHORIZED`：用户未登录

---

### 11. 更换邮箱

**接口**：`PUT /api/v1/auth/email`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "newEmail": "new@example.com",
  "password": "current_password123",
  "verificationCode": "123456"
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "email": "new@example.com",
    "updatedAt": "2026-02-25T10:00:00Z"
  }
}
```

**错误码**：
- `INVALID_PASSWORD`：密码错误
- `EMAIL_ALREADY_EXISTS`：新邮箱已被使用
- `INVALID_VERIFICATION_CODE`：验证码错误

---

### 12. 更换/绑定手机号

**接口**：`PUT /api/v1/auth/phone`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "newPhoneNumber": "+8613800138001",
  "verificationCode": "123456"
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "phoneNumber": "+8613800138001",
    "updatedAt": "2026-02-25T10:00:00Z"
  }
}
```

**错误码**：
- `PHONE_ALREADY_EXISTS`：新手机号已被使用
- `INVALID_VERIFICATION_CODE`：验证码错误

---

## 📦 数据同步 API

### 13. 上传单条记录

**接口**：`POST /api/v1/records`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "id": "uuid",
  "timestamp": "2026-02-25T10:00:00Z",
  "location": {
    "latitude": 39.9087,
    "longitude": 116.3975,
    "address": "北京市朝阳区建国门外大街1号",
    "placeName": "常去的咖啡馆",
    "placeType": "coffee_shop"
  },
  "description": "她在读《百年孤独》...",
  "tags": [
    {
      "tag": "长发",
      "note": "光线不好，可能是深棕色"
    }
  ],
  "emotion": "thought_all_night",
  "status": "missed",
  "storyLineId": "uuid",
  "ifReencounter": "如果再遇到，我想说...",
  "conversationStarter": "她掉了一本书，我帮她捡起来",
  "backgroundMusic": "《遇见》",
  "weather": ["sunny", "breeze"],
  "createdAt": "2026-02-25T10:00:00Z",
  "updatedAt": "2026-02-25T10:00:00Z",
  "isPinned": false
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "syncedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 14. 批量上传记录

**接口**：`POST /api/v1/records/batch`

**请求参数**：
```json
{
  "records": [
    // 记录数组，格式同上传单条记录
  ]
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "total": 10,
    "succeeded": 10,
    "failed": 0,
    "syncedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 15. 下载记录

**接口**：`GET /api/v1/records`

**说明**：支持增量同步，只返回 `updatedAt > lastSyncTime` 的记录

**请求参数**：
```
?lastSyncTime=2026-02-25T10:00:00Z  // 增量同步时间戳（ISO 8601 格式），不传则返回所有记录
&limit=100  // 每页数量，默认 100
&offset=0   // 偏移量，默认 0
```

**响应**：
```json
{
  "success": true,
  "data": {
    "records": [
      // 记录数组，格式同上传单条记录
    ],
    "total": 100,
    "hasMore": true,
    "syncTime": "2026-02-25T10:00:00Z"
  }
}
```

**增量同步逻辑**：
- 提供 `lastSyncTime` 时：只返回 `updatedAt > lastSyncTime` 的记录
- 不提供 `lastSyncTime` 时：返回所有记录
- 客户端保存响应中的 `syncTime`，下次同步时作为 `lastSyncTime` 传入

---

### 16. 更新记录

**接口**：`PUT /api/v1/records/:id`

**请求参数**：同上传单条记录

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "updatedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 17. 删除记录

**接口**：`DELETE /api/v1/records/:id`

**响应**：
```json
{
  "success": true,
  "message": "记录已删除"
}
```

---

### 18. 上传单条故事线

**接口**：`POST /api/v1/storylines`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "id": "uuid",
  "name": "地铁上的她",
  "recordIds": ["uuid1", "uuid2", "uuid3"],
  "createdAt": "2026-02-25T10:00:00Z",
  "updatedAt": "2026-02-25T10:00:00Z"
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "syncedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 19. 批量上传故事线

**接口**：`POST /api/v1/storylines/batch`

**请求参数**：
```json
{
  "storylines": [
    // 故事线数组，格式同上传单条故事线
  ]
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "total": 5,
    "succeeded": 5,
    "failed": 0,
    "syncedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 20. 下载故事线

**接口**：`GET /api/v1/storylines`

**说明**：支持增量同步，只返回 `updatedAt > lastSyncTime` 的故事线

**请求参数**：
```
?lastSyncTime=2026-02-25T10:00:00Z  // 增量同步时间戳，不传则返回所有故事线
&limit=100  // 每页数量，默认 100
&offset=0   // 偏移量，默认 0
```

**响应**：
```json
{
  "success": true,
  "data": {
    "storylines": [
      // 故事线数组
    ],
    "total": 5,
    "hasMore": false,
    "syncTime": "2026-02-25T10:00:00Z"
  }
}
```

---

### 21. 更新故事线

**接口**：`PUT /api/v1/storylines/:id`

**请求参数**：同上传单条故事线

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "updatedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 22. 删除故事线

**接口**：`DELETE /api/v1/storylines/:id`

**响应**：
```json
{
  "success": true,
  "message": "故事线已删除"
}
```

---

## 🌍 社区相关 API

### 23. 发布社区帖子

**接口**：`POST /api/v1/community/posts`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "id": "uuid",
  "recordId": "uuid",
  "timestamp": "2026-02-25T10:00:00Z",
  "address": "北京市朝阳区建国门外大街1号",
  "placeName": "常去的咖啡馆",
  "placeType": "coffee_shop",
  "province": "北京市",
  "city": "北京市",
  "area": "朝阳区",
  "description": "她在读《百年孤独》...",
  "tags": [
    {
      "tag": "长发",
      "note": "光线不好，可能是深棕色"
    }
  ],
  "status": "missed",
  "publishedAt": "2026-02-25T10:00:00Z"
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "publishedAt": "2026-02-25T10:00:00Z"
  }
}
```

**说明**：
- 完全匿名，不包含用户信息
- 不包含精确 GPS 坐标（只有 address）
- 不包含 placeName（私人标记）

---

### 24. 获取社区帖子列表

**接口**：`GET /api/v1/community/posts`

**请求参数**：
```
?limit=20  // 每页数量，默认 20
&lastTimestamp=2026-02-25T10:00:00Z  // 分页游标（上一页最后一条的时间戳）
```

**响应**：
```json
{
  "success": true,
  "data": {
    "posts": [
      // 帖子数组，格式同发布接口
    ],
    "hasMore": true
  }
}
```

---

### 25. 获取我的社区帖子

**接口**：`GET /api/v1/community/my-posts`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**响应**：
```json
{
  "success": true,
  "data": {
    "posts": [
      // 我发布的帖子数组
    ],
    "total": 10
  }
}
```

---

### 26. 删除社区帖子

**接口**：`DELETE /api/v1/community/posts/:id`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**响应**：
```json
{
  "success": true,
  "message": "帖子已删除"
}
```

**错误码**：
- `NOT_FOUND`：帖子不存在
- `FORBIDDEN`：不是帖子作者，无权删除

---

### 27. 筛选社区帖子

**接口**：`GET /api/v1/community/posts/filter`

**请求参数**：
```
?startDate=2026-02-01  // 开始日期（不传则不限制）
&endDate=2026-02-28    // 结束日期（不传则不限制）
&province=北京市       // 省份（不传则不限制）
&city=北京市           // 城市（不传则不限制）
&area=朝阳区           // 区县（不传则不限制）
&placeType=coffee_shop // 场所类型（不传则不限制）
&tag=长发              // 标签名称（不传则不限制）
&status=1              // 状态（1=错过，2=回避，不传则不限制）
&limit=20              // 每页数量，默认 20
```

**响应**：
```json
{
  "success": true,
  "data": {
    "posts": [
      // 符合条件的帖子数组
    ],
    "total": 50,
    "hasMore": true
  }
}
```

---

## 👤 用户相关 API

### 28. 更新用户信息

**接口**：`PUT /api/v1/users/me`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "displayName": "新昵称",
  "avatarUrl": "https://..."
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "displayName": "新昵称",
    "updatedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

### 29. 获取用户设置

**接口**：`GET /api/v1/users/settings`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**响应**：
```json
{
  "success": true,
  "data": {
    "theme": "light",
    "pageTransition": "slide_from_right",
    "dialogAnimation": "fade_in",
    "notifications": {
      "checkInReminder": true,
      "checkInReminderTime": "20:00",
      "achievementUnlocked": true
    },
    "checkIn": {
      "vibrationEnabled": true,
      "confettiEnabled": true
    }
  }
}
```

---

### 30. 更新用户设置

**接口**：`PUT /api/v1/users/settings`

**请求头**：
```http
Authorization: Bearer <access_token>
```

**请求参数**：
```json
{
  "theme": "dark",
  "pageTransition": "fade",
  "dialogAnimation": "scale",
  "notifications": {
    "checkInReminder": false,
    "checkInReminderTime": "21:00",
    "achievementUnlocked": true
  },
  "checkIn": {
    "vibrationEnabled": false,
    "confettiEnabled": true
  }
}
```

**响应**：
```json
{
  "success": true,
  "data": {
    "updatedAt": "2026-02-25T10:00:00Z"
  }
}
```

---

## 🔒 安全机制

### 1. 请求签名

敏感操作（支付、修改密码等）要求客户端对请求进行签名：

```
Signature = HMAC-SHA256(timestamp + method + path + body, secret)
```

### 2. 频率限制

| 接口类型 | 限制 |
|---------|------|
| 登录/注册 | 5 次/分钟 |
| 发送验证码 | 1 次/分钟 |
| 数据同步 | 100 次/分钟 |
| ~~支付相关~~ | ~~10 次/分钟~~ ❌ 已删除 |

### 3. ~~IP 白名单~~ ❌ 已删除

~~支付回调接口只允许微信/支付宝的 IP 访问。~~

---

## 📊 性能指标

### 响应时间要求

| 接口类型 | P95 响应时间 |
|---------|-------------|
| 认证相关 | < 200ms |
| 数据同步 | < 500ms |
| ~~支付相关~~ | ~~< 1000ms~~ ❌ 已删除 |

### 并发能力

- 单机 QPS：1000+
- 集群 QPS：10000+

---

## 🧪 测试环境

### 测试服务器

- Base URL：`http://localhost:3000/api/v1`
- 数据库：本地 PostgreSQL
- Redis：本地 Redis

### 沙箱环境

~~- 微信支付沙箱：`https://pay.weixin.qq.com/wiki/doc/api/sandbox.php`~~
~~- 支付宝沙箱：`https://openhome.alipay.com/platform/appDaily.htm`~~

❌ 支付功能已删除，不再需要沙箱环境

---

---

## 📊 数据库表设计

### users 表

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE,
  phone_number VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100),
  avatar_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
```

---

### records 表

```sql
CREATE TABLE records (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  timestamp TIMESTAMP NOT NULL,
  location JSONB NOT NULL,  -- {latitude, longitude, address, placeName, placeType}
  description TEXT,
  tags JSONB NOT NULL DEFAULT '[]',  -- [{tag, note}]
  emotion VARCHAR(50),
  status VARCHAR(50) NOT NULL,
  story_line_id UUID,
  if_reencounter TEXT,
  conversation_starter TEXT,
  background_music VARCHAR(255),
  weather JSONB DEFAULT '[]',  -- ["sunny", "breeze"]
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL,
  FOREIGN KEY (story_line_id) REFERENCES story_lines(id) ON DELETE SET NULL
);

CREATE INDEX idx_records_user_id ON records(user_id);
CREATE INDEX idx_records_updated_at ON records(updated_at);
CREATE INDEX idx_records_story_line_id ON records(story_line_id);
CREATE INDEX idx_records_timestamp ON records(timestamp);
```

---

### story_lines 表

```sql
CREATE TABLE story_lines (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  record_ids JSONB NOT NULL DEFAULT '[]',  -- ["uuid1", "uuid2"]
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_story_lines_user_id ON story_lines(user_id);
CREATE INDEX idx_story_lines_updated_at ON story_lines(updated_at);
```

---

### community_posts 表

```sql
CREATE TABLE community_posts (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  record_id UUID NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  address TEXT,
  place_name TEXT,
  place_type VARCHAR(50),
  city_name VARCHAR(100),
  description TEXT,
  tags JSONB NOT NULL DEFAULT '[]',
  status VARCHAR(50) NOT NULL,
  published_at TIMESTAMP NOT NULL DEFAULT NOW(),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_community_posts_published_at ON community_posts(published_at DESC);
CREATE INDEX idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX idx_community_posts_city_name ON community_posts(city_name);
CREATE INDEX idx_community_posts_place_type ON community_posts(place_type);
CREATE INDEX idx_community_posts_status ON community_posts(status);
```

---

### memberships 表

```sql
CREATE TABLE memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  tier VARCHAR(50) NOT NULL DEFAULT 'free',  -- free | premium
  status VARCHAR(50) NOT NULL DEFAULT 'inactive',  -- inactive | active | expired | cancelled
  started_at TIMESTAMP,
  expires_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_memberships_user_id ON memberships(user_id);
CREATE INDEX idx_memberships_expires_at ON memberships(expires_at);
```

---

### ~~payment_orders 表~~ ❌ 已删除

~~支付功能已移除，不再需要此表~~

---

### refresh_tokens 表

```sql
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(255) NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
```

---

### verification_codes 表

```sql
CREATE TABLE verification_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(20) NOT NULL,  -- email | phone
  target VARCHAR(255) NOT NULL,  -- 邮箱或手机号
  code VARCHAR(10) NOT NULL,
  purpose VARCHAR(50) NOT NULL,  -- register | login | reset_password
  expires_at TIMESTAMP NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verification_codes_target ON verification_codes(target);
CREATE INDEX idx_verification_codes_expires_at ON verification_codes(expires_at);
```

---

### user_settings 表

```sql
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  theme VARCHAR(50) DEFAULT 'light',
  page_transition VARCHAR(50) DEFAULT 'slide_from_right',
  dialog_animation VARCHAR(50) DEFAULT 'fade_in',
  notifications JSONB DEFAULT '{"checkInReminder": true, "checkInReminderTime": "20:00", "achievementUnlocked": true}',
  check_in JSONB DEFAULT '{"vibrationEnabled": true, "confettiEnabled": true}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
```

---

**最后更新**：2026-02-25（修正版）  
**文档版本**：v3.0  
**维护者**：AI Assistant + 开发者

**修正内容**：
- ✅ 修正 API 路径（移除重复的 /api/v1）
- ✅ 新增 3 个认证 API（修改密码、更换邮箱、更换手机号）
- ✅ 完善数据同步 API（增量同步说明）
- ✅ 补充故事线 API 详细定义
- ✅ 新增 5 个社区 API
- ✅ 完善支付订单响应（补充缺失字段）
- ✅ 新增用户设置更新 API
- ✅ 补充完整的数据库表设计
- ✅ ~~接口总数从 26 个增加到 35 个~~
- ✅ **删除所有支付相关 API（5个）**
- ✅ **删除 payment_orders 表**
- ✅ **简化 memberships 表（移除 auto_renew 和 monthly_amount）**
- ✅ **接口总数从 35 个减少到 30 个**

