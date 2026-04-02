class PushTokenRegistration {
  final String token;
  final String platform;
  final String timezone;

  const PushTokenRegistration({
    required this.token,
    required this.platform,
    required this.timezone,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'platform': platform,
      'timezone': timezone,
    };
  }
}

