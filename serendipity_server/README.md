# Serendipity 自建服务器

## 项目简介

Serendipity（错过了么）后端服务器，基于 Node.js + Express + TypeScript 构建。

当前服务端负责：
- 用户认证与令牌管理
- 记录、故事线、社区、收藏、统计等核心业务 API
- 登录用户签到服务端权威源
- Push Token 注册与签到提醒分发
- Prisma + PostgreSQL 数据持久化

## 技术栈

- **运行环境**: Node.js 20 LTS
- **Web 框架**: Express 5.x
- **语言**: TypeScript 5.x
- **数据库**: PostgreSQL 15
- **ORM**: Prisma 7.x
- **认证**: JWT + Refresh Token
- **安全**: helmet、cors、express-rate-limit、express-validator
- **日志**: winston
- **测试**: Jest + Supertest + jest-mock-extended
- **推送**: FCM（Android）+ APNs 预留实现

## 快速开始

> **注意**：以下步骤适用于**本地开发环境**。生产环境（云服务器）直接在系统上安装 PostgreSQL，不使用 Docker。

### 1. 安装 Docker Desktop

下载并安装 Docker Desktop：
- Windows: https://www.docker.com/products/docker-desktop/
- Mac: https://www.docker.com/products/docker-desktop/

### 2. 启动数据库

```bash
# 启动 PostgreSQL
docker-compose up -d

# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 3. 配置环境变量

项目使用 `.env` 文件管理环境变量。
如果本地还没有 `.env`，请手动创建并填写必需配置。

至少需要：
- `DATABASE_URL`
- `JWT_SECRET`（生产环境必须设置强密码）

### 4. 安装依赖

```bash
npm install
```

### 5. 运行数据库迁移

```bash
npm run prisma:migrate
```

### 6. 启动开发服务器

```bash
npm run dev
```

服务器默认监听 `http://localhost:3000`。
健康检查地址：`http://localhost:3000/api/v1/health`

## 常用命令

```bash
# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 启动生产构建
npm run start

# 生成 Prisma Client
npm run prisma:generate

# 执行数据库迁移
npm run prisma:migrate

# 打开 Prisma Studio
npm run prisma:studio

# 写入种子数据
npm run prisma:seed

# 手动执行一次签到提醒扫描
npm run reminder:scan

# 运行测试
npm test
```

## 环境变量说明

项目主要环境变量如下：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `NODE_ENV` | 运行环境 | `development` |
| `PORT` | 服务器端口 | `3000` |
| `DATABASE_URL` | PostgreSQL 连接字符串 | 无 |
| `JWT_SECRET` | JWT 密钥 | 开发环境有默认值，生产环境必填 |
| `JWT_EXPIRES_IN` | Access Token 有效期 | `7d` |
| `REFRESH_TOKEN_EXPIRES_IN` | Refresh Token 有效期 | `30d` |
| `CORS_ORIGIN` | CORS 允许的源 | `*` |
| `CHECKIN_REMINDER_ENABLED` | 是否启用签到提醒扫描器 | `true` |
| `CHECKIN_REMINDER_SCAN_INTERVAL_MS` | 提醒扫描间隔（毫秒） | `60000` |
| `FCM_PROJECT_ID` | FCM Project ID | 空 |
| `FCM_CLIENT_EMAIL` | FCM Service Account 邮箱 | 空 |
| `FCM_PRIVATE_KEY` | FCM Service Account 私钥 | 空 |
| `APNS_KEY_ID` | APNs Key ID | 空 |
| `APNS_TEAM_ID` | Apple Team ID | 空 |
| `APNS_PRIVATE_KEY` | APNs 私钥 | 空 |
| `APNS_BUNDLE_ID` | iOS App Bundle ID | 空 |
| `APNS_PRODUCTION` | 是否使用 APNs 生产环境 | `false` |

**注意：**
- 生产环境必须设置强 `JWT_SECRET`
- 未配置 FCM / APNs 时，推送发送会因缺少凭证而失败
- 当前签到提醒服务端扫描器会在服务启动后自动按间隔运行，也可以通过 `npm run reminder:scan` 手动执行

## Docker 命令

> **注意**：以下命令仅用于**本地开发环境**。生产环境不使用 Docker。

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看 PostgreSQL 日志
docker-compose logs -f postgres

# 进入 PostgreSQL
docker exec -it serendipity_postgres psql -U serendipity -d serendipity_db
```

## 项目结构

```text
serendipity_server/
├── src/
│   ├── config/           # 配置、依赖注入容器、中间件装配
│   ├── controllers/      # 控制器层
│   ├── middlewares/      # 认证、错误处理、上传等中间件
│   ├── repositories/     # 数据访问层
│   ├── routes/           # 路由注册
│   ├── services/         # 业务逻辑层
│   ├── types/            # DTO 与类型定义
│   ├── utils/            # 通用工具
│   ├── validators/       # 请求校验规则
│   ├── app.ts            # Express 应用创建
│   └── server.ts         # 服务器启动与提醒扫描调度
├── prisma/
│   ├── migrations/       # 数据库迁移
│   ├── schema.prisma     # 数据模型
│   └── seed.ts           # 种子数据脚本
├── scripts/              # 手动维护/测试脚本
├── tests/                # 单元测试与测试辅助文件
├── docs/                 # 服务端专项文档
├── uploads/              # 上传文件目录
├── logs/                 # 服务端日志
├── docker-compose.yml    # Docker 配置
├── jest.config.js        # Jest 配置
├── package.json          # 项目配置与脚本
├── prisma.config.ts      # Prisma 配置
└── tsconfig.json         # TypeScript 配置
```

## 当前主要 API 模块

当前已注册的主要路由模块包括：
- `auth`
- `records`
- `storylines`
- `community`
- `users`
- `check-ins`
- `achievement-unlocks`
- `favorites`
- `statistics`
- `push-tokens`

## 签到提醒说明

当前服务端已实现登录用户签到提醒的基础能力：
- Push Token 注册与注销
- 基于用户时区的提醒候选扫描
- 服务端判断“今天是否已签到”
- 发送后按设备与日期去重记录分发状态
- FCM 正式发送链路
- APNs 发送实现预留

## API 文档

详见 `../docs/Custom_Server_API_Design.md`

## 开发进度

详见 `../docs/开发清单_00_总览.md`
