# Phase 1.7: Mock 支付功能

## 概述

Phase 1.7 实现了支付功能的 Mock 模式，支持在开发/测试环境下模拟支付流程，无需真实的支付平台账号。

## 功能特性

### 1. 模式切换
- **Mock 模式**（默认）：模拟支付，自动在 3 秒后完成支付
- **真实模式**：集成 YunGouOS 支付平台（待实现）

### 2. 支付方式
- 免费解锁（¥0）
- 微信支付（¥1-648）
- 支付宝（¥1-648）

### 3. API 接口

#### 3.1 创建支付订单
```http
POST /api/v1/payment/create
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "amount": 100,
  "method": "wechat"
}
```

**响应：**
```json
{
  "success": true,
  "data": {
    "orderId": "ORDER_1234567890_1234",
    "amount": 100,
    "method": "wechat",
    "status": "pending",
    "paymentUrl": "https://mock-payment.serendipity.com/pay?orderId=...",
    "qrCode": "https://mock-qr.serendipity.com/qr?orderId=...",
    "expiresAt": "2026-02-27T12:00:00.000Z",
    "createdAt": "2026-02-27T11:45:00.000Z"
  }
}
```

#### 3.2 查询支付状态
```http
GET /api/v1/payment/status/:orderId
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "success": true,
  "data": {
    "orderId": "ORDER_1234567890_1234",
    "amount": 100,
    "method": "wechat",
    "status": "success",
    "transactionId": "MOCK_TXN_1234567890",
    "paidAt": "2026-02-27T11:45:03.000Z",
    "createdAt": "2026-02-27T11:45:00.000Z"
  }
}
```

#### 3.3 查询会员状态
```http
GET /api/v1/membership/status
Authorization: Bearer <access_token>
```

**响应：**
```json
{
  "success": true,
  "data": {
    "tier": "premium",
    "status": "active",
    "startedAt": "2026-02-27T11:45:03.000Z",
    "expiresAt": "2026-03-29T11:45:03.000Z",
    "autoRenew": false,
    "monthlyAmount": 100
  }
}
```

#### 3.4 微信支付回调（内部使用）
```http
POST /api/v1/payment/wechat/callback
Content-Type: application/json

{
  "orderId": "ORDER_1234567890_1234",
  "transactionId": "WX_TXN_123",
  "amount": 100,
  "status": "success",
  "paidAt": "2026-02-27T11:45:03.000Z"
}
```

#### 3.5 支付宝回调（内部使用）
```http
POST /api/v1/payment/alipay/callback
Content-Type: application/json

{
  "orderId": "ORDER_1234567890_1234",
  "transactionId": "ALIPAY_TXN_123",
  "amount": 100,
  "status": "success",
  "paidAt": "2026-02-27T11:45:03.000Z"
}
```

## 配置说明

### 环境变量

在 `.env` 文件中配置：

```bash
# Mock 模式（开发/测试环境）
PAYMENT_MOCK_MODE=true

# 真实支付模式（生产环境）
# PAYMENT_MOCK_MODE=false
# YUNGOUOS_MCH_ID=your-merchant-id
# YUNGOUOS_PAY_KEY=your-pay-key
# YUNGOUOS_APP_ID=your-app-id
# YUNGOUOS_NOTIFY_URL=https://your-domain.com/api/v1/payment/callback
```

### Flutter 客户端配置

在 `app_config.dart` 中：

```dart
class AppConfig {
  /// 是否启用测试模式
  /// - true：使用 TestAuthRepository（内存模拟，无需网络）
  /// - false：使用 SupabaseAuthRepository（当前）或 CustomServerAuthRepository（Phase 1.9 后）
  static const bool enableTestMode = false;
}
```

**注意：** 
- 客户端的 `enableTestMode` 控制认证模式（测试认证 vs 真实认证）
- 服务端的 `PAYMENT_MOCK_MODE` 控制支付模式（Mock 支付 vs 真实支付）
- 两者独立配置，互不影响

**项目迁移状态**：
```
当前：Supabase（认证） + 自建服务器开发中（Phase 1.1-1.7）
Phase 1.9：切换到自建服务器（创建 CustomServerAuthRepository）
```

## Mock 模式工作流程

1. **创建订单**：调用 `/api/v1/payment/create`，返回订单信息
2. **自动支付**：Mock 模式下，3 秒后自动模拟支付成功
3. **激活会员**：支付成功后，自动激活 30 天会员
4. **查询状态**：客户端轮询 `/api/v1/payment/status/:orderId` 检查支付状态

## 架构设计

### 分层架构
```
DTO → Repository → Service → Controller → Routes
```

### 依赖注入
所有服务通过 DI 容器管理，便于测试和替换实现。

### 接口抽象
- `IPaymentService`：支付服务接口
- `IPaymentOrderRepository`：支付订单数据访问接口
- `IMembershipRepository`：会员数据访问接口

### 代码质量
- ✅ 遵循 SOLID 原则
- ✅ DRY（无重复代码）
- ✅ KISS（保持简单）
- ✅ YAGNI（只实现需要的功能）
- ✅ Fail Fast（尽早失败）
- ✅ 关注点分离
- ✅ 依赖注入
- ✅ 单元测试覆盖率 100%

## 测试

运行支付服务测试：
```bash
npm test -- paymentService.test.ts
```

运行所有测试：
```bash
npm test
```

**测试结果：**
- ✅ 10/10 支付服务测试通过
- ✅ 49/49 总测试通过

## 切换到真实支付

当 APP 开发完成并获得 YunGouOS 商户账号后：

1. 更新 `.env` 配置：
```bash
PAYMENT_MOCK_MODE=false
YUNGOUOS_MCH_ID=your-merchant-id
YUNGOUOS_PAY_KEY=your-pay-key
YUNGOUOS_APP_ID=your-app-id
YUNGOUOS_NOTIFY_URL=https://your-domain.com/api/v1/payment/callback
```

2. 实现 `createRealPayment` 方法（在 `paymentService.ts` 中）：
```typescript
private async createRealPayment(...) {
  // 集成 YunGouOS SDK
  const yungouos = new YunGouOS(config.payment.yungouos);
  const result = await yungouos.createPayment({ ... });
  return result;
}
```

3. 实现签名验证（在回调处理中）：
```typescript
// 验证微信支付签名
if (!this.verifyWechatSignature(data)) {
  throw new AppError('Invalid signature', ErrorCode.INVALID_SIGNATURE);
}
```

## 文件清单

### 新增文件
- `src/types/payment.dto.ts` - 支付相关 DTO
- `src/repositories/paymentOrderRepository.ts` - 支付订单 Repository
- `src/repositories/membershipRepository.ts` - 会员 Repository
- `src/services/paymentService.ts` - 支付服务
- `src/controllers/paymentController.ts` - 支付控制器
- `src/routes/payment.routes.ts` - 支付路由
- `src/validators/payment.validator.ts` - 支付验证器
- `tests/unit/services/paymentService.test.ts` - 支付服务测试

### 修改文件
- `src/config/index.ts` - 添加支付配置
- `src/config/container.ts` - 注册支付服务
- `src/routes/index.ts` - 注册支付路由
- `.env.example` - 添加支付配置示例

## 下一步

- [ ] Phase 1.8: 用户相关 API（3 个端点）
- [ ] Phase 1.9: Flutter 客户端适配
- [ ] 未来：申请 YunGouOS 商户账号
- [ ] 未来：替换 Mock 支付为真实支付

---

**版本：** v1.0  
**完成时间：** 2026-02-27  
**状态：** ✅ 已完成

