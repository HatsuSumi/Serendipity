# Serendipity（错过了么）

> 记录生活中那些擦肩而过的瞬间

## 📋 项目简介

Serendipity 是一个情感记录类移动应用，专注于记录日常生活中错过的人。

无论是通勤路上的地铁、公交，还是周末的咖啡馆、公园，那些让你心动却未曾开口的瞬间，都值得被记住。

- **核心理念**：有些错过，只能被记住
- **目标用户**：18-35岁，经常通勤的都市青年
- **技术栈**：Flutter + Dart + 自建服务器（Node.js + PostgreSQL）
- **平台**：Android 5.0+ / iOS 12.0+

## 📁 项目结构

```
Serendipity/
├── README.md                    # 项目说明（本文件）
├── docs/                        # 项目文档
│   ├── Serendipity_Spec.md     # 完整规格文档
│   ├── Development_Roadmap.md  # 开发路线图
│   └── About_Page_Content.md   # 关于页面内容
└── serendipity_app/            # Flutter 项目
    ├── lib/                    # 源代码
    ├── android/                # Android 配置
    ├── ios/                    # iOS 配置
    └── pubspec.yaml            # 依赖配置
```

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
- Flutter 3.x
- Dart 3.x
- Riverpod 2.x（状态管理）
- go_router（路由）
- Hive（本地存储）

### 后端
- Node.js 20 LTS（运行环境）
- Express 4.x（Web 框架）
- TypeScript 5.x（类型安全）
- Prisma（ORM）
- PostgreSQL 15（数据库）
- Redis 7（缓存）
- JWT（认证）

### 第三方服务
- 高德地图 API（地图服务、逆地理编码）

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
- 免费版：核心功能完整，最多3条故事线，单设备
- 会员版：多设备同步、无限故事线、词云图、高级主题等

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

## 👨‍💻 开发者

一个人的为爱发电项目

---

**最后更新**：2026-02-21  
**版本**：v0.2.0（开发中）

