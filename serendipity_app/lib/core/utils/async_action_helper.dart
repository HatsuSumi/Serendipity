import 'package:flutter/material.dart';
import 'message_helper.dart';
import 'auth_error_helper.dart';

/// 异步操作辅助工具
/// 
/// 统一处理异步操作的错误处理和成功提示
class AsyncActionHelper {
  /// 执行异步操作并统一处理错误
  /// 
  /// 参数：
  /// - context: BuildContext
  /// - action: 要执行的异步操作
  /// - successMessage: 成功提示消息（可选）
  /// - errorMessagePrefix: 错误消息前缀（默认为"操作失败"）
  /// - onSuccess: 成功后的回调（可选）
  /// - onError: 错误后的回调（可选）
  /// 
  /// 返回：
  /// - true: 操作成功
  /// - false: 操作失败
  /// 
  /// 示例：
  /// ```dart
  /// await AsyncActionHelper.execute(
  ///   context,
  ///   action: () => ref.read(recordsProvider.notifier).deleteRecord(id),
  ///   successMessage: '记录已删除',
  ///   errorMessagePrefix: '删除失败',
  ///   onSuccess: () => Navigator.of(context).pop(),
  /// );
  /// ```
  static Future<bool> execute(
    BuildContext context, {
    required Future<void> Function() action,
    String? successMessage,
    String errorMessagePrefix = '操作失败',
    VoidCallback? onSuccess,
    void Function(Object error)? onError,
  }) async {
    try {
      await action();
      
      if (context.mounted) {
        if (successMessage != null) {
          MessageHelper.showSuccess(context, successMessage);
        }
        onSuccess?.call();
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        final cleanMessage = AuthErrorHelper.extractErrorMessage(e);
        MessageHelper.showError(context, '$errorMessagePrefix：$cleanMessage');
        onError?.call(e);
      }
      
      return false;
    }
  }

  /// 执行异步操作并返回结果
  /// 
  /// 参数：
  /// - context: BuildContext
  /// - action: 要执行的异步操作
  /// - errorMessagePrefix: 错误消息前缀（默认为"操作失败"）
  /// - onError: 错误后的回调（可选）
  /// 
  /// 返回：
  /// - 操作结果（成功时）
  /// - null（失败时）
  /// 
  /// 示例：
  /// ```dart
  /// final record = await AsyncActionHelper.executeWithResult<EncounterRecord>(
  ///   context,
  ///   action: () => ref.read(recordsProvider.notifier).getRecord(id),
  ///   errorMessagePrefix: '获取记录失败',
  /// );
  /// ```
  static Future<T?> executeWithResult<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String errorMessagePrefix = '操作失败',
    void Function(Object error)? onError,
  }) async {
    try {
      return await action();
    } catch (e) {
      if (context.mounted) {
        final cleanMessage = AuthErrorHelper.extractErrorMessage(e);
        MessageHelper.showError(context, '$errorMessagePrefix：$cleanMessage');
        onError?.call(e);
      }
      
      return null;
    }
  }

  /// 执行异步操作，不显示任何提示
  /// 
  /// 参数：
  /// - action: 要执行的异步操作
  /// - onError: 错误后的回调（可选）
  /// 
  /// 返回：
  /// - true: 操作成功
  /// - false: 操作失败
  /// 
  /// 示例：
  /// ```dart
  /// final success = await AsyncActionHelper.executeSilently(
  ///   action: () => ref.read(recordsProvider.notifier).refresh(),
  ///   onError: (e) => print('Refresh failed: $e'),
  /// );
  /// ```
  static Future<bool> executeSilently({
    required Future<void> Function() action,
    void Function(Object error)? onError,
  }) async {
    try {
      await action();
      return true;
    } catch (e) {
      onError?.call(e);
      return false;
    }
  }
}

