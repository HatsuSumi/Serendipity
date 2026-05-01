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
- **媒体与头像**：photo_manager、image_cropper、path_provider
- **其他能力**：url_launcher、package_info_plus、uuid、intl
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
│   │   ├── avatar/        # 头像选择与裁剪
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

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run
dart run build_runner build --delete-conflicting-outputs
```
