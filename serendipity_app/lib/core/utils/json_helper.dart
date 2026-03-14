/// JSON 序列化辅助工具
/// 
/// 提供类型安全的 JSON 字段读取和写入
class JsonHelper {
  JsonHelper._();

  /// 读取字段（带类型检查）
  /// 
  /// 如果字段类型不匹配，抛出清晰的错误信息
  /// 
  /// 示例：
  /// ```dart
  /// name: JsonHelper.readField<String>(json, 'name'),
  /// age: JsonHelper.readField<int>(json, 'age'),
  /// ```
  static T? readField<T>(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) return null;

    if (value is! T) {
      throw FormatException(
        'Field "$key" expected $T but got ${value.runtimeType} ($value)',
      );
    }

    return value;
  }

  /// 验证 JSON 字段类型（用于 toJson）
  /// 
  /// 在序列化前验证字段类型，避免发送错误类型给后端
  /// 
  /// 示例：
  /// ```dart
  /// final json = <String, dynamic>{
  ///   'name': JsonHelper.validateField('name', name, String),
  ///   'age': JsonHelper.validateField('age', age, int),
  /// };
  /// ```
  static T validateField<T>(String key, dynamic value, Type expectedType) {
    if (value == null) {
      throw FormatException(
        'Field "$key" is null but expected $expectedType',
      );
    }

    if (value.runtimeType != expectedType) {
      throw FormatException(
        'Field "$key" expected $expectedType but got ${value.runtimeType} ($value)',
      );
    }

    return value as T;
  }

  /// 验证可选字段类型
  /// 
  /// 允许 null 值，但如果不是 null 则必须是正确类型
  static T? validateOptionalField<T>(String key, dynamic value, Type expectedType) {
    if (value == null) return null;

    if (value.runtimeType != expectedType) {
      throw FormatException(
        'Field "$key" expected $expectedType? but got ${value.runtimeType} ($value)',
      );
    }

    return value as T;
  }
}

