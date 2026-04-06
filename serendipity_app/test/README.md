# 测试目录说明

本目录包含 Serendipity Flutter 客户端的测试代码与测试资源，覆盖模型、Provider、Service、工具函数，以及部分多设备同步相关场景。

## 测试目标

当前测试主要覆盖以下方向：
- 数据模型的序列化、拷贝与业务约束
- Provider 的状态流转与业务逻辑
- Service 的核心能力，如通知、定位、存储、成就检测等
- 多用户隔离与多设备同步相关场景
- 签到提醒文案与签到缓存等专项逻辑

## 目录结构

```text
test/
├── constants/                 # 常量与配置相关测试
│   └── achievement_definitions_test.dart
├── core/
│   ├── services/              # core/services 下的专项测试
│   │   └── notification_service_test.dart
│   └── utils/
├── fixtures/                  # 测试夹具与测试数据辅助文件
├── integration/               # 集成测试与测试说明
│   ├── multi_device_sync_test.dart
│   └── user_settings_sync_test.md
├── models/                    # 数据模型测试
│   ├── achievement_test.dart
│   ├── community_post_test.dart
│   ├── encounter_record_copywith_test.dart
│   ├── encounter_record_test.dart
│   ├── location_result_test.dart
│   ├── membership_test.dart
│   ├── story_line_test.dart
│   ├── user_settings_test.dart
│   └── user_test.dart
├── providers/                 # Provider 测试
│   ├── check_in_provider_test.dart
│   ├── location_provider_test.dart
│   └── sync_status_provider_test.dart
├── services/                  # 业务服务测试
│   ├── achievement_detector_test.dart
│   ├── geolocator_location_service_test.dart
│   ├── storage_service_test.dart
│   └── sync_history_test.dart
├── unit/                      # 更细分的单元测试目录
│   ├── providers/
│   │   └── records_provider_multi_user_test.dart
│   ├── repositories/
│   │   ├── check_in_repository_remote_cache_test.dart
│   │   └── record_repository_multi_user_test.dart
│   └── services/
├── utils/                     # 工具函数测试
│   └── check_in_reminder_helper_test.dart
├── README.md                  # 本文档
└── test_posts.json            # 测试用社区帖子数据
```

## 主要测试分类

### 1. 模型测试
位于 `test/models/`，主要验证：
- 数据模型构造与默认值
- `copyWith` 行为
- JSON 序列化 / 反序列化
- 枚举与字段约束

### 2. Provider 测试
位于 `test/providers/` 与 `test/unit/providers/`，主要验证：
- 状态切换是否符合预期
- 依赖注入后的行为是否正确
- 登录 / 离线 / 同步场景下的数据读取与刷新逻辑
- 多用户场景下的数据隔离

### 3. Service 测试
位于 `test/services/` 与 `test/core/services/`，主要验证：
- 通知服务调度与取消逻辑
- 定位服务行为
- 本地存储服务读写
- 成就检测逻辑
- 同步历史相关行为

### 4. Repository 测试
位于 `test/unit/repositories/`，主要验证：
- 记录仓储的数据隔离
- 签到远端状态缓存的保存与读取
- 多用户与本地缓存边界情况

### 5. 集成测试
位于 `test/integration/`，主要关注：
- 多设备同步
- 跨设备/跨用户的数据一致性
- 同步链路中的关键交互场景

## 当前专项测试说明

### 多用户数据隔离
当前与多用户隔离直接相关的测试主要包括：
- `test/unit/repositories/record_repository_multi_user_test.dart`
- `test/unit/providers/records_provider_multi_user_test.dart`

这类测试重点验证：
- 用户 A 的数据不会泄露给用户 B
- 按用户维度读取的数据不会串号
- 多用户并发操作时状态不会混淆

### 多设备同步
当前与多设备同步直接相关的测试主要包括：
- `test/integration/multi_device_sync_test.dart`

这类测试重点验证：
- 同一用户在多个设备上的数据同步行为
- 离线数据与登录后绑定场景
- 同步过程中的用户隔离与一致性

### 签到与提醒相关测试
当前与签到/提醒直接相关的测试主要包括：
- `test/providers/check_in_provider_test.dart`
- `test/unit/repositories/check_in_repository_remote_cache_test.dart`
- `test/utils/check_in_reminder_helper_test.dart`
- `test/core/services/notification_service_test.dart`

这类测试重点验证：
- 登录用户与未登录用户的签到逻辑差异
- 服务端签到状态缓存
- 提醒文案生成
- 本地通知调度与取消

## 常用命令

### 运行全部测试

```bash
flutter test
```

### 运行单个测试文件

```bash
flutter test test/providers/check_in_provider_test.dart
flutter test test/core/services/notification_service_test.dart
flutter test test/integration/multi_device_sync_test.dart
```

### 运行多用户隔离相关测试

```bash
flutter test test/unit/repositories/record_repository_multi_user_test.dart
flutter test test/unit/providers/records_provider_multi_user_test.dart
```

### 运行签到与提醒相关测试

```bash
flutter test test/providers/check_in_provider_test.dart
flutter test test/unit/repositories/check_in_repository_remote_cache_test.dart
flutter test test/utils/check_in_reminder_helper_test.dart
flutter test test/core/services/notification_service_test.dart
```

### 使用名称过滤运行特定测试

```bash
flutter test test/providers/check_in_provider_test.dart -k "guest"
flutter test test/unit/repositories/record_repository_multi_user_test.dart -k "different users"
```

### 生成覆盖率报告

```bash
flutter test --coverage
```

## 编写测试时的建议

新增测试时，建议优先遵循以下原则：
- 目录归类与被测对象保持一致
- 优先测试真实业务边界，而不是只测 getter/setter
- 多用户、多设备、登录/离线切换等场景优先覆盖
- 避免在 `test/README.md` 中记录已经不存在的专项文件名

## 相关说明

- `test/test_posts.json` 用于社区相关测试数据
- `test/integration/user_settings_sync_test.md` 是用户设置同步相关的测试说明文档，不是可直接执行的测试文件
- 如果后续新增大规模专项测试，可继续在本 README 中补充入口说明，但应保持与当前真实目录一致
