/// Iterable 扩展方法
/// 
/// 提供更友好的错误信息
extension IterableX<T> on Iterable<T> {
  /// 查找第一个匹配的元素，找不到时抛出带详细信息的异常
  /// 
  /// 参数：
  /// - test: 测试函数
  /// - message: 错误信息
  /// 
  /// 示例：
  /// ```dart
  /// final user = users.firstWhereOrThrow(
  ///   (u) => u.id == id,
  ///   message: 'User with id=$id not found in users list (length=${users.length})',
  /// );
  /// ```
  T firstWhereOrThrow(
    bool Function(T element) test, {
    required String message,
  }) {
    for (final element in this) {
      if (test(element)) return element;
    }
    throw StateError(message);
  }
}

/// List 扩展方法
/// 
/// 提供安全的访问方法
extension SafeList<T> on List<T> {
  /// 安全获取第一个元素
  /// 
  /// 如果列表为空，抛出带详细信息的异常
  T get firstOrThrow {
    if (isEmpty) {
      throw StateError('List is empty, cannot get first element');
    }
    return first;
  }

  /// 安全获取最后一个元素
  /// 
  /// 如果列表为空，抛出带详细信息的异常
  T get lastOrThrow {
    if (isEmpty) {
      throw StateError('List is empty, cannot get last element');
    }
    return last;
  }

  /// 安全获取唯一元素
  /// 
  /// 如果列表为空或有多个元素，抛出带详细信息的异常
  T get singleOrThrow {
    if (isEmpty) {
      throw StateError('List is empty, cannot get single element');
    }
    if (length > 1) {
      throw StateError('List has $length elements, expected exactly 1');
    }
    return single;
  }
}

