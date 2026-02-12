# Hive 本地存储设置步骤

## 当前进度

✅ 已完成：
1. 添加 Hive 相关依赖到 `pubspec.yaml`
2. 为 `enums.dart` 中的所有枚举添加 Hive 注解（13个枚举）
3. 为 `encounter_record.dart` 中的类添加 Hive 注解（3个类）

## 下一步操作

### 1. 安装依赖

在项目根目录 `serendipity_app` 下运行：

```bash
flutter pub get
```

### 2. 生成 TypeAdapter

运行代码生成器：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

这会生成以下文件：
- `lib/models/enums.g.dart`
- `lib/models/encounter_record.g.dart`

### 3. 检查生成的文件

确保生成的文件没有错误，包含了所有的 TypeAdapter。

### 4. 为其他数据模型添加 Hive 注解

还需要为以下模型添加 Hive 注解：

- [ ] `story_line.dart` (typeId: 3)
- [ ] `achievement.dart` (typeId: 4)
- [ ] `match.dart` (typeId: 5)
- [ ] `conversation.dart` (typeId: 6)
- [ ] `community_post.dart` (typeId: 7)
- [ ] `user.dart` (typeId: 8)
- [ ] `membership.dart` (typeId: 9)
- [ ] `user_settings.dart` (typeId: 24)
- [ ] `user_credit_score.dart` (typeId: 25)
- [ ] `keep_in_memory_list.dart` (typeId: 26)
- [ ] `payment_record.dart` (typeId: 27)

**注意**：typeId 必须唯一，已使用的 typeId：
- 0-2: TagWithNote, Location, EncounterRecord
- 10-23: 所有枚举类型

### 5. 初始化 Hive

在 `main.dart` 中初始化 Hive 并注册所有 TypeAdapter。

### 6. 创建存储服务

创建 `lib/core/services/storage_service.dart`，提供 CRUD 操作。

## TypeId 分配表

| TypeId | 类型 | 文件 |
|--------|------|------|
| 0 | TagWithNote | encounter_record.dart |
| 1 | Location | encounter_record.dart |
| 2 | EncounterRecord | encounter_record.dart |
| 3 | StoryLine | story_line.dart |
| 4 | Achievement | achievement.dart |
| 5 | Match | match.dart |
| 6 | Conversation | conversation.dart |
| 7 | CommunityPost | community_post.dart |
| 8 | User | user.dart |
| 9 | Membership | membership.dart |
| 10 | EncounterStatus | enums.dart |
| 11 | EmotionIntensity | enums.dart |
| 12 | PlaceType | enums.dart |
| 13 | Weather | enums.dart |
| 14 | MatchStatus | enums.dart |
| 15 | MatchConfidence | enums.dart |
| 16 | VerificationChoice | enums.dart |
| 17 | AuthProvider | enums.dart |
| 18 | MembershipTier | enums.dart |
| 19 | MembershipStatus | enums.dart |
| 20 | PaymentMethod | enums.dart |
| 21 | PaymentStatus | enums.dart |
| 22 | AppTheme | enums.dart |
| 23 | CreditChangeReason | enums.dart |
| 24 | UserSettings | user_settings.dart |
| 25 | UserCreditScore | user_credit_score.dart |
| 26 | KeepInMemoryList | keep_in_memory_list.dart |
| 27 | PaymentRecord | payment_record.dart |
| 28+ | 预留给其他嵌套类 | - |

## 注意事项

1. **TypeId 必须唯一**：每个类和枚举都需要一个唯一的 typeId
2. **HiveField 索引从 0 开始**：每个字段的索引必须唯一且连续
3. **不要修改已有的 typeId**：一旦数据保存后，修改 typeId 会导致数据无法读取
4. **枚举值的顺序不能改变**：添加新值可以，但不能改变现有值的顺序

## 遇到问题？

如果生成代码时遇到错误，检查：
1. 是否所有的 `part` 语句都正确
2. 是否所有字段都添加了 `@HiveField` 注解
3. typeId 是否有重复
4. HiveField 索引是否有重复或跳号

