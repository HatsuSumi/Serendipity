/// Extract required string field
String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is! String) {
    throw FormatException('Field "$key" must be String, got ${value.runtimeType}');
  }
  return value;
}

/// Extract optional string field
String? optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Field "$key" must be String or null, got ${value.runtimeType}');
  }
  return value;
}

/// Extract required double field
double requireDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is! num) {
    throw FormatException('Field "$key" must be num, got ${value.runtimeType}');
  }
  return value.toDouble();
}

/// Extract optional double field
double? optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num) {
    throw FormatException('Field "$key" must be num or null, got ${value.runtimeType}');
  }
  return value.toDouble();
}

/// Extract required bool field
bool requireBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is! bool) {
    throw FormatException('Field "$key" must be bool, got ${value.runtimeType}');
  }
  return value;
}

/// Extract optional bool field
bool? optionalBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! bool) {
    throw FormatException('Field "$key" must be bool or null, got ${value.runtimeType}');
  }
  return value;
}

/// Extract required list field
List<T> requireList<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    throw FormatException('Missing required field: $key');
  }
  if (value is! List) {
    throw FormatException('Field "$key" must be List, got ${value.runtimeType}');
  }
  return List<T>.from(value);
}

/// Extract optional list field
List<T>? optionalList<T>(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! List) {
    throw FormatException('Field "$key" must be List or null, got ${value.runtimeType}');
  }
  return List<T>.from(value);
}
