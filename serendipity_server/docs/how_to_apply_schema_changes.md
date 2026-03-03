# 如何应用数据库 Schema 变更

## 开发阶段（数据库无数据或可以重置）

### 方法 1：重置数据库（推荐）

如果数据库中没有重要数据，直接重置是最简单的方式：

```bash
cd d:\Serendipity\serendipity_server

# 1. 确保数据库服务正在运行
# 如果使用 Docker:
docker-compose up -d

# 2. 重置数据库（会删除所有数据并重新创建表）
npx prisma migrate reset

# 3. 生成 Prisma Client
npm run prisma:generate
```

### 方法 2：创建新迁移

如果想保留迁移历史：

```bash
cd d:\Serendipity\serendipity_server

# 1. 确保数据库服务正在运行

# 2. 创建并应用迁移
npm run prisma:migrate
# 输入迁移名称，例如: update_community_posts_region

# 3. Prisma Client 会自动生成
```

## 生产阶段（数据库有重要数据）

### 步骤 1：备份数据库

```bash
# PostgreSQL 备份
pg_dump -h localhost -U your_username -d serendipity_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 步骤 2：创建迁移

```bash
cd d:\Serendipity\serendipity_server

# 创建迁移（不自动应用）
npx prisma migrate dev --create-only

# 输入迁移名称
```

### 步骤 3：检查生成的 SQL

检查 `prisma/migrations/[timestamp]_[name]/migration.sql` 文件，确保 SQL 正确。

### 步骤 4：应用迁移

```bash
# 应用迁移
npx prisma migrate deploy
```

### 步骤 5：验证

```bash
# 打开 Prisma Studio 检查数据
npm run prisma:studio
```

## 当前修改说明

### 修改内容
- 删除字段: `city_name`
- 新增字段: `province`, `city`, `area`
- 更新索引

### 数据兼容性
- 如果有旧数据，Prisma 会自动将 `city_name` 的值迁移到 `city`
- `province` 和 `area` 在旧数据中为 `NULL`

## 常见问题

### Q: 数据库连接超时
**A**: 确保 PostgreSQL 服务正在运行：
```bash
# 检查 Docker 容器
docker ps

# 或启动 Docker Compose
docker-compose up -d
```

### Q: 迁移冲突
**A**: 如果开发阶段出现迁移冲突，可以重置：
```bash
npx prisma migrate reset
```

### Q: 如何回滚迁移
**A**: Prisma 不支持自动回滚，需要：
1. 恢复数据库备份
2. 或手动编写回滚 SQL

## 相关文档

- Prisma 迁移文档: https://www.prisma.io/docs/concepts/components/prisma-migrate
- 项目迁移指南: `docs/migration_guide_region_filter.md`
- 后端修改总结: `docs/community_region_filter_backend_changes.md`

