# Serendipity 自建服务器迁移指南

**项目名称**：Serendipity（错过了么）  
**迁移类型**：从 Supabase 迁移到自建服务器  
**开始时间**：2026-02-25  
**预计完成**：待定  
**当前状态**：⏳ 准备中

---

## 📋 迁移概述

### 迁移原因

由于项目需要集成**微信支付**和**支付宝支付**，必须使用自建服务器来处理支付回调验证：

```
支付流程：
1. 客户端发起支付 → 自建服务器
2. 服务器调用支付平台 API → 微信/支付宝
3. 支付平台回调 → 自建服务器（验证签名）✨ 关键步骤
4. 服务器更新会员状态 → 通知客户端

❌ Supabase 无法处理支付回调验证
✅ 自建服务器可以完全控制支付流程
```

### 迁移方案

**方案 A：完全自建（最终目标）**

```
┌─────────────────────────────────────┐
│         自建服务器                   │
│  ┌──────────────────────────────┐  │
│  │  Node.js + Express + TS      │  │
│  │  - 认证 API                  │  │
│  │  - 数据同步 API              │  │
│  │  - 支付 API                  │  │
│  └──────────────────────────────┘  │
│              ↓                      │
│  ┌──────────────────────────────┐  │
│  │  PostgreSQL 数据库           │  │
│  │  + Redis 缓存                │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 技术栈选型

经过全局分析，选择 **Node.js + Express + TypeScript**：

| 维度 | 评分 | 说明 |
|------|------|------|
| 支付集成 | ⭐⭐⭐⭐⭐ | 微信/支付宝 SDK 最成熟 |
| 开发效率 | ⭐⭐⭐⭐⭐ | 生态丰富，开发速度快 |
| 技术契合 | ⭐⭐⭐⭐⭐ | 与 Flutter/Dart 技术栈相似 |
| 性能 | ⭐⭐⭐⭐ | 可支撑 10 万+ 用户 |
| 部署运维 | ⭐⭐⭐⭐⭐ | Docker + PM2，简单易用 |
| 成本 | ⭐⭐⭐⭐⭐ | ¥300/月可支撑初期用户 |

**完整技术栈：**
```
应用层：
- Node.js 20 LTS
- Express 4.x (Web 框架)
- TypeScript 5.x (类型安全)
- Prisma (ORM，类型安全的数据库操作)
- JWT (认证)
- wechatpay-node-v3 (微信支付)
- alipay-sdk (支付宝)
- node-schedule (定时任务)
- winston (日志)
- ioredis (Redis 客户端)

数据层：
- PostgreSQL 15 (主数据库)
- Redis 7 (缓存 + Session)
```

---

## 🎯 迁移阶段

### 阶段 1：本地开发（无需服务器）

**目标**：完成所有代码开发和测试，使用本地环境

#### Phase 1.1: 环境搭建
- [ ] 安装 Docker Desktop
- [ ] 配置 docker-compose.yml
- [ ] 启动本地 PostgreSQL + Redis
- [ ] 验证环境正常运行

#### Phase 1.2: 后端框架搭建
- [ ] 初始化 Node.js + TypeScript 项目
- [ ] 配置 Express 框架
- [ ] 配置 Prisma ORM
- [ ] 实现 JWT 认证中间件
- [ ] 配置日志系统（winston）
- [ ] 配置错误处理中间件
- [ ] 编写健康检查接口

#### Phase 1.3: 数据库设计
- [ ] 设计数据库表结构（9 个表）
- [ ] 编写 Prisma Schema
- [ ] 创建数据库迁移脚本
- [ ] 添加索引优化
- [ ] 填充测试数据

#### Phase 1.4: 认证 API（12 个接口）
- [ ] POST /api/v1/auth/register/email（邮箱注册）
- [ ] POST /api/v1/auth/register/phone（手机号注册）
- [ ] POST /api/v1/auth/login/email（邮箱登录）
- [ ] POST /api/v1/auth/login/phone（手机号登录）
- [ ] POST /api/v1/auth/send-verification-code（发送验证码）
- [ ] POST /api/v1/auth/reset-password（重置密码）
- [ ] POST /api/v1/auth/refresh-token（刷新 Token）
- [ ] GET /api/v1/auth/me（获取当前用户）
- [ ] POST /api/v1/auth/logout（登出）
- [ ] PUT /api/v1/auth/password（修改密码）
- [ ] PUT /api/v1/auth/email（更换邮箱）
- [ ] PUT /api/v1/auth/phone（更换/绑定手机号）
- [ ] 单元测试

#### Phase 1.5: 数据同步 API（10 个接口）
- [ ] POST /api/v1/records（上传记录）
- [ ] POST /api/v1/records/batch（批量上传）
- [ ] GET /api/v1/records（下载记录，支持增量同步）
- [ ] PUT /api/v1/records/:id（更新记录）
- [ ] DELETE /api/v1/records/:id（删除记录）
- [ ] POST /api/v1/storylines（上传故事线）
- [ ] POST /api/v1/storylines/batch（批量上传）
- [ ] GET /api/v1/storylines（下载故事线，支持增量同步）
- [ ] PUT /api/v1/storylines/:id（更新故事线）
- [ ] DELETE /api/v1/storylines/:id（删除故事线）
- [ ] 单元测试

#### Phase 1.6: 社区 API（5 个接口）
- [ ] POST /api/v1/community/posts（发布社区帖子）
- [ ] GET /api/v1/community/posts（获取社区帖子列表）
- [ ] GET /api/v1/community/my-posts（获取我的社区帖子）
- [ ] DELETE /api/v1/community/posts/:id（删除社区帖子）
- [ ] GET /api/v1/community/posts/filter（筛选社区帖子）
- [ ] 单元测试

#### Phase 1.7: 支付集成（4 个接口）
- [ ] 申请微信支付沙箱账号
- [ ] 申请支付宝沙箱账号
- [ ] 安装 ngrok（内网穿透）
- [ ] POST /api/v1/payment/create（创建支付订单）
- [ ] POST /api/v1/payment/wechat/callback（微信支付回调）
- [ ] POST /api/v1/payment/alipay/callback（支付宝回调）
- [ ] GET /api/v1/payment/status/:orderId（查询支付状态）
- [ ] GET /api/v1/membership/status（查询会员状态）
- [ ] 支付流程完整测试
- [ ] 单元测试

#### Phase 1.8: 用户相关 API（3 个接口）
- [ ] PUT /api/v1/users/me（更新用户信息）
- [ ] GET /api/v1/users/settings（获取用户设置）
- [ ] PUT /api/v1/users/settings（更新用户设置）
- [ ] 单元测试

#### Phase 1.9: Flutter 客户端适配
- [ ] 创建 CustomServerAuthRepository
- [ ] 创建 CustomServerRemoteDataRepository
- [ ] 创建 HttpClientService
- [ ] 创建 ServerConfig
- [ ] 修改 Provider 切换到自建服务器
- [ ] 端到端测试
- [ ] 代码优化

**阶段 1 完成标准：**
- ✅ 所有 35 个 API 接口开发完成
- ✅ 单元测试覆盖率 > 80%
- ✅ Flutter 客户端可以连接本地后端
- ✅ 支付流程在沙箱环境测试通过

---

### 阶段 2：服务器部署（需要服务器）

**目标**：将代码部署到云服务器，配置生产环境

#### Phase 2.1: 服务器购买与配置
- [ ] 购买阿里云 ECS（2核4G）
- [ ] 购买阿里云 RDS PostgreSQL（1核2G）
- [ ] 购买阿里云 Redis（256MB）
- [ ] 购买域名（未拥有时需购买）
- [ ] 配置域名解析
- [ ] 申请 SSL 证书
- [ ] 配置防火墙规则
- [ ] 安装 Docker
- [ ] 安装 Nginx

#### Phase 2.2: 应用部署
- [ ] 上传代码到服务器
- [ ] 配置环境变量
- [ ] Docker 打包后端应用
- [ ] 配置 Nginx 反向代理
- [ ] 配置 SSL 证书
- [ ] 运行数据库迁移
- [ ] 启动应用
- [ ] 配置 PM2 进程管理
- [ ] 配置日志收集

#### Phase 2.3: 真实支付测试
- [ ] 配置微信支付正式环境
- [ ] 配置支付宝正式环境
- [ ] 真实支付测试（小额）
- [ ] 验证支付回调
- [ ] 验证会员状态更新
- [ ] 配置监控和告警
- [ ] 性能测试
- [ ] 安全检查

**阶段 2 完成标准：**
- ✅ 应用成功部署到云服务器
- ✅ 域名和 SSL 配置正确
- ✅ 真实支付流程测试通过
- ✅ 监控和日志正常运行

---

## 📊 进度追踪

### 总体进度

| 阶段 | 状态 | 进度 |
|------|------|------|
| 阶段 1：本地开发 | ⏳ 准备中 | 0% |
| 阶段 2：服务器部署 | ⏳ 未开始 | 0% |

### 详细进度

#### 阶段 1：本地开发

| 任务 | 接口数量 | 状态 | 完成时间 | 备注 |
|------|---------|------|---------|------|
| Phase 1.1: 环境搭建 | - | ⏳ 准备中 | - | - |
| Phase 1.2: 后端框架搭建 | - | ⏳ 未开始 | - | - |
| Phase 1.3: 数据库设计 | 9 个表 | ⏳ 未开始 | - | - |
| Phase 1.4: 认证 API | 12 个 | ⏳ 未开始 | - | - |
| Phase 1.5: 数据同步 API | 10 个 | ⏳ 未开始 | - | - |
| Phase 1.6: 社区 API | 5 个 | ⏳ 未开始 | - | - |
| Phase 1.7: 支付集成 | 4 个 | ⏳ 未开始 | - | - |
| Phase 1.8: 用户相关 API | 3 个 | ⏳ 未开始 | - | - |
| Phase 1.9: Flutter 客户端适配 | - | ⏳ 未开始 | - | - |

**总计**：35 个 API 接口 + 9 个数据库表

#### 阶段 2：服务器部署

| 任务 | 状态 | 完成时间 | 备注 |
|------|------|---------|------|
| Phase 2.1: 服务器购买与配置 | ⏳ 未开始 | - | - |
| Phase 2.2: 应用部署 | ⏳ 未开始 | - | - |
| Phase 2.3: 真实支付测试 | ⏳ 未开始 | - | - |

---

## 📝 开发日志

### 2026-02-25

**任务**：创建迁移指南文档

**完成内容**：
- ✅ 创建 `Custom_Server_Migration_Guide.md`
- ✅ 创建 `Custom_Server_API_Design.md`
- ✅ 规划完整的迁移路线图
- ✅ 确定技术栈：Node.js + Express + TypeScript

**下一步**：
- Phase 1.1: 环境搭建
- 创建 docker-compose.yml
- 初始化后端项目

---

## 🔗 相关文档

- [API 接口设计文档](./Custom_Server_API_Design.md)
- [Supabase 迁移指南](./supabase_migration_guide.md)（历史参考）
- [项目规格文档](./Serendipity_Spec.md)
- [开发清单总览](./开发清单_00_总览.md)

---

## 💡 注意事项

### 本地开发阶段

1. **手机连接本地后端**
   - 手机和电脑连接同一 WiFi
   - 使用电脑的局域网 IP（如 192.168.1.100）
   - 后端配置允许跨域

2. **支付回调测试**
   - 使用 ngrok 内网穿透
   - 配置沙箱环境回调地址
   - 验证签名和解密逻辑

3. **数据库迁移**
   - 保持与 Supabase 相同的表结构
   - 便于后续数据迁移

### 服务器部署阶段

1. **安全配置**
   - 配置防火墙，只开放必要端口
   - 使用环境变量存储敏感信息
   - 配置 SSL 证书（HTTPS）
   - 定期更新依赖包

2. **性能优化**
   - 使用 Redis 缓存热点数据
   - 配置数据库连接池
   - 使用 PM2 Cluster 模式
   - 配置 Nginx 压缩和缓存

3. **监控告警**
   - 配置日志收集
   - 配置性能监控
   - 配置错误告警
   - 定期备份数据库

---

**最后更新**：2026-02-25（修正版）  
**文档版本**：v2.0  
**维护者**：AI Assistant + 开发者

**修正内容**：
- ✅ 删除不准确的时间估算（Day 1-18）
- ✅ 补充缺失的 API（认证 3 个、社区 5 个、用户 1 个）
- ✅ 调整阶段划分（Phase 1.6 社区 API、Phase 1.7 支付、Phase 1.8 用户、Phase 1.9 Flutter）
- ✅ 更新接口总数（从 26 个增加到 35 个）
- ✅ 补充数据库表设计（9 个表）
- ✅ 更新进度追踪表格

