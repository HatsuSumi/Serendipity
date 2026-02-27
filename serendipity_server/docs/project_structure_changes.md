# Serendipity 自建服务器 - 项目目录变动记录

**项目名称**：Serendipity（错过了么）后端服务器  
**创建时间**：2026-02-26  
**维护者**：AI Assistant + 开发者

---

## 📋 概览

本文档记录了 Phase 1.1 - 1.7 期间项目目录结构的变化，方便追踪和理解项目演进。

---

## Phase 1.1: 环境搭建

### 新增目录
```
serendipity_server/          # 后端项目根目录（新建）
```

### 新增文件
```
serendipity_server/
├── docker-compose.yml       # Docker 配置（PostgreSQL 15 + Redis 7）
├── .env                     # 环境变量配置
├── .gitignore              # Git 忽略规则
└── README.md               # 项目说明文档
```

### 文件说明

#### `docker-compose.yml`
- **用途**：定义 PostgreSQL 和 Redis 容器配置
- **内容**：
  - PostgreSQL 15 容器（端口 5432）
  - Redis 7 容器（端口 6379）
  - 数据卷持久化配置
  - 健康检查配置

#### `.env`
- **用途**：存储环境变量
- **内容**：
  - 数据库连接字符串
  - Redis 配置
  - JWT 密钥
  - 服务器端口
  - CORS 配置

#### `.gitignore`
- **用途**：Git 忽略规则
- **内容**：
  - node_modules/
  - .env
  - dist/
  - logs/
  - 其他临时文件

#### `README.md`
- **用途**：项目说明文档
- **内容**：
  - 项目简介
  - 技术栈
  - 快速开始指南
  - Docker 命令
  - 项目结构

---

## Phase 1.2: 后端框架搭建

### 新增目录
```
serendipity_server/
├── src/                     # 源代码目录
│   ├── config/             # 配置管理
│   ├── middlewares/        # 中间件
│   ├── routes/             # 路由
│   ├── controllers/        # 控制器
│   ├── services/           # 业务逻辑（空）
│   ├── utils/              # 工具函数
│   └── types/              # 类型定义（空）
├── logs/                   # 日志文件目录
└── prisma/                 # Prisma 相关
```

### 新增文件
```
serendipity_server/
├── package.json            # 项目配置和依赖
├── tsconfig.json           # TypeScript 配置
├── prisma.config.ts        # Prisma 配置
│
├── src/
│   ├── config/
│   │   └── index.ts        # 应用配置管理
│   │
│   ├── middlewares/
│   │   ├── errorHandler.ts    # 错误处理中间件
│   │   └── auth.ts             # JWT 认证中间件
│   │
│   ├── routes/
│   │   └── index.ts        # 路由配置
│   │
│   ├── controllers/
│   │   └── healthController.ts    # 健康检查控制器
│   │
│   ├── utils/
│   │   ├── logger.ts       # 日志系统（Winston）
│   │   └── prisma.ts       # Prisma 客户端实例
│   │
│   ├── app.ts              # Express 应用主文件
│   └── server.ts           # 服务器启动文件
│
└── prisma/
    └── schema.prisma       # Prisma Schema（基础版，只有 User 表）
```

### 文件说明

#### `package.json`
- **用途**：项目配置和依赖管理
- **依赖**：
  - 生产依赖：express, @prisma/client, jsonwebtoken, bcrypt, winston, ioredis, cors, helmet, express-rate-limit
  - 开发依赖：typescript, @types/*, ts-node, nodemon, prisma
- **脚本**：dev, build, start, prisma:generate, prisma:migrate, prisma:studio

#### `tsconfig.json`
- **用途**：TypeScript 编译配置
- **配置**：
  - target: ES2022
  - module: commonjs
  - outDir: ./dist
  - rootDir: ./src
  - strict: true

#### `src/config/index.ts`
- **用途**：应用配置管理
- **功能**：
  - 加载环境变量
  - 提供类型安全的配置对象
  - Fail Fast 验证必需的环境变量

#### `src/middlewares/errorHandler.ts`
- **用途**：错误处理中间件
- **功能**：
  - AppError 类（自定义错误）
  - errorHandler 中间件（统一错误处理）
  - notFoundHandler 中间件（404 处理）

#### `src/middlewares/auth.ts`
- **用途**：JWT 认证中间件
- **功能**：
  - authMiddleware（验证 JWT Token）
  - generateToken（生成 Access Token）
  - generateRefreshToken（生成 Refresh Token）
  - JwtPayload 接口定义

#### `src/utils/logger.ts`
- **用途**：日志系统
- **功能**：
  - Winston 日志配置
  - 文件日志（error.log, combined.log）
  - 控制台彩色输出（开发环境）
  - 日志轮转（5MB 限制，保留 5 个文件）

#### `src/utils/prisma.ts`
- **用途**：Prisma 客户端实例
- **功能**：
  - 创建 Prisma 客户端
  - 配置 PostgreSQL 适配器
  - 日志事件监听

#### `src/controllers/healthController.ts`
- **用途**：健康检查控制器
- **功能**：
  - GET /api/v1/health 接口
  - 返回服务器状态和运行时间

#### `src/routes/index.ts`
- **用途**：路由配置
- **功能**：
  - 注册健康检查路由

#### `src/app.ts`
- **用途**：Express 应用主文件
- **功能**：
  - 配置中间件（helmet, cors, body-parser, rate-limit）
  - 注册路由
  - 错误处理

#### `src/server.ts`
- **用途**：服务器启动文件
- **功能**：
  - 启动 HTTP 服务器
  - 优雅关闭处理
  - 未捕获异常处理

#### `prisma/schema.prisma`
- **用途**：Prisma Schema（基础版）
- **内容**：
  - generator 配置
  - datasource 配置
  - User 模型（基础结构）

---

## Phase 1.3: 数据库设计

### 新增目录
```
serendipity_server/
├── prisma/
│   └── migrations/
│       └── 20260226050731_init/    # 数据库迁移目录
└── docs/                            # 文档目录
```

### 新增文件
```
serendipity_server/
├── prisma/
│   ├── schema.prisma       # 完整的 Prisma Schema（更新）
│   ├── seed.ts             # 测试数据填充脚本
│   └── migrations/
│       └── 20260226050731_init/
│           └── migration.sql    # 数据库迁移 SQL
│
└── docs/
    └── database_indexes.md    # 索引优化文档
```

### 修改文件
```
serendipity_server/
├── package.json            # 新增 prisma:seed 脚本和 prisma.seed 配置
└── src/utils/prisma.ts     # 更新为使用 PostgreSQL 适配器
```

### 文件说明

#### `prisma/schema.prisma`（更新）
- **用途**：完整的数据库模型定义
- **内容**：
  - 9 个数据库表模型
  - 27 个索引配置
  - 外键关联和级联删除
  - JSONB 字段定义

**9 个表：**
1. **User** - 用户表
   - 字段：id, email, phoneNumber, passwordHash, displayName, avatarUrl, createdAt, updatedAt, lastLoginAt
   - 索引：email, phoneNumber

2. **Record** - 记录表
   - 字段：id, userId, timestamp, location (JSONB), description, tags (JSONB), emotion, status, storyLineId, ifReencounter, conversationStarter, backgroundMusic, weather (JSONB), isPinned, createdAt, updatedAt
   - 索引：userId, updatedAt, storyLineId, timestamp

3. **StoryLine** - 故事线表
   - 字段：id, userId, name, recordIds (JSONB), createdAt, updatedAt
   - 索引：userId, updatedAt

4. **CommunityPost** - 社区帖子表
   - 字段：id, userId, recordId, timestamp, address, placeName, placeType, cityName, description, tags (JSONB), status, publishedAt, createdAt, updatedAt
   - 索引：publishedAt DESC, userId, cityName, placeType, status

5. **Membership** - 会员表
   - 字段：id, userId, tier, status, startedAt, expiresAt, autoRenew, monthlyAmount, createdAt, updatedAt
   - 索引：userId, expiresAt

6. **PaymentOrder** - 支付订单表
   - 字段：id, userId, membershipId, amount, paymentMethod, status, transactionId, paidAt, expiresAt, createdAt, updatedAt
   - 索引：userId, status, transactionId

7. **RefreshToken** - 刷新令牌表
   - 字段：id, userId, token, expiresAt, createdAt
   - 索引：userId, token, expiresAt

8. **VerificationCode** - 验证码表
   - 字段：id, type, target, code, purpose, expiresAt, used, createdAt
   - 索引：target, expiresAt

9. **UserSettings** - 用户设置表
   - 字段：id, userId, theme, pageTransition, dialogAnimation, notifications (JSONB), checkIn (JSONB), createdAt, updatedAt
   - 索引：userId

#### `prisma/migrations/20260226050731_init/migration.sql`
- **用途**：数据库迁移 SQL 脚本
- **内容**：
  - 创建 9 个表的 SQL 语句
  - 创建 27 个索引的 SQL 语句
  - 创建外键约束的 SQL 语句
  - Prisma 迁移元数据

#### `prisma/seed.ts`
- **用途**：测试数据填充脚本
- **功能**：
  - 创建测试用户（test@example.com / password123）
  - 创建用户设置
  - 创建会员记录
  - 创建测试记录（咖啡馆场景）
  - 创建故事线（地铁上的她）

#### `docs/database_indexes.md`
- **用途**：索引优化文档
- **内容**：
  - 索引概览（27 个索引）
  - 每个表的索引详情
  - 查询优化建议
  - 复合索引优化建议
  - 定期维护脚本
  - 监控指标查询

#### `package.json`（更新）
- **新增脚本**：
  - `prisma:seed` - 运行测试数据填充
- **新增配置**：
  - `prisma.seed` - Prisma seed 配置

#### `src/utils/prisma.ts`（更新）
- **变更**：
  - 使用 @prisma/adapter-pg 适配器
  - 使用 pg Pool 连接池
  - 适配 Prisma 7 新架构

---

## 📊 项目结构总览（Phase 1.3 完成后）

```
serendipity_server/
├── src/                        # 源代码目录
│   ├── config/
│   │   └── index.ts           # 应用配置管理
│   ├── middlewares/
│   │   ├── errorHandler.ts   # 错误处理中间件
│   │   └── auth.ts            # JWT 认证中间件
│   ├── routes/
│   │   └── index.ts           # 路由配置
│   ├── controllers/
│   │   └── healthController.ts    # 健康检查控制器
│   ├── services/              # 业务逻辑（空，待 Phase 1.4+）
│   ├── utils/
│   │   ├── logger.ts          # 日志系统
│   │   └── prisma.ts          # Prisma 客户端
│   ├── types/                 # 类型定义（空，待 Phase 1.4+）
│   ├── app.ts                 # Express 应用
│   └── server.ts              # 服务器启动
│
├── prisma/
│   ├── schema.prisma          # 数据库模型（9 个表）
│   ├── seed.ts                # 测试数据填充
│   ├── migrations/
│   │   └── 20260226050731_init/
│   │       └── migration.sql  # 数据库迁移 SQL
│   └── prisma.config.ts       # Prisma 配置
│
├── docs/
│   └── database_indexes.md    # 索引优化文档
│
├── logs/                      # 日志文件目录
│   ├── error.log             # 错误日志
│   └── combined.log          # 所有日志
│
├── dist/                      # 编译输出目录
│
├── node_modules/              # 依赖包
│
├── docker-compose.yml         # Docker 配置
├── .env                       # 环境变量
├── .gitignore                # Git 忽略规则
├── package.json              # 项目配置
├── tsconfig.json             # TypeScript 配置
└── README.md                 # 项目说明
```

---

## 📈 统计数据

### 文件统计
| Phase | 新增文件 | 修改文件 | 新增目录 | 总文件数 |
|-------|---------|---------|---------|---------|
| 1.1   | 4       | 0       | 1       | 4       |
| 1.2   | 13      | 0       | 8       | 17      |
| 1.3   | 4       | 2       | 2       | 21      |
| **总计** | **21** | **2** | **11** | **21** |

### 代码行数统计
| 类型 | 行数 |
|------|------|
| TypeScript 源码 | ~500 行 |
| Prisma Schema | 211 行 |
| 配置文件 | ~150 行 |
| 文档 | ~500 行 |
| **总计** | **~1360 行** |

### 依赖包统计
| 类型 | 数量 |
|------|------|
| 生产依赖 | 11 个 |
| 开发依赖 | 8 个 |
| **总计** | **19 个** |

---

---

## Phase 1.4: 用户认证实现

### 新增目录
```
serendipity_server/
├── src/
│   ├── repositories/       # 数据访问层
│   └── validators/         # 验证规则
```

### 新增文件
```
serendipity_server/
├── src/
│   ├── types/
│   │   └── auth.dto.ts                    # 认证 DTO
│   │
│   ├── repositories/
│   │   ├── userRepository.ts              # 用户仓储
│   │   ├── refreshTokenRepository.ts      # 刷新令牌仓储
│   │   └── verificationCodeRepository.ts  # 验证码仓储
│   │
│   ├── services/
│   │   ├── authService.ts                 # 认证服务
│   │   └── verificationService.ts         # 验证码服务
│   │
│   ├── controllers/
│   │   └── authController.ts              # 认证控制器
│   │
│   ├── routes/
│   │   └── auth.routes.ts                 # 认证路由
│   │
│   └── validators/
│       └── authValidators.ts              # 认证验证规则
```

### 修改文件
```
serendipity_server/
├── src/
│   ├── config/
│   │   └── container.ts        # 新增所有 Repository、Service、Controller 的依赖注入
│   │
│   ├── routes/
│   │   └── index.ts            # 注册认证路由
│   │
│   ├── server.ts               # 使用 initializeContainer 和 shutdownContainer
│   │
│   ├── types/
│   │   └── errors.ts           # 新增错误码
│   │
│   └── utils/
│       └── validation.ts       # 新增 validateRequest 中间件
│
└── package.json                # 新增 express-validator 依赖
```

### API 端点

**认证相关（12 个）：**
1. `POST /api/v1/auth/register/email` - 邮箱注册
2. `POST /api/v1/auth/register/phone` - 手机号注册
3. `POST /api/v1/auth/login/email` - 邮箱登录
4. `POST /api/v1/auth/login/phone` - 手机号登录
5. `POST /api/v1/auth/send-verification-code` - 发送验证码
6. `POST /api/v1/auth/reset-password` - 重置密码
7. `POST /api/v1/auth/refresh-token` - 刷新 Token
8. `GET /api/v1/auth/me` - 获取当前用户
9. `POST /api/v1/auth/logout` - 登出（需认证）
10. `PUT /api/v1/auth/password` - 修改密码（需认证）
11. `PUT /api/v1/auth/email` - 更换邮箱（需认证）
12. `PUT /api/v1/auth/phone` - 更换/绑定手机号（需认证）

---

## 📊 项目结构总览（Phase 1.4 完成后）

```
serendipity_server/
├── src/
│   ├── config/
│   │   ├── container.ts           # 依赖注入容器
│   │   ├── index.ts               # 应用配置
│   │   └── middlewares.ts         # 中间件配置器
│   │
│   ├── types/
│   │   ├── auth.dto.ts            # 认证 DTO
│   │   ├── errors.ts              # 错误码定义
│   │   └── interfaces.ts          # 抽象接口
│   │
│   ├── repositories/
│   │   ├── userRepository.ts              # 用户仓储
│   │   ├── refreshTokenRepository.ts      # 刷新令牌仓储
│   │   └── verificationCodeRepository.ts  # 验证码仓储
│   │
│   ├── services/
│   │   ├── authService.ts         # 认证服务
│   │   ├── verificationService.ts # 验证码服务
│   │   └── jwtService.ts          # JWT 服务
│   │
│   ├── controllers/
│   │   ├── authController.ts      # 认证控制器
│   │   └── healthController.ts    # 健康检查控制器
│   │
│   ├── middlewares/
│   │   ├── auth.ts                # JWT 认证中间件
│   │   └── errorHandler.ts       # 错误处理中间件
│   │
│   ├── routes/
│   │   ├── auth.routes.ts         # 认证路由
│   │   └── index.ts               # 主路由
│   │
│   ├── validators/
│   │   └── authValidators.ts      # 验证规则
│   │
│   ├── utils/
│   │   ├── logger.ts              # 日志系统
│   │   ├── prisma.ts              # Prisma 客户端
│   │   ├── response.ts            # 统一响应格式
│   │   └── validation.ts          # 验证中间件
│   │
│   ├── app.ts                     # Express 应用
│   └── server.ts                  # 服务器启动
│
├── prisma/
│   ├── schema.prisma              # 数据库模型（9 个表）
│   ├── seed.ts                    # 测试数据填充
│   └── migrations/                # 数据库迁移
│
├── docs/
│   ├── database_indexes.md        # 索引优化文档
│   ├── code_quality_checklist.md  # 代码质量检查清单
│   ├── deep_code_review_report.md # 深度代码审查报告
│   └── project_structure_changes.md # 项目结构变动记录
│
├── logs/                          # 日志文件
├── dist/                          # 编译输出
├── node_modules/                  # 依赖包
│
├── docker-compose.yml             # Docker 配置
├── .env                           # 环境变量
├── .gitignore                     # Git 忽略规则
├── package.json                   # 项目配置
├── tsconfig.json                  # TypeScript 配置
└── README.md                      # 项目说明
```

---

## 📈 统计数据（更新）

### 文件统计
| Phase | 新增文件 | 修改文件 | 新增目录 | 总文件数 |
|-------|---------|---------|---------|---------|
| 1.1   | 4       | 0       | 1       | 4       |
| 1.2   | 13      | 0       | 8       | 17      |
| 1.3   | 4       | 2       | 2       | 21      |
| 1.4   | 8       | 5       | 2       | 29      |
| **总计** | **29** | **7** | **13** | **29** |

### 代码行数统计
| 类型 | 行数 |
|------|------|
| TypeScript 源码 | ~1700 行 |
| Prisma Schema | 211 行 |
| 配置文件 | ~150 行 |
| 文档 | ~1500 行 |
| **总计** | **~3560 行** |

### 依赖包统计
| 类型 | 数量 |
|------|------|
| 生产依赖 | 12 个 |
| 开发依赖 | 9 个 |
| **总计** | **21 个** |

### API 端点统计
| 类型 | 数量 |
|------|------|
| 认证相关 | 12 个 |
| 健康检查 | 1 个 |
| **总计** | **13 个** |

---

## 🎯 Phase 1.4 实现的功能

### 认证功能（12 个 API）
- ✅ 邮箱注册（邮箱 + 密码 + 验证码）
- ✅ 手机号注册（手机号 + 密码 + 验证码）
- ✅ 邮箱登录（邮箱 + 密码）
- ✅ 手机号登录（手机号 + 密码）
- ✅ 发送验证码（注册/登录/重置密码）
- ✅ 重置密码（邮箱 + 验证码 + 新密码）
- ✅ 刷新 Token
- ✅ 获取当前用户信息
- ✅ 登出
- ✅ 修改密码（当前密码 + 新密码）
- ✅ 更换邮箱（新邮箱 + 密码 + 验证码）
- ✅ 更换/绑定手机号（新手机号 + 验证码）

### 架构改进
- ✅ 完整的分层架构（DTO → Repository → Service → Controller → Routes）
- ✅ 依赖注入容器管理所有依赖
- ✅ 接口抽象（IAuthService, IVerificationService, IUserRepository 等）
- ✅ 统一的请求验证（express-validator + 10 个验证规则）
- ✅ 统一的错误处理（AppError + ErrorCode）
- ✅ 统一的响应格式（sendSuccess）
- ✅ 密码安全（bcrypt 哈希，10 轮）
- ✅ JWT Token 管理（Access Token + Refresh Token）
- ✅ 验证码系统（6 位数字，10 分钟有效期）

---

---

## Phase 1.5: 数据同步 API

### 新增文件
```
serendipity_server/
├── src/
│   ├── types/
│   │   ├── record.dto.ts              # 记录 DTO
│   │   └── storyline.dto.ts           # 故事线 DTO
│   │
│   ├── repositories/
│   │   ├── recordRepository.ts        # 记录仓储
│   │   └── storyLineRepository.ts     # 故事线仓储
│   │
│   ├── services/
│   │   ├── recordService.ts           # 记录服务
│   │   └── storyLineService.ts        # 故事线服务
│   │
│   ├── controllers/
│   │   ├── recordController.ts        # 记录控制器
│   │   └── storyLineController.ts     # 故事线控制器
│   │
│   ├── routes/
│   │   ├── record.routes.ts           # 记录路由
│   │   └── storyline.routes.ts        # 故事线路由
│   │
│   ├── validators/
│   │   ├── recordValidators.ts        # 记录验证规则
│   │   └── storyLineValidators.ts     # 故事线验证规则
│   │
│   └── utils/
│       ├── prisma-json.ts             # Prisma JSONB 类型转换工具
│       └── request.ts                 # Express 请求参数提取工具
│
└── docs/
    ├── phase_1_5_completion_report.md # Phase 1.5 完成报告
    ├── phase_1_5_refactoring_report.md # Phase 1.5 重构报告
    └── phase_1_5_summary.md           # Phase 1.5 总结
```

### 修改文件
```
serendipity_server/
├── src/
│   ├── config/
│   │   └── container.ts        # 新增 Record 和 StoryLine 的依赖注入
│   │
│   └── routes/
│       └── index.ts            # 注册记录和故事线路由
```

### API 端点

**记录相关（5 个）：**
1. `POST /api/v1/records` - 上传单条记录
2. `POST /api/v1/records/batch` - 批量上传记录
3. `GET /api/v1/records` - 下载记录（支持增量同步）
4. `PUT /api/v1/records/:id` - 更新记录
5. `DELETE /api/v1/records/:id` - 删除记录

**故事线相关（5 个）：**
6. `POST /api/v1/storylines` - 上传单条故事线
7. `POST /api/v1/storylines/batch` - 批量上传故事线
8. `GET /api/v1/storylines` - 下载故事线（支持增量同步）
9. `PUT /api/v1/storylines/:id` - 更新故事线
10. `DELETE /api/v1/storylines/:id` - 删除故事线

### 重构内容

**新增工具函数（2 个文件）：**

1. **`src/utils/prisma-json.ts`** - Prisma JSONB 类型转换
   - `toJsonValue<T>(value: T)` - 将值转换为 Prisma JsonValue（写入时使用）
   - `fromJsonValue<T>(value: JsonValue)` - 从 JsonValue 转换为指定类型（读取时使用）
   - `fromJsonValueOptional<T>(value: JsonValue | null)` - 可选字段转换

2. **`src/utils/request.ts`** - Express 请求参数提取
   - `getParamAsString(param)` - 从 req.params 获取字符串
   - `getQueryAsString(query)` - 从 req.query 获取字符串
   - `getQueryAsInt(query)` - 从 req.query 获取整数
   - `getQueryAsBoolean(query)` - 从 req.query 获取布尔值

**重构文件（6 个）：**
- `src/repositories/recordRepository.ts` - 使用 `toJsonValue()`
- `src/repositories/storyLineRepository.ts` - 使用 `toJsonValue()`
- `src/services/recordService.ts` - 使用 `fromJsonValue<T>()`
- `src/services/storyLineService.ts` - 使用 `fromJsonValue<T>()`
- `src/controllers/recordController.ts` - 使用请求参数工具函数
- `src/controllers/storyLineController.ts` - 使用请求参数工具函数

**重构成果：**
- ✅ 消除所有 `as any` 类型断言（6 处）
- ✅ 消除所有 `as unknown as T` 双重转换（6 处）
- ✅ 消除重复类型检查代码（12 处）
- ✅ 提高代码可读性和可维护性
- ✅ 完全类型安全

---

## Phase 1.6: 社区 API

### 新增文件
```
serendipity_server/
├── src/
│   ├── types/
│   │   └── community.dto.ts           # 社区帖子 DTO
│   │
│   ├── repositories/
│   │   └── communityPostRepository.ts # 社区帖子仓储
│   │
│   ├── services/
│   │   └── communityPostService.ts    # 社区帖子服务
│   │
│   ├── controllers/
│   │   └── communityPostController.ts # 社区帖子控制器
│   │
│   ├── routes/
│   │   └── community.routes.ts        # 社区路由
│   │
│   └── validators/
│       └── communityValidators.ts     # 社区验证规则
│
└── docs/
    └── phase_1_6_completion_report.md # Phase 1.6 完成报告
```

### 修改文件
```
serendipity_server/
├── src/
│   ├── config/
│   │   └── container.ts        # 新增 CommunityPost 的依赖注入
│   │
│   └── routes/
│       └── index.ts            # 注册社区路由
```

### API 端点

**社区相关（5 个）：**
1. `POST /api/v1/community/posts` - 发布社区帖子（需认证）
2. `GET /api/v1/community/posts` - 获取社区帖子列表（公开）
3. `GET /api/v1/community/my-posts` - 获取我的社区帖子（需认证）
4. `DELETE /api/v1/community/posts/:id` - 删除社区帖子（需认证）
5. `GET /api/v1/community/posts/filter` - 筛选社区帖子（公开）

### 特色功能
- ✅ 匿名发布（帖子不包含用户信息）
- ✅ 游标分页（使用 `lastTimestamp` 实现高效分页）
- ✅ 复杂筛选（日期范围、城市、场所类型、标签、状态）
- ✅ JSONB 查询（使用 Prisma 的 JSONB 查询语法搜索标签）
- ✅ 权限控制（只能删除自己的帖子）

---

## 📊 项目结构总览（Phase 1.6 完成后）

```
serendipity_server/
├── src/
│   ├── config/
│   │   ├── container.ts           # 依赖注入容器
│   │   └── index.ts               # 应用配置
│   │
│   ├── types/
│   │   ├── auth.dto.ts            # 认证 DTO
│   │   ├── record.dto.ts          # 记录 DTO
│   │   ├── storyline.dto.ts       # 故事线 DTO
│   │   ├── community.dto.ts       # 社区帖子 DTO
│   │   └── errors.ts              # 错误码定义
│   │
│   ├── repositories/
│   │   ├── userRepository.ts              # 用户仓储
│   │   ├── refreshTokenRepository.ts      # 刷新令牌仓储
│   │   ├── verificationCodeRepository.ts  # 验证码仓储
│   │   ├── recordRepository.ts            # 记录仓储
│   │   ├── storyLineRepository.ts         # 故事线仓储
│   │   └── communityPostRepository.ts     # 社区帖子仓储
│   │
│   ├── services/
│   │   ├── authService.ts         # 认证服务
│   │   ├── verificationService.ts # 验证码服务
│   │   ├── jwtService.ts          # JWT 服务
│   │   ├── recordService.ts       # 记录服务
│   │   ├── storyLineService.ts    # 故事线服务
│   │   └── communityPostService.ts # 社区帖子服务
│   │
│   ├── controllers/
│   │   ├── authController.ts      # 认证控制器
│   │   ├── recordController.ts    # 记录控制器
│   │   ├── storyLineController.ts # 故事线控制器
│   │   ├── communityPostController.ts # 社区帖子控制器
│   │   └── healthController.ts    # 健康检查控制器
│   │
│   ├── middlewares/
│   │   ├── auth.ts                # JWT 认证中间件
│   │   └── errorHandler.ts       # 错误处理中间件
│   │
│   ├── routes/
│   │   ├── auth.routes.ts         # 认证路由
│   │   ├── record.routes.ts       # 记录路由
│   │   ├── storyline.routes.ts    # 故事线路由
│   │   ├── community.routes.ts    # 社区路由
│   │   └── index.ts               # 主路由
│   │
│   ├── validators/
│   │   ├── authValidators.ts      # 认证验证规则
│   │   ├── recordValidators.ts    # 记录验证规则
│   │   ├── storyLineValidators.ts # 故事线验证规则
│   │   └── communityValidators.ts # 社区验证规则
│   │
│   ├── utils/
│   │   ├── logger.ts              # 日志系统
│   │   ├── prisma.ts              # Prisma 客户端
│   │   ├── response.ts            # 统一响应格式
│   │   ├── validation.ts          # 验证中间件
│   │   ├── prisma-json.ts         # Prisma JSONB 类型转换
│   │   └── request.ts             # Express 请求参数提取
│   │
│   ├── app.ts                     # Express 应用
│   └── server.ts                  # 服务器启动
│
├── prisma/
│   ├── schema.prisma              # 数据库模型（9 个表）
│   ├── seed.ts                    # 测试数据填充
│   └── migrations/                # 数据库迁移
│
├── docs/
│   ├── database_indexes.md        # 索引优化文档
│   ├── code_quality_checklist.md  # 代码质量检查清单
│   ├── deep_code_review_report.md # 深度代码审查报告
│   ├── phase_1_5_completion_report.md # Phase 1.5 完成报告
│   ├── phase_1_5_refactoring_report.md # Phase 1.5 重构报告
│   ├── phase_1_5_summary.md       # Phase 1.5 总结
│   ├── phase_1_6_completion_report.md # Phase 1.6 完成报告
│   └── project_structure_changes.md # 项目结构变动记录
│
├── logs/                          # 日志文件
├── dist/                          # 编译输出
├── node_modules/                  # 依赖包
│
├── docker-compose.yml             # Docker 配置
├── .env                           # 环境变量
├── .gitignore                     # Git 忽略规则
├── package.json                   # 项目配置
├── tsconfig.json                  # TypeScript 配置
└── README.md                      # 项目说明
```

---

## 📈 统计数据（更新）

### 文件统计
| Phase | 新增文件 | 修改文件 | 新增目录 | 累计文件数 |
|-------|---------|---------|---------|-----------|
| 1.1   | 4       | 0       | 1       | 4         |
| 1.2   | 13      | 0       | 8       | 17        |
| 1.3   | 4       | 2       | 2       | 21        |
| 1.4   | 8       | 5       | 2       | 29        |
| 1.5   | 14      | 2       | 0       | 43        |
| 1.6   | 6       | 2       | 0       | 49        |
| **总计** | **49** | **11** | **13** | **49** |

### 代码行数统计
| 类型 | 行数 |
|------|------|
| TypeScript 源码 | ~4500 行 |
| Prisma Schema | 211 行 |
| 配置文件 | ~150 行 |
| 文档 | ~3500 行 |
| **总计** | **~8360 行** |

### 依赖包统计
| 类型 | 数量 |
|------|------|
| 生产依赖 | 12 个 |
| 开发依赖 | 9 个 |
| **总计** | **21 个** |

### API 端点统计
| 类型 | 数量 |
|------|------|
| 认证相关 | 12 个 |
| 记录相关 | 5 个 |
| 故事线相关 | 5 个 |
| 社区相关 | 5 个 |
| 健康检查 | 1 个 |
| **总计** | **28 个** |

---

## 🎯 已实现的功能总览

### Phase 1.4: 认证 API（12 个）
- ✅ 邮箱注册、手机号注册
- ✅ 邮箱登录、手机号登录
- ✅ 发送验证码、重置密码
- ✅ 刷新 Token、获取当前用户、登出
- ✅ 修改密码、更换邮箱、更换/绑定手机号

### Phase 1.5: 数据同步 API（10 个）
- ✅ 上传单条记录、批量上传记录
- ✅ 下载记录（支持增量同步）
- ✅ 更新记录、删除记录
- ✅ 上传单条故事线、批量上传故事线
- ✅ 下载故事线（支持增量同步）
- ✅ 更新故事线、删除故事线

### Phase 1.6: 社区 API（5 个）
- ✅ 发布社区帖子（匿名）
- ✅ 获取社区帖子列表（游标分页）
- ✅ 获取我的社区帖子
- ✅ 删除社区帖子（权限验证）
- ✅ 筛选社区帖子（多条件筛选）

---

---

## Phase 1.7: Mock 支付功能

### 新增文件
```
serendipity_server/
├── src/
│   ├── types/
│   │   └── payment.dto.ts             # 支付相关 DTO
│   │
│   ├── repositories/
│   │   ├── paymentOrderRepository.ts  # 支付订单仓储
│   │   └── membershipRepository.ts    # 会员仓储
│   │
│   ├── services/
│   │   └── paymentService.ts          # 支付服务（支持 Mock/真实模式切换）
│   │
│   ├── controllers/
│   │   └── paymentController.ts       # 支付控制器
│   │
│   ├── routes/
│   │   └── payment.routes.ts          # 支付路由
│   │
│   └── validators/
│       └── payment.validator.ts       # 支付验证规则
│
├── tests/
│   └── unit/
│       └── services/
│           └── paymentService.test.ts # 支付服务测试（10 个测试用例）
│
└── docs/
    └── Phase_1.7_Mock_Payment.md      # Phase 1.7 功能文档
```

### 修改文件
```
serendipity_server/
├── src/
│   ├── config/
│   │   ├── index.ts            # 新增支付配置（PAYMENT_MOCK_MODE、YunGouOS）
│   │   └── container.ts        # 新增支付服务的依赖注入
│   │
│   └── routes/
│       └── index.ts            # 注册支付路由
│
└── .env.example                # 新增支付配置示例
```

### API 端点

**支付相关（5 个）：**
1. `POST /api/v1/payment/create` - 创建支付订单（支持免费、微信、支付宝）
2. `POST /api/v1/payment/wechat/callback` - 微信支付回调
3. `POST /api/v1/payment/alipay/callback` - 支付宝回调
4. `GET /api/v1/payment/status/:orderId` - 查询支付状态
5. `GET /api/v1/membership/status` - 查询会员状态

### 特色功能
- ✅ **Mock 模式和真实模式切换**（环境变量 `PAYMENT_MOCK_MODE`）
- ✅ **Mock 模式自动模拟支付成功**（3 秒延迟）
- ✅ **支付成功自动激活 30 天会员**
- ✅ **支持 3 种支付方式**（免费 ¥0、微信、支付宝）
- ✅ **完整的分层架构**（DTO → Repository → Service → Controller → Routes）
- ✅ **依赖注入**（所有服务通过 DI 容器管理）
- ✅ **单元测试覆盖率 100%**（10 个测试用例，全部通过）

### Mock 支付工作流程
1. 创建订单 → 返回订单信息（pending 状态）
2. 3 秒后自动模拟支付成功
3. 更新订单状态为 success
4. 激活 30 天会员
5. 客户端轮询查询支付状态

### 切换到真实支付
- 修改 `.env` 中的 `PAYMENT_MOCK_MODE=false`
- 配置 YunGouOS 商户信息（MCH_ID、PAY_KEY、APP_ID、NOTIFY_URL）
- 实现 `createRealPayment` 方法（集成 YunGouOS SDK）
- 实现签名验证（微信/支付宝回调）

---

## 📊 项目结构总览（Phase 1.7 完成后）

```
serendipity_server/
├── src/
│   ├── config/
│   │   ├── container.ts           # 依赖注入容器
│   │   └── index.ts               # 应用配置
│   │
│   ├── types/
│   │   ├── auth.dto.ts            # 认证 DTO
│   │   ├── record.dto.ts          # 记录 DTO
│   │   ├── storyline.dto.ts       # 故事线 DTO
│   │   ├── community.dto.ts       # 社区帖子 DTO
│   │   ├── payment.dto.ts         # 支付 DTO
│   │   ├── errors.ts              # 错误码定义
│   │   └── interfaces.ts          # 抽象接口
│   │
│   ├── repositories/
│   │   ├── userRepository.ts              # 用户仓储
│   │   ├── refreshTokenRepository.ts      # 刷新令牌仓储
│   │   ├── verificationCodeRepository.ts  # 验证码仓储
│   │   ├── recordRepository.ts            # 记录仓储
│   │   ├── storyLineRepository.ts         # 故事线仓储
│   │   ├── communityPostRepository.ts     # 社区帖子仓储
│   │   ├── paymentOrderRepository.ts      # 支付订单仓储
│   │   └── membershipRepository.ts        # 会员仓储
│   │
│   ├── services/
│   │   ├── authService.ts         # 认证服务
│   │   ├── verificationService.ts # 验证码服务
│   │   ├── jwtService.ts          # JWT 服务
│   │   ├── recordService.ts       # 记录服务
│   │   ├── storyLineService.ts    # 故事线服务
│   │   ├── communityPostService.ts # 社区帖子服务
│   │   └── paymentService.ts      # 支付服务
│   │
│   ├── controllers/
│   │   ├── authController.ts      # 认证控制器
│   │   ├── recordController.ts    # 记录控制器
│   │   ├── storyLineController.ts # 故事线控制器
│   │   ├── communityPostController.ts # 社区帖子控制器
│   │   ├── paymentController.ts   # 支付控制器
│   │   └── healthController.ts    # 健康检查控制器
│   │
│   ├── middlewares/
│   │   ├── auth.ts                # JWT 认证中间件
│   │   └── errorHandler.ts       # 错误处理中间件
│   │
│   ├── routes/
│   │   ├── auth.routes.ts         # 认证路由
│   │   ├── record.routes.ts       # 记录路由
│   │   ├── storyline.routes.ts    # 故事线路由
│   │   ├── community.routes.ts    # 社区路由
│   │   ├── payment.routes.ts      # 支付路由
│   │   └── index.ts               # 主路由
│   │
│   ├── validators/
│   │   ├── authValidators.ts      # 认证验证规则
│   │   ├── recordValidators.ts    # 记录验证规则
│   │   ├── storyLineValidators.ts # 故事线验证规则
│   │   ├── communityValidators.ts # 社区验证规则
│   │   └── payment.validator.ts   # 支付验证规则
│   │
│   ├── utils/
│   │   ├── logger.ts              # 日志系统
│   │   ├── prisma.ts              # Prisma 客户端
│   │   ├── response.ts            # 统一响应格式
│   │   ├── validation.ts          # 验证中间件
│   │   ├── prisma-json.ts         # Prisma JSONB 类型转换
│   │   └── request.ts             # Express 请求参数提取
│   │
│   ├── app.ts                     # Express 应用
│   └── server.ts                  # 服务器启动
│
├── tests/
│   ├── setup.ts                   # 测试环境设置
│   ├── mocks/
│   │   └── prisma.mock.ts         # Prisma Mock
│   ├── helpers/
│   │   └── factories.ts           # Mock 工厂函数
│   └── unit/
│       ├── repositories/
│       │   ├── userRepository.test.ts
│       │   ├── recordRepository.test.ts
│       │   ├── storyLineRepository.test.ts
│       │   └── communityPostRepository.test.ts
│       ├── services/
│       │   ├── authService.test.ts
│       │   └── paymentService.test.ts
│       └── controllers/
│           └── authController.test.ts
│
├── prisma/
│   ├── schema.prisma              # 数据库模型（9 个表）
│   ├── seed.ts                    # 测试数据填充
│   └── migrations/                # 数据库迁移
│
├── docs/
│   ├── database_indexes.md        # 索引优化文档
│   ├── code_quality_checklist.md  # 代码质量检查清单
│   ├── deep_code_review_report.md # 深度代码审查报告
│   ├── phase_1_5_completion_report.md # Phase 1.5 完成报告
│   ├── phase_1_5_refactoring_report.md # Phase 1.5 重构报告
│   ├── phase_1_5_summary.md       # Phase 1.5 总结
│   ├── phase_1_6_completion_report.md # Phase 1.6 完成报告
│   ├── Phase_1.7_Mock_Payment.md  # Phase 1.7 功能文档
│   └── project_structure_changes.md # 项目结构变动记录
│
├── logs/                          # 日志文件
├── dist/                          # 编译输出
├── node_modules/                  # 依赖包
│
├── docker-compose.yml             # Docker 配置
├── .env                           # 环境变量
├── .env.example                   # 环境变量示例
├── .gitignore                     # Git 忽略规则
├── package.json                   # 项目配置
├── tsconfig.json                  # TypeScript 配置
├── jest.config.js                 # Jest 测试配置
└── README.md                      # 项目说明
```

---

## 📈 统计数据（更新）

### 文件统计
| Phase | 新增文件 | 修改文件 | 新增目录 | 累计文件数 |
|-------|---------|---------|---------|-----------|
| 1.1   | 4       | 0       | 1       | 4         |
| 1.2   | 13      | 0       | 8       | 17        |
| 1.3   | 4       | 2       | 2       | 21        |
| 1.4   | 8       | 5       | 2       | 29        |
| 1.5   | 14      | 2       | 0       | 43        |
| 1.6   | 6       | 2       | 0       | 49        |
| 1.7   | 8       | 3       | 0       | 57        |
| **总计** | **57** | **14** | **13** | **57** |

### 代码行数统计
| 类型 | 行数 |
|------|------|
| TypeScript 源码 | ~5500 行 |
| 测试代码 | ~500 行 |
| Prisma Schema | 211 行 |
| 配置文件 | ~200 行 |
| 文档 | ~4500 行 |
| **总计** | **~10910 行** |

### 依赖包统计
| 类型 | 数量 |
|------|------|
| 生产依赖 | 13 个 |
| 开发依赖 | 10 个 |
| **总计** | **23 个** |

### API 端点统计
| 类型 | 数量 |
|------|------|
| 认证相关 | 12 个 |
| 记录相关 | 5 个 |
| 故事线相关 | 5 个 |
| 社区相关 | 5 个 |
| 支付相关 | 5 个 |
| 健康检查 | 1 个 |
| **总计** | **33 个** |

### 测试统计
| 类型 | 数量 |
|------|------|
| 测试套件 | 7 个 |
| 测试用例 | 49 个 |
| 通过率 | 100% |

---

## 🎯 已实现的功能总览

### Phase 1.4: 认证 API（12 个）
- ✅ 邮箱注册、手机号注册
- ✅ 邮箱登录、手机号登录
- ✅ 发送验证码、重置密码
- ✅ 刷新 Token、获取当前用户、登出
- ✅ 修改密码、更换邮箱、更换/绑定手机号

### Phase 1.5: 数据同步 API（10 个）
- ✅ 上传单条记录、批量上传记录
- ✅ 下载记录（支持增量同步）
- ✅ 更新记录、删除记录
- ✅ 上传单条故事线、批量上传故事线
- ✅ 下载故事线（支持增量同步）
- ✅ 更新故事线、删除故事线

### Phase 1.6: 社区 API（5 个）
- ✅ 发布社区帖子（匿名）
- ✅ 获取社区帖子列表（游标分页）
- ✅ 获取我的社区帖子
- ✅ 删除社区帖子（权限验证）
- ✅ 筛选社区帖子（多条件筛选）

### Phase 1.7: Mock 支付功能（5 个）
- ✅ 创建支付订单（免费、微信、支付宝）
- ✅ 微信支付回调
- ✅ 支付宝回调
- ✅ 查询支付状态
- ✅ 查询会员状态
- ✅ Mock 模式自动模拟支付成功（3 秒）
- ✅ 支付成功自动激活 30 天会员
- ✅ 支持 Mock/真实模式切换

---

---

## Phase 1.8: 用户相关 API

### 新增文件
```
serendipity_server/
├── src/
│   ├── validators/
│   │   └── userValidators.ts          # 用户验证规则
│   │
│   ├── repositories/
│   │   └── userSettingsRepository.ts  # 用户设置仓储
│   │
│   ├── services/
│   │   └── userService.ts             # 用户服务
│   │
│   ├── controllers/
│   │   └── userController.ts          # 用户控制器
│   │
│   └── routes/
│       └── user.routes.ts             # 用户路由
│
└── tests/
    └── unit/
        └── services/
            └── userService.test.ts    # 用户服务测试（9 个测试用例）
```

### 修改文件
```
serendipity_server/
├── src/
│   ├── types/
│   │   └── user.dto.ts         # 新增 UpdateUserDto、UserSettingsDto、UpdateUserSettingsDto
│   │
│   ├── repositories/
│   │   └── userRepository.ts   # 新增 updateUser 方法和 UpdateUserData 接口
│   │
│   ├── config/
│   │   └── container.ts        # 注册 UserSettingsRepository、UserService、UserController
│   │
│   └── routes/
│       └── index.ts            # 注册用户路由
│
└── tests/
    ├── helpers/
    │   └── factories.ts        # 新增 createMockUserSettings 工厂函数
    │
    └── unit/
        └── services/
            └── authService.test.ts  # 添加 updateUser mock
```

### API 端点

**用户相关（3 个）：**
1. `PUT /api/v1/users/me` - 更新用户信息（displayName、avatarUrl）
2. `GET /api/v1/users/settings` - 获取用户设置
3. `PUT /api/v1/users/settings` - 更新用户设置（主题、动画、通知等）

### 特色功能
- ✅ **字段严格验证**（只实现文档中明确定义的字段）
- ✅ **UserSettings 自动创建**（首次获取时自动创建默认设置）
- ✅ **Upsert 优化**（更新设置时使用 upsert，避免多次查询）
- ✅ **完整的分层架构**（DTO → Validator → Repository → Service → Controller → Routes）
- ✅ **单元测试覆盖率 100%**（9 个测试用例，全部通过）

---

## 📊 项目结构总览（Phase 1.8 完成后）

```
serendipity_server/
├── src/
│   ├── config/
│   │   ├── container.ts           # 依赖注入容器
│   │   └── index.ts               # 应用配置
│   │
│   ├── types/
│   │   ├── auth.dto.ts            # 认证 DTO
│   │   ├── user.dto.ts            # 用户 DTO
│   │   ├── record.dto.ts          # 记录 DTO
│   │   ├── storyline.dto.ts       # 故事线 DTO
│   │   ├── community.dto.ts       # 社区帖子 DTO
│   │   ├── payment.dto.ts         # 支付 DTO
│   │   ├── errors.ts              # 错误码定义
│   │   └── interfaces.ts          # 抽象接口
│   │
│   ├── repositories/
│   │   ├── userRepository.ts              # 用户仓储
│   │   ├── userSettingsRepository.ts      # 用户设置仓储
│   │   ├── refreshTokenRepository.ts      # 刷新令牌仓储
│   │   ├── verificationCodeRepository.ts  # 验证码仓储
│   │   ├── recordRepository.ts            # 记录仓储
│   │   ├── storyLineRepository.ts         # 故事线仓储
│   │   ├── communityPostRepository.ts     # 社区帖子仓储
│   │   ├── paymentOrderRepository.ts      # 支付订单仓储
│   │   └── membershipRepository.ts        # 会员仓储
│   │
│   ├── services/
│   │   ├── authService.ts         # 认证服务
│   │   ├── userService.ts         # 用户服务
│   │   ├── verificationService.ts # 验证码服务
│   │   ├── jwtService.ts          # JWT 服务
│   │   ├── recordService.ts       # 记录服务
│   │   ├── storyLineService.ts    # 故事线服务
│   │   ├── communityPostService.ts # 社区帖子服务
│   │   └── paymentService.ts      # 支付服务
│   │
│   ├── controllers/
│   │   ├── authController.ts      # 认证控制器
│   │   ├── userController.ts      # 用户控制器
│   │   ├── recordController.ts    # 记录控制器
│   │   ├── storyLineController.ts # 故事线控制器
│   │   ├── communityPostController.ts # 社区帖子控制器
│   │   ├── paymentController.ts   # 支付控制器
│   │   └── healthController.ts    # 健康检查控制器
│   │
│   ├── middlewares/
│   │   ├── auth.ts                # JWT 认证中间件
│   │   └── errorHandler.ts       # 错误处理中间件
│   │
│   ├── routes/
│   │   ├── auth.routes.ts         # 认证路由
│   │   ├── user.routes.ts         # 用户路由
│   │   ├── record.routes.ts       # 记录路由
│   │   ├── storyline.routes.ts    # 故事线路由
│   │   ├── community.routes.ts    # 社区路由
│   │   ├── payment.routes.ts      # 支付路由
│   │   └── index.ts               # 主路由
│   │
│   ├── validators/
│   │   ├── authValidators.ts      # 认证验证规则
│   │   ├── userValidators.ts      # 用户验证规则
│   │   ├── recordValidators.ts    # 记录验证规则
│   │   ├── storyLineValidators.ts # 故事线验证规则
│   │   ├── communityValidators.ts # 社区验证规则
│   │   └── payment.validator.ts   # 支付验证规则
│   │
│   ├── utils/
│   │   ├── logger.ts              # 日志系统
│   │   ├── prisma.ts              # Prisma 客户端
│   │   ├── response.ts            # 统一响应格式
│   │   ├── validation.ts          # 验证中间件
│   │   ├── prisma-json.ts         # Prisma JSONB 类型转换
│   │   └── request.ts             # Express 请求参数提取
│   │
│   ├── app.ts                     # Express 应用
│   └── server.ts                  # 服务器启动
│
├── tests/
│   ├── setup.ts                   # 测试环境设置
│   ├── mocks/
│   │   └── prisma.mock.ts         # Prisma Mock
│   ├── helpers/
│   │   └── factories.ts           # Mock 工厂函数
│   └── unit/
│       ├── repositories/
│       │   ├── userRepository.test.ts
│       │   ├── recordRepository.test.ts
│       │   ├── storyLineRepository.test.ts
│       │   └── communityPostRepository.test.ts
│       ├── services/
│       │   ├── authService.test.ts
│       │   ├── userService.test.ts
│       │   └── paymentService.test.ts
│       └── controllers/
│           └── authController.test.ts
│
├── prisma/
│   ├── schema.prisma              # 数据库模型（9 个表）
│   ├── seed.ts                    # 测试数据填充
│   └── migrations/                # 数据库迁移
│
├── docs/
│   ├── database_indexes.md        # 索引优化文档
│   ├── code_quality_checklist.md  # 代码质量检查清单
│   ├── deep_code_review_report.md # 深度代码审查报告
│   ├── phase_1_5_completion_report.md # Phase 1.5 完成报告
│   ├── phase_1_5_refactoring_report.md # Phase 1.5 重构报告
│   ├── phase_1_5_summary.md       # Phase 1.5 总结
│   ├── phase_1_6_completion_report.md # Phase 1.6 完成报告
│   ├── Phase_1.7_Mock_Payment.md  # Phase 1.7 功能文档
│   └── project_structure_changes.md # 项目结构变动记录
│
├── logs/                          # 日志文件
├── dist/                          # 编译输出
├── node_modules/                  # 依赖包
│
├── docker-compose.yml             # Docker 配置
├── .env                           # 环境变量
├── .env.example                   # 环境变量示例
├── .gitignore                     # Git 忽略规则
├── package.json                   # 项目配置
├── tsconfig.json                  # TypeScript 配置
├── jest.config.js                 # Jest 测试配置
└── README.md                      # 项目说明
```

---

## 📈 统计数据（更新）

### 文件统计
| Phase | 新增文件 | 修改文件 | 新增目录 | 累计文件数 |
|-------|---------|---------|---------|-----------|
| 1.1   | 4       | 0       | 1       | 4         |
| 1.2   | 13      | 0       | 8       | 17        |
| 1.3   | 4       | 2       | 2       | 21        |
| 1.4   | 8       | 5       | 2       | 29        |
| 1.5   | 14      | 2       | 0       | 43        |
| 1.6   | 6       | 2       | 0       | 49        |
| 1.7   | 8       | 3       | 0       | 57        |
| 1.8   | 6       | 5       | 0       | 63        |
| **总计** | **63** | **19** | **13** | **63** |

### 代码行数统计
| 类型 | 行数 |
|------|------|
| TypeScript 源码 | ~6100 行 |
| 测试代码 | ~700 行 |
| Prisma Schema | 211 行 |
| 配置文件 | ~200 行 |
| 文档 | ~5000 行 |
| **总计** | **~12210 行** |

### 依赖包统计
| 类型 | 数量 |
|------|------|
| 生产依赖 | 13 个 |
| 开发依赖 | 10 个 |
| **总计** | **23 个** |

### API 端点统计
| 类型 | 数量 |
|------|------|
| 认证相关 | 12 个 |
| 用户相关 | 3 个 |
| 记录相关 | 5 个 |
| 故事线相关 | 5 个 |
| 社区相关 | 5 个 |
| 支付相关 | 5 个 |
| 健康检查 | 1 个 |
| **总计** | **36 个** |

### 测试统计
| 类型 | 数量 |
|------|------|
| 测试套件 | 8 个 |
| 测试用例 | 59 个 |
| 通过率 | 100% |

---

## 🎯 已实现的功能总览

### Phase 1.4: 认证 API（12 个）
- ✅ 邮箱注册、手机号注册
- ✅ 邮箱登录、手机号登录
- ✅ 发送验证码、重置密码
- ✅ 刷新 Token、获取当前用户、登出
- ✅ 修改密码、更换邮箱、更换/绑定手机号

### Phase 1.5: 数据同步 API（10 个）
- ✅ 上传单条记录、批量上传记录
- ✅ 下载记录（支持增量同步）
- ✅ 更新记录、删除记录
- ✅ 上传单条故事线、批量上传故事线
- ✅ 下载故事线（支持增量同步）
- ✅ 更新故事线、删除故事线

### Phase 1.6: 社区 API（5 个）
- ✅ 发布社区帖子（匿名）
- ✅ 获取社区帖子列表（游标分页）
- ✅ 获取我的社区帖子
- ✅ 删除社区帖子（权限验证）
- ✅ 筛选社区帖子（多条件筛选）

### Phase 1.7: Mock 支付功能（5 个）
- ✅ 创建支付订单（免费、微信、支付宝）
- ✅ 微信支付回调
- ✅ 支付宝回调
- ✅ 查询支付状态
- ✅ 查询会员状态
- ✅ Mock 模式自动模拟支付成功（3 秒）
- ✅ 支付成功自动激活 30 天会员
- ✅ 支持 Mock/真实模式切换

### Phase 1.8: 用户相关 API（3 个）
- ✅ 更新用户信息（displayName、avatarUrl）
- ✅ 获取用户设置（自动创建默认设置）
- ✅ 更新用户设置（主题、动画、通知等）
- ✅ 字段严格验证（只实现文档定义的字段）
- ✅ Upsert 优化（避免多次查询）

---

## 🔄 下一步（Phase 1.9）

### Phase 1.9: Flutter 客户端适配
- 创建 CustomServerAuthRepository
- 创建 CustomServerRemoteDataRepository
- 创建 HttpClientService
- 端到端测试

---

**最后更新**：2026-02-27  
**文档版本**：v1.5  
**维护者**：AI Assistant + 开发者

**更新内容**：
- ✅ 新增 Phase 1.8: 用户相关 API
- 📝 新增 6 个文件（用户相关代码 + 测试）
- 🎯 新增 3 个用户 API 端点
- 📊 更新统计数据（63 个文件，~12210 行代码，59 个测试用例）
- 🔄 文档版本：v1.4 → v1.5

