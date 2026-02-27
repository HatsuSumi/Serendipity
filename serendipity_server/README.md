# Serendipity 自建服务器

## 项目简介

Serendipity（错过了么）后端服务器，基于 Node.js + Express + TypeScript 构建。

## 技术栈

- **运行环境**: Node.js 20 LTS
- **Web 框架**: Express 4.x
- **语言**: TypeScript 5.x
- **数据库**: PostgreSQL 15
- **缓存**: Redis 7
- **ORM**: Prisma
- **认证**: JWT

## 快速开始

### 1. 安装 Docker Desktop

下载并安装 Docker Desktop：
- Windows: https://www.docker.com/products/docker-desktop/
- Mac: https://www.docker.com/products/docker-desktop/

### 2. 启动数据库

```bash
# 启动 PostgreSQL + Redis
docker-compose up -d

# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 3. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，修改配置（如果需要）
# 默认配置已经可以直接使用
```

### 4. 安装依赖

```bash
npm install
```

### 5. 运行数据库迁移

```bash
npx prisma migrate dev
```

### 6. 启动开发服务器

```bash
npm run dev
```

服务器将在 http://localhost:3000 启动。

## 环境变量说明

项目使用 `.env` 文件管理环境变量。主要配置项：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| NODE_ENV | 运行环境 | development |
| PORT | 服务器端口 | 3000 |
| DATABASE_URL | PostgreSQL 连接字符串 | postgresql://serendipity:serendipity_dev_password@localhost:5432/serendipity_db |
| REDIS_HOST | Redis 主机 | localhost |
| REDIS_PORT | Redis 端口 | 6379 |
| JWT_SECRET | JWT 密钥 | （需要修改） |
| JWT_EXPIRES_IN | Access Token 有效期 | 7d |
| JWT_REFRESH_TOKEN_EXPIRES_IN | Refresh Token 有效期 | 30d |
| CORS_ORIGIN | CORS 允许的源 | http://localhost:3000 |

**注意**：生产环境必须修改 `JWT_SECRET` 为强密码！

## Docker 命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f postgres
docker-compose logs -f redis

# 进入 PostgreSQL
docker exec -it serendipity_postgres psql -U serendipity -d serendipity_db

# 进入 Redis
docker exec -it serendipity_redis redis-cli
```

## 项目结构

```
serendipity_server/
├── src/
│   ├── controllers/     # 控制器
│   ├── middlewares/     # 中间件
│   ├── routes/          # 路由
│   ├── services/        # 业务逻辑
│   ├── utils/           # 工具函数
│   └── app.ts           # 应用入口
├── prisma/
│   └── schema.prisma    # 数据库模型
├── docker-compose.yml   # Docker 配置
├── .env                 # 环境变量
└── package.json         # 项目配置
```

## API 文档

详见 [Custom_Server_API_Design.md](../docs/Custom_Server_API_Design.md)

## 开发进度

详见 [Custom_Server_Migration_Guide.md](../docs/Custom_Server_Migration_Guide.md)

