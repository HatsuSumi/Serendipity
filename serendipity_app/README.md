# Serendipity App

Serendipity 的 Flutter 客户端。

当前客户端负责：
- 记录、故事线、社区、成就、统计等核心交互
- 本地存储与登录后云端同步
- 登录用户服务端权威签到状态展示
- 未登录用户本地签到与本地提醒
- Firebase Push Token 注册与远程推送接收

## 技术栈

- **框架**：Flutter 3.x
- **语言**：Dart 3.x（SDK `^3.10.8`）
- **状态管理**：Riverpod 2.x
- **本地存储**：Hive + SharedPreferences
- **网络与同步**：HTTP、自建服务端同步、Connectivity Plus
- **定位与地图相关**：Geolocator、高德地图逆地理编码
- **通知与推送**：flutter_local_notifications、Firebase Messaging、timezone、flutter_timezone
- **数据可视化与体验增强**：fl_chart、confetti
- **媒体与导出**：image_picker、image_cropper、screenshot、image_gallery_saver、path_provider
- **其他能力**：url_launcher、package_info_plus
- **架构模式**：Feature-first + Repository Pattern + Provider Pattern

## 项目结构

```text
serendipity_app/
├── lib/
│   ├── core/              # 基础设施与通用能力
│   │   ├── config/        # 环境与服务端配置
│   │   ├── constants/     # 常量定义
│   │   ├── providers/     # 全局状态与业务 Provider
│   │   ├── repositories/  # 数据访问层
│   │   ├── services/      # 同步、通知、定位、存储等服务
│   │   ├── theme/         # 主题系统
│   │   ├── utils/         # 工具函数
│   │   └── widgets/       # 通用组件
│   ├── dev_tools/         # 开发辅助脚本
│   ├── features/          # 按业务功能划分的页面与组件
│   │   ├── about/         # 关于页与设计说明
│   │   ├── achievement/   # 成就系统
│   │   ├── auth/          # 登录注册与认证
│   │   ├── check_in/      # 签到
│   │   ├── community/     # 社区/树洞
│   │   ├── favorites/     # 收藏
│   │   ├── home/          # 主导航与首页承载
│   │   ├── membership/    # 会员系统
│   │   ├── record/        # 记录创建与详情
│   │   ├── settings/      # 设置与个人页
│   │   ├── statistics/    # 统计面板
│   │   ├── story_line/    # 故事线
│   │   └── timeline/      # 时间轴
│   ├── models/            # 数据模型与序列化代码
│   └── main.dart          # 应用入口
├── assets/                # 静态资源与本地数据文件
├── test/                  # 客户端测试
├── android/               # Android 工程
├── ios/                   # iOS 工程
├── web/                   # Web 运行配置
├── windows/               # Windows 工程
├── linux/                 # Linux 工程
├── macos/                 # macOS 工程
├── pubspec.yaml           # Flutter 依赖配置
└── analysis_options.yaml  # Dart/Flutter 分析配置
```

## 📊 项目规模

### 文件统计

- **总文件数**：449 个
  - Dart文件：338 个
  - 其他文件：51 个
  - JSON文件：8 个
  - XML文件：8 个
  - C文件：7 个
  - C++文件：6 个
  - Markdown文档：6 个
  - Swift文件：6 个
  - JavaScript文件：5 个
  - Kotlin文件：4 个
  - INI/配置文件：3 个
  - YAML文件：2 个
  - HTML文件：1 个
  - Java文件：1 个
  - Objective-C文件：1 个
  - Python脚本：1 个
  - 批处理脚本：1 个

### 代码规模

- **代码总行数**：68,553 行（不含空行、注释）
  - Dart：47,323 行（69.0%）
  - JSON：19,457 行（28.4%）
  - JavaScript：656 行（1.0%）
  - C++：442 行（0.6%）
  - C：105 行（0.2%）
  - XML：103 行（0.2%）
  - Kotlin：90 行（0.1%）
  - Swift：73 行（0.1%）
  - Java：71 行（0.1%）
  - ObjC：71 行（0.1%）
  - Batch：64 行（0.1%）
  - YAML：49 行（0.1%）
  - HTML：19 行（0.0%）
  - Python：18 行（0.0%）
  - INI：12 行（0.0%）

- **字符总数**：2,266,153 字符（不含注释）
  - Dart：1,555,517 字符（68.6%）
  - JSON：376,648 字符（16.6%）
  - JavaScript：293,886 字符（13.0%）
  - C++：15,306 字符（0.7%）
  - C：3,231 字符（0.2%）
  - XML：4,900 字符（0.2%）
  - Kotlin：2,534 字符（0.1%）
  - Swift：2,559 字符（0.1%）
  - Java：3,564 字符（0.2%）
  - ObjC：2,999 字符（0.1%）
  - Batch：2,107 字符（0.1%）
  - YAML：1,009 字符（0.1%）
  - HTML：657 字符（0.0%）
  - Python：750 字符（0.0%）
  - INI：486 字符（0.0%）

> 数据来源：以上数据基于项目内的 `project_stats.py` 统计生成

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run
dart run build_runner build --delete-conflicting-outputs
```
