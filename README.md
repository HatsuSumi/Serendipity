# Serendipity（错过了么）

> 记录生活中那些擦肩而过的瞬间

## 📋 项目简介

Serendipity 是一个情感记录类移动应用，专注于记录日常生活中错过的人。

无论是通勤路上的地铁、公交，还是周末的咖啡馆、公园，那些让你心动却未曾开口的瞬间，都值得被记住。

- **核心理念**：有些错过，只能被记住
- **目标用户**：18-35岁，经常通勤的都市青年
- **技术栈**：Flutter 3.x + Dart 3.x + Riverpod 2.x + Hive 2.x + Node.js 20 LTS + Express 5.x + TypeScript 5.x + PostgreSQL 15 + Prisma ORM + JWT + 高德地图 API（逆地理编码）
- **平台**：Android 5.0+ / iOS 12.0+

## 📁 项目结构

```text
Serendipity/
├── README.md                    # 项目总说明（本文件）
├── docs/                        # 项目文档、重构计划与评审记录
│   ├── Serendipity_Spec.md      # 完整规格文档
│   ├── checkin_reminder_server_refactor_plan.md  # 签到提醒服务端化重构计划
│   ├── 开发清单_00_总览.md       # 当前开发清单总览
│   └── code_review_reports/     # 代码评审报告
├── serendipity_app/             # Flutter 客户端
│   ├── lib/                     # 客户端源码
│   ├── assets/                  # 静态资源
│   ├── test/                    # 客户端测试
│   ├── android/                 # Android 工程
│   ├── ios/                     # iOS 工程
│   └── pubspec.yaml             # Flutter 依赖配置
├── serendipity_server/          # Node.js / Express / TypeScript 服务端
│   ├── src/                     # 服务端源码
│   ├── prisma/                  # 数据库 schema、seed 与迁移
│   ├── tests/                   # 服务端测试
│   ├── docs/                    # 服务端专项文档
│   └── package.json             # 服务端依赖与脚本
├── logs/                        # 根目录日志
├── project_stats.py             # 项目规模统计脚本
└── count_lines.ps1              # 行数统计脚本
```

## 📊 项目规模

### 文件统计

- **总文件数**：721 个
  - Dart文件：328 个
  - TypeScript文件：121 个
  - Markdown文档：117 个
  - 其他文件：70 个
  - JavaScript文件：20 个
  - JSON文件：12 个
  - SQL脚本：9 个
  - XML文件：8 个
  - C文件：7 个
  - C++文件：6 个
  - Swift文件：6 个
  - Kotlin文件：4 个
  - INI/配置文件：3 个
  - YAML文件：3 个
  - HTML文件：1 个
  - Java文件：1 个
  - Objective-C文件：1 个
  - PowerShell脚本：1 个
  - Python脚本：1 个
  - TOML文件：1 个
  - 批处理脚本：1 个

### 代码规模

- **代码总行数**：91,871 行（不含空行、注释）
  - Dart：47,013 行（51.2%）
  - JSON：27,707 行（30.1%）
  - TypeScript：12,325 行（13.4%）
  - JavaScript：3,333 行（3.6%）
  - C++：442 行（0.5%）
  - SQL：284 行（0.3%）
  - C：105 行（0.1%）
  - XML：103 行（0.1%）
  - Kotlin：90 行（0.1%）
  - Swift：73 行（0.1%）
  - Java：71 行（0.1%）
  - ObjC：71 行（0.1%）
  - PowerShell：70 行（0.1%）
  - YAML：70 行（0.1%）
  - Batch：64 行（0.1%）
  - HTML：19 行（0.0%）
  - Python：18 行（0.0%）
  - INI：12 行（0.0%）
  - TOML：1 行（0.0%）

- **字符总数**：3,069,644 字符（不含注释）
  - Dart：1,543,273 字符（50.3%）
  - JSON：670,002 字符（21.8%）
  - TypeScript：406,613 字符（13.2%）
  - JavaScript：390,766 字符（12.7%）
  - C++：15,306 字符（0.5%）
  - SQL：16,457 字符（0.5%）
  - C：3,231 字符（0.1%）
  - XML：4,900 字符（0.2%）
  - Kotlin：2,534 字符（0.1%）
  - Swift：2,559 字符（0.1%）
  - Java：3,564 字符（0.1%）
  - ObjC：2,999 字符（0.1%）
  - PowerShell：1,922 字符（0.1%）
  - YAML：1,495 字符（0.1%）
  - Batch：2,107 字符（0.1%）
  - HTML：657 字符（0.0%）
  - Python：750 字符（0.0%）
  - INI：486 字符（0.0%）
  - TOML：23 字符（0.0%）

> 💡 **数据来源**：以上数据基于项目内的 `project_stats.py` 统计生成
>
> 📊 **统计工具 GitHub 仓库链接**：[Omni-Project-Stats](https://github.com/HatsuSumi/Omni-Project-Stats) —— 90%项目通用，涵盖多个领域

## 🎯 核心功能

### 七种状态
- 🌫️ **错过** - 第一次看到，但没说话
- 🙈 **回避** - 看到了，但刻意避开
- 🌟 **再遇** - 又看到了，但还是没说话
- 💫 **邂逅** - 终于说话了
- 💝 **重逢** - 分开后再次相遇（需先别离）
- 🥀 **别离** - 主动结束了
- 🍂 **失联** - 被动消失，再也没见过

### 主要功能
- ✅ 记录错过的瞬间
- ✅ 故事线（关联同一个人的多次记录）
- ✅ 时间轴视图
- ✅ 地图视图
- ✅ 社区（树洞）
- ✅ 成就系统
- ✅ 会员系统（自愿付费 ¥0-648/月）

## 📚 文档说明

### [Serendipity_Spec.md](docs/Serendipity_Spec.md)
完整的项目规格文档，包含：
- 项目概述
- 核心功能详细设计
- 数据模型
- UI/UX 设计原则
- 技术架构

### [Development_Roadmap.md](docs/Development_Roadmap.md)
开发路线图，包含：
- 技术栈确认
- 开发阶段划分（Phase 1-6）
- 时间估算（8-10周）
- 风险与应对

### [About_Page_Content.md](docs/About_Page_Content.md)
关于页面的完整文案内容

## 🔧 技术栈

### 前端
- Flutter 3.x + Dart 3.x（SDK `^3.10.8`）
- Riverpod 2.x（状态管理，`flutter_riverpod: ^2.6.1`）
- Hive 2.x（本地存储，TypeAdapter 模式，含代码生成）
- flutter_local_notifications（本地通知）
- fl_chart（图表）
- confetti（粒子特效）
- photo_manager（导出截图、相册保存）
- 架构模式：Feature-first + Repository Pattern + Provider Pattern

### 后端
- Node.js 20 LTS（运行环境）
- Express 5.x + TypeScript 5.x
- PostgreSQL 15 + Prisma ORM（v7.x）
- JWT（Access Token + Refresh Token，双 Token 机制）
- helmet、cors、express-rate-limit（安全中间件）
- winston（日志）
- Jest + Supertest + jest-mock-extended（测试）
- 自实现 DI Container（依赖注入）

### 第三方服务
- 高德地图 API（逆地理编码）

## 🛠️ 开发环境配置

### 1. 安装 Flutter

请参考 Flutter 官方文档：https://flutter.dev/docs/get-started/install

### 2. 配置高德地图 API

GPS 定位功能需要高德地图 API Key：

1. 前往高德开放平台注册：https://lbs.amap.com/
2. 创建应用，获取"Web 服务"类型的 API Key
3. 复制 `lib/core/config/amap_config.dart.template` 为 `amap_config.dart`
4. 将 API Key 填入配置文件

详细步骤请查看：[高德地图集成指南](docs/Amap_Integration_Guide.md)

### 3. 安装依赖

```bash
cd serendipity_app
flutter pub get
```

### 4. 运行项目

```bash
# Android
flutter run

# iOS
flutter run

# Web
flutter run -d chrome
```

## 💎 商业模式

**自愿付费（Pay What You Want）**
- 用户自定义金额：¥0-648/月
- 基础版：记录、故事线、签到与账号数据都可同步，最多3条故事线
- 会员版：无限故事线、词云图、高级主题等

## 📝 开发规范

### 代码规范
- 遵循 Dart 官方代码风格
- 使用 `flutter analyze` 检查代码
- 使用 `dart format` 格式化代码

### Git 规范
- 使用语义化提交信息
  - `feat: 添加记录创建功能`
  - `fix: 修复时间轴加载问题`
  - `docs: 更新开发文档`

## 📄 许可证

待定

---

**最后更新**：2026-02-21  
**版本**：v0.2.0（开发中）

