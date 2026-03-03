# 社区帖子地区筛选功能数据库迁移指南

## 概述

本次迁移将社区帖子表的地区字段从单一的 `city_name` 改为 `province`、`city`、`area` 三个字段，以支持省市区三级筛选。

## 修改内容

### 数据库层面
- **删除字段**: `city_name`
- **新增字段**: 
  - `province` VARCHAR(50) - 省份（如"广东省"）
  - `city` VARCHAR(100) - 城市（如"深圳市"）
  - `area` VARCHAR(100) - 区县（如"南山区"）
- **索引变更**:
  - 删除: `community_posts_city_name_idx`
  - 新增: `community_posts_province_idx`
  - 新增: `community_posts_city_idx`
  - 新增: `community_posts_area_idx`

### API 层面
- **请求参数变更**:
  - 创建帖子: `cityName` → `province`, `city`, `area`
  - 筛选帖子: `cityName` → `province`, `city`, `area`
- **响应数据变更**:
  - 帖子详情: `cityName` → `province`, `city`, `area`

## 迁移步骤

### 1. 备份数据库（重要！）

```bash
# 使用 pg_dump 备份数据库
pg_dump -h localhost -U your_username -d serendipity_db > backup_before_migration.sql
```

### 2. 运行数据库迁移

```bash
cd d:\Serendipity\serendipity_server

# 方式 1: 使用 Prisma Migrate（推荐用于开发环境）
npm run prisma:migrate:dev

# 方式 2: 手动执行 SQL（推荐用于生产环境）
# 连接到数据库后执行：
# d:\Serendipity\serendipity_server\prisma\migrations\20260303000000_update_community_posts_region\migration.sql
```

### 3. 验证迁移结果

```bash
# 检查表结构
npm run prisma:studio

# 或者直接查询数据库
psql -h localhost -U your_username -d serendipity_db -c "\d community_posts"
```

### 4. 重启服务

```bash
# 重新编译 TypeScript
npm run build

# 重启服务
npm run start
```

## 数据迁移说明

### 旧数据处理
- 迁移脚本会自动将 `city_name` 的值复制到 `city` 字段
- `province` 和 `area` 字段在旧数据中为 `NULL`
- 旧数据仍然可以正常显示和筛选（按城市筛选）

### 新数据
- 新创建的帖子将包含完整的 `province`、`city`、`area` 信息
- 支持省市区三级精确筛选

## API 兼容性

### 向后兼容性
- ❌ **不兼容**: 旧客户端发送 `cityName` 参数将被忽略
- ✅ **需要更新**: 客户端必须更新到新版本才能使用地区筛选功能

### 客户端更新要求
- Flutter 客户端已同步更新（见 `docs/community_region_filter_fix.md`）
- 客户端版本要求: >= v1.x.x（待定）

## 回滚方案

如果迁移出现问题，可以执行以下回滚步骤：

### 1. 恢复数据库备份

```bash
# 停止服务
npm run stop

# 恢复备份
psql -h localhost -U your_username -d serendipity_db < backup_before_migration.sql
```

### 2. 回滚代码

```bash
git revert <commit_hash>
npm run build
npm run start
```

## 测试清单

迁移完成后，请测试以下功能：

- [ ] 创建新社区帖子（包含省市区信息）
- [ ] 查看社区帖子列表
- [ ] 按省份筛选帖子
- [ ] 按城市筛选帖子
- [ ] 按区县筛选帖子
- [ ] 组合筛选（省+市+区）
- [ ] 查看旧数据（只有城市信息的帖子）
- [ ] 删除帖子

## 性能影响

### 索引优化
- 新增三个索引可能会略微增加写入时间
- 查询性能应该保持不变或略有提升（更精确的索引）

### 存储空间
- 每条记录增加约 50-200 字节（取决于地区名称长度）
- 索引增加约 10-20% 的存储空间

## 注意事项

1. **生产环境迁移建议**:
   - 在低峰期执行迁移
   - 提前通知用户可能的短暂服务中断
   - 准备好回滚方案

2. **数据一致性**:
   - 旧数据的 `province` 和 `area` 为 NULL 是正常的
   - 不影响功能使用

3. **客户端更新**:
   - 必须同步更新 Flutter 客户端
   - 建议强制更新客户端版本

## 相关文档

- 前端修复文档: `docs/community_region_filter_fix.md`
- API 设计文档: `docs/Custom_Server_API_Design.md`
- Prisma Schema: `prisma/schema.prisma`

## 联系方式

如有问题，请联系开发团队。

