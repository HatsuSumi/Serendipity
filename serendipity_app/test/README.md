## 多用户数据隔离测试指南

本目录包含针对多用户场景、多设备同步和数据隔离的单元测试和集成测试。

### 📁 测试文件结构

```
test/
├── unit/
│   ├── repositories/
│   │   └── record_repository_multi_user_test.dart       # 记录仓储隔离测试
│   └── providers/
│       └── records_provider_multi_user_test.dart        # 记录提供者隔离测试
└── integration/
    └── multi_device_sync_test.dart                      # 多设备同步集成测试
```

### 🧪 测试覆盖范围

#### 1. 记录仓储隔离测试 (`record_repository_multi_user_test.dart`)

**测试场景：**
- ✅ 只返回指定用户的记录
- ✅ 用户 A 的数据不会泄露给用户 B
- ✅ 空用户列表处理
- ✅ null userId（离线记录）处理
- ✅ 记录删除隔离
- ✅ 数据一致性验证

**关键验证：**
```dart
// 用户 B 只能看到自己的 1 条记录
final recordsB = repository.getRecordsByUser(userB);
expect(recordsB, hasLength(1));
expect(recordsB[0].ownerId, equals(userB));
expect(recordsB.map((r) => r.id), isNot(contains('record_a_1')));
```

#### 2. 记录提供者隔离测试 (`records_provider_multi_user_test.dart`)

**测试场景：**
- ✅ 用户特定的记录查询隔离
- ✅ 并发访问时的数据隔离
- ✅ 记录更新隔离
- ✅ 离线记录处理
- ✅ 数据一致性检查

**关键验证：**
```dart
// 并发创建记录时，数据不混淆
expect(recordsA.every((r) => r.ownerId == userA), isTrue);
expect(recordsB.every((r) => r.ownerId == userB), isTrue);
expect(recordsA.map((r) => r.id), isNot(containsAny(recordsB.map((r) => r.id))));
```

#### 3. 多设备同步集成测试 (`multi_device_sync_test.dart`)

**测试场景：**
- ✅ 同一用户的两个设备数据隔离
- ✅ 不同用户在同一设备上的数据隔离
- ✅ 故事线跨设备隔离
- ✅ 多设备更新冲突处理
- ✅ 并发更新时的用户隔离
- ✅ 离线到在线的同步绑定
- ✅ 离线记录不泄露给其他用户

**关键验证：**
```dart
// 设备 A 和 B 的记录都被保存，但属于同一用户
final userRecords = recordRepository.getRecordsByUser(userId);
expect(userRecords, hasLength(2));
expect(userRecords.map((r) => r.id), 
  containsAll(['device_a_record_1', 'device_b_record_1']));
```

### 🚀 运行测试

#### 运行所有多用户隔离测试
```bash
flutter test test/unit/services/achievement_detector_multi_user_test.dart test/unit/services/sync_service_multi_user_test.dart
```

#### 运行特定测试文件
```bash
# 成就检测隔离测试
flutter test test/unit/services/achievement_detector_multi_user_test.dart

# 同步服务隔离测试
flutter test test/unit/services/sync_service_multi_user_test.dart
```

#### 运行特定测试组
```bash
# 只运行记录成就检测测试
flutter test test/unit/services/achievement_detector_multi_user_test.dart -k "Record Achievement Detection"

# 只运行上传隔离测试
flutter test test/unit/services/sync_service_multi_user_test.dart -k "Upload Local Data"
```

#### 运行所有测试并生成覆盖率报告
```bash
flutter test --coverage
lcov --list coverage/lcov.info
```

### 📊 测试数据工厂使用示例

```dart
import 'test/fixtures/test_data_factory.dart';

// 创建测试用户
final userA = TestDataFactory.createUser(id: 'user_a');
final userB = TestDataFactory.createUser(id: 'user_b');

// 创建单条记录
final record = TestDataFactory.createRecord(
  id: 'record_1',
  ownerId: userA.id,
  status: EncounterStatus.missed,
);

// 创建多条记录
final records = TestDataFactory.createRecords(
  count: 10,
  ownerId: userA.id,
);

// 创建故事线
final storyLine = TestDataFactory.createStoryLine(
  id: 'story_1',
  ownerId: userA.id,
);

// 创建签到记录
final checkIn = TestDataFactory.createCheckIn(
  id: 'checkin_1',
  userId: userA.id,
);

// 使用断言验证数据隔离
TestAssertions.assertAllRecordsBelongToUser(records, userA.id);
TestAssertions.assertAllStoryLinesBelongToUser([storyLine], userA.id);
```

### 🔍 Mock 对象说明

所有测试都使用 `mockito` 库创建 Mock 对象：

- `MockAchievementRepository` - 模拟成就仓储
- `MockRecordRepository` - 模拟记录仓储
- `MockStoryLineRepository` - 模拟故事线仓储
- `MockCheckInRepository` - 模拟签到仓储
- `MockRemoteDataRepository` - 模拟远程数据仓储
- `MockStorageService` - 模拟本地存储服务

### ✅ 测试通过标准

所有测试应该通过以下验证：

1. **数据隔离验证**
   - 用户 A 的操作不影响用户 B 的数据
   - 成就检测只基于当前用户的数据
   - 同步操作只处理当前用户的数据

2. **参数验证**
   - 空 userId 应抛出 `ArgumentError`
   - 无效参数应被正确处理

3. **Mock 验证**
   - 正确的方法被调用了正确的次数
   - 不应该调用的方法没有被调用

### 📝 添加新测试

当添加新的多用户隔离测试时，遵循以下模式：

```dart
test('should isolate data for different users', () async {
  // 1. 准备数据
  const userA = User(id: 'user_a', email: 'a@example.com');
  const userB = User(id: 'user_b', email: 'b@example.com');
  
  final dataA = TestDataFactory.createRecords(count: 5, ownerId: userA.id);
  final dataB = TestDataFactory.createRecords(count: 3, ownerId: userB.id);
  
  // 2. 设置 Mock
  when(mockStorage.getRecordsByUser(userA.id)).thenReturn(dataA);
  when(mockStorage.getRecordsByUser(userB.id)).thenReturn(dataB);
  
  // 3. 执行操作
  final resultA = await service.operation(userA);
  final resultB = await service.operation(userB);
  
  // 4. 验证隔离
  expect(resultA, isNot(contains(dataB)));
  expect(resultB, isNot(contains(dataA)));
  
  // 5. 验证 Mock 调用
  verify(mockStorage.getRecordsByUser(userA.id)).called(1);
  verify(mockStorage.getRecordsByUser(userB.id)).called(1);
});
```

### 🐛 调试测试

如果测试失败，使用以下命令获取详细输出：

```bash
# 显示详细的测试输出
flutter test test/unit/services/achievement_detector_multi_user_test.dart -v

# 显示 Mock 验证的详细信息
flutter test test/unit/services/achievement_detector_multi_user_test.dart --verbose
```

### 📚 相关文档

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Riverpod Testing](https://riverpod.dev/docs/essentials/testing)

### 🎯 下一步

1. 运行所有测试确保通过
2. 添加更多边界情况测试
3. 集成到 CI/CD 流程
4. 定期运行覆盖率检查

