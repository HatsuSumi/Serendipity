import 'package:flutter/services.dart';

class NotificationCacheRecoveryService {
  static const MethodChannel _channel = MethodChannel(
    'com.serendipity.notification_cache',
  );

  const NotificationCacheRecoveryService();

  Future<void> recoverScheduledNotificationCache({required int notificationId}) {
    return _channel.invokeMethod<void>(
      'recoverScheduledNotificationCache',
      {'id': notificationId},
    );
  }
}
