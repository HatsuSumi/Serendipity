import 'enums.dart';

/// 支付记录
class PaymentRecord {
  final String id;
  final String userId;
  final String membershipId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? receiptData;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentRecord({
    required this.id,
    required this.userId,
    required this.membershipId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.receiptData,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 PaymentRecord
  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      userId: json['userId'] as String,
      membershipId: json['membershipId'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values
          .firstWhere((e) => e.value == json['method'] as String),
      status: PaymentStatus.values
          .firstWhere((e) => e.value == json['status'] as int),
      transactionId: json['transactionId'] as String?,
      receiptData: json['receiptData'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'membershipId': membershipId,
      'amount': amount,
      'method': method.value,
      'status': status.value,
      'transactionId': transactionId,
      'receiptData': receiptData,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  PaymentRecord copyWith({
    String? id,
    String? userId,
    String? membershipId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    String? receiptData,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      membershipId: membershipId ?? this.membershipId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      receiptData: receiptData ?? this.receiptData,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PaymentRecord(id: $id, amount: $amount, method: ${method.label}, status: ${status.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentRecord &&
        other.id == id &&
        other.userId == userId &&
        other.membershipId == membershipId &&
        other.amount == amount &&
        other.method == method &&
        other.status == status &&
        other.transactionId == transactionId &&
        other.receiptData == receiptData &&
        other.paidAt == paidAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        membershipId.hashCode ^
        amount.hashCode ^
        method.hashCode ^
        status.hashCode ^
        transactionId.hashCode ^
        receiptData.hashCode ^
        paidAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

