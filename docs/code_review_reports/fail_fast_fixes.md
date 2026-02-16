# Fail Fast 原则修复报告

## 修复日期
2026-02-15

## 修复概述
对模型类进行了全面的 Fail Fast 原则修复，区分程序内部错误和用户操作错误，确保在数据损坏或违反不变量时快速失败并提供明确的错误信息。

---

## 核心原则

### 程序内部错误（应该 Fail Fast）
- ✅ 违反不变量和数据一致性
- ✅ 程序员错误（如传入空字符串给必填字段）
- ✅ 数据损坏（反序列化时遇到无效枚举值）
- ✅ 内部 API 调用错误

**处理方式：** 使用 `assert` 或抛出 `StateError`，提供明确的错误信息

### 用户操作错误（应该优雅处理）
- ❌ 用户输入验证失败
- ❌ 网络请求失败
- ❌ 文件不存在
- ❌ 权限不足

**处理方式：** 返回 null/Result 或显示友好的错误提示

---

## 修复详情

### 1. encounter_record.dart

#### 1.1 TagWithNote 构造函数
**问题：** 注释说明"最多50字"，但没有验证

**修复前：**
```dart
TagWithNote({
  required this.tag,
  this.note,
});
```

**修复后：**
```dart
TagWithNote({
  required this.tag,
  this.note,
}) : assert(tag.isNotEmpty, 'Tag cannot be empty'),
     assert(note == null || note.length <= 50, 
       'Note must be at most 50 characters, got ${note?.length}');
```

**原因：** 这是程序内部错误，调用者应该保证业务规则。

---

#### 1.2 Location.fromJson
**问题：** `firstWhere` 在找不到匹配时抛出不明确的 `StateError`

**修复前：**
```dart
placeType: json['placeType'] != null
    ? PlaceType.values.firstWhere((e) => e.value == json['placeType'])
    : null,
```

**修复后：**
```dart
placeType: json['placeType'] != null
    ? PlaceType.values.firstWhere(
        (e) => e.value == json['placeType'],
        orElse: () => throw StateError(
          'Invalid placeType value: ${json['placeType']}. '
          'Expected one of: ${PlaceType.values.map((e) => e.value).join(", ")}'
        ),
      )
    : null,
```

**原因：** 数据损坏是程序内部错误，应该提供明确的错误信息帮助调试。

---

#### 1.3 EncounterRecord 构造函数
**问题：** 注释说明字段长度限制，但没有验证

**修复前：**
```dart
EncounterRecord({
  required this.id,
  // ... 其他参数
  this.description, // 可选，最多500字
  this.conversationStarter, // 可选，最多500字
  // ...
});
```

**修复后：**
```dart
EncounterRecord({
  required this.id,
  // ... 其他参数
  this.description,
  this.conversationStarter,
  // ...
}) : assert(id.isNotEmpty, 'ID cannot be empty'),
     assert(description == null || description.length <= 500, 
       'Description must be at most 500 characters, got ${description?.length}'),
     assert(conversationStarter == null || conversationStarter.length <= 500, 
       'ConversationStarter must be at most 500 characters, got ${conversationStarter?.length}');
```

**原因：** 业务规则验证，调用者违反契约是程序内部错误。

---

#### 1.4 EncounterRecord.fromJson
**问题：** 多个 `firstWhere` 缺少 `orElse`，错误信息不明确

**修复前：**
```dart
emotion: json['emotion'] != null
    ? EmotionIntensity.values.firstWhere((e) => e.value == json['emotion'])
    : null,
status: EncounterStatus.values.firstWhere((e) => e.value == json['status']),
weather: json['weather'] != null
    ? (json['weather'] as List)
        .map((w) => Weather.values.firstWhere((e) => e.value == w))
        .toList()
    : [],
```

**修复后：**
```dart
emotion: json['emotion'] != null
    ? EmotionIntensity.values.firstWhere(
        (e) => e.value == json['emotion'],
        orElse: () => throw StateError(
          'Invalid emotion value: ${json['emotion']}. '
          'Expected one of: ${EmotionIntensity.values.map((e) => e.value).join(", ")}'
        ),
      )
    : null,
status: EncounterStatus.values.firstWhere(
  (e) => e.value == json['status'],
  orElse: () => throw StateError(
    'Invalid status value: ${json['status']}. '
    'Expected one of: ${EncounterStatus.values.map((e) => e.value).join(", ")}'
  ),
),
weather: json['weather'] != null
    ? (json['weather'] as List)
        .map((w) => Weather.values.firstWhere(
          (e) => e.value == w,
          orElse: () => throw StateError(
            'Invalid weather value: $w. '
            'Expected one of: ${Weather.values.map((e) => e.value).join(", ")}'
          ),
        ))
        .toList()
    : [],
```

**原因：** 数据损坏时应该快速失败，并提供所有可能的有效值帮助调试。

---

### 2. user_settings.dart

#### 2.1 UserSettings.fromJson
**问题：** `firstWhere` 缺少 `orElse`

**修复前：**
```dart
theme: ThemeOption.values
    .firstWhere((e) => e.value == json['theme'] as String),
```

**修复后：**
```dart
theme: ThemeOption.values.firstWhere(
  (e) => e.value == json['theme'] as String,
  orElse: () => throw StateError(
    'Invalid theme value: ${json['theme']}. '
    'Expected one of: ${ThemeOption.values.map((e) => e.value).join(", ")}'
  ),
),
```

**原因：** theme 是必填字段，数据损坏时应该明确报错。

---

#### 2.2 UserSettings.copyWith
**问题：** 可空字段无法区分"不修改"和"设置为 null"

**修复前：**
```dart
UserSettings copyWith({
  String? accentColor,
  String? passwordHash,
  // ...
}) {
  return UserSettings(
    accentColor: accentColor ?? this.accentColor,
    passwordHash: passwordHash ?? this.passwordHash,
    // ...
  );
}
```

**修复后：**
```dart
/// 复制并修改部分字段
/// 
/// 对于可空字段（accentColor, passwordHash），使用函数包装来区分"未传递"和"传递 null"：
/// - 不传参数：保持原值
/// - 传递函数返回 null：清空字段
/// - 传递函数返回新值：更新字段
/// 
/// 示例：
/// ```dart
/// // 清空强调色
/// settings.copyWith(accentColor: () => null)
/// 
/// // 修改强调色
/// settings.copyWith(accentColor: () => '#FF5722')
/// 
/// // 保持强调色不变
/// settings.copyWith(theme: ThemeOption.dark)
/// ```
UserSettings copyWith({
  String? Function()? accentColor,
  String? Function()? passwordHash,
  // ...
}) {
  return UserSettings(
    accentColor: accentColor != null ? accentColor() : this.accentColor,
    passwordHash: passwordHash != null ? passwordHash() : this.passwordHash,
    // ...
  );
}
```

**原因：** 统一 API 设计，与 `EncounterRecord.copyWith` 保持一致，避免程序员误用。

---

### 3. story_line.dart

#### 3.1 StoryLine 构造函数
**问题：** 必填字段没有验证

**修复前：**
```dart
const StoryLine({
  required this.id,
  required this.name,
  required this.recordIds,
  required this.createdAt,
  required this.updatedAt,
});
```

**修复后：**
```dart
const StoryLine({
  required this.id,
  required this.name,
  required this.recordIds,
  required this.createdAt,
  required this.updatedAt,
}) : assert(id != '', 'ID cannot be empty'),
     assert(name != '', 'Name cannot be empty');
```

**原因：** 空字符串违反业务规则，是程序内部错误。

---

## 修复效果

### 修复前的问题
1. ❌ 数据损坏时错误信息不明确，难以调试
2. ❌ 业务规则没有验证，可能产生无效数据
3. ❌ API 设计不一致（copyWith 方法）
4. ❌ 违反 Fail Fast 原则，错误可能延迟暴露

### 修复后的改进
1. ✅ 所有数据损坏都会立即抛出明确的 `StateError`
2. ✅ 构造函数使用 `assert` 验证业务规则
3. ✅ 统一 `copyWith` 方法的可空字段处理
4. ✅ 错误信息包含实际值和期望值，便于调试
5. ✅ 符合 Fail Fast 原则，在最早的时间点发现问题

---

## 后续建议

### 1. UI 层异常处理（未在本次修复）
建议在 UI 层区分内部错误和用户错误：

```dart
try {
  await repository.saveRecord(record);
  showSuccess('保存成功');
} on StateError catch (e) {
  // 程序内部错误 - 记录日志并显示技术错误
  debugPrint('Internal error: $e');
  showError('保存失败：数据异常，请联系开发者');
  rethrow; // 重新抛出，让错误上报系统捕获
} on NetworkException catch (e) {
  // 用户操作错误 - 友好提示
  showError('保存失败：网络连接异常');
} catch (e) {
  // 未知错误 - 保守处理
  debugPrint('Unknown error: $e');
  showError('保存失败：$e');
}
```

### 2. 数据一致性验证
`record_repository.dart` 中已有 `validateDataConsistency()` 方法，建议：
- 在应用启动时调用
- 在开发模式下定期调用
- 在数据迁移后调用

### 3. 单元测试
为所有修复添加单元测试，验证：
- ✅ 有效数据能正常处理
- ✅ 无效数据会抛出明确的错误
- ✅ 错误信息包含有用的调试信息

---

## 总结

本次修复全面应用了 Fail Fast 原则，确保：
1. **程序内部错误**快速失败，提供明确的错误信息
2. **业务规则**在构造函数中验证，防止无效数据产生
3. **API 设计**统一一致，减少程序员误用
4. **错误信息**详细明确，便于调试和问题定位

所有修复都遵循"在最早的时间点发现问题"的原则，提高了代码的健壮性和可维护性。

