# Firebase 用户认证系统实现追踪

**任务名称**：用户认证系统 + Firebase 集成  
**开始时间**：2026-02-18  
**预计完成时间**：3 天  
**当前状态**：⏳ 准备中

---

## 📋 任务概述

根据 `Serendipity_Spec.md` 产品规格要求，实现完整的用户认证系统和 Firebase 云同步功能。

### 核心目标
1. ✅ Firebase 项目配置和初始化
2. ✅ 用户登录/注册功能（邮箱、手机号）
3. ❌ 第三方登录（Apple ID、Google）- 已移除
4. ✅ 用户状态管理（Riverpod）
5. ✅ Firestore 数据同步
6. ✅ 路由守卫（未登录跳转）

### 质量标准
严格遵循 `Code_Quality_Review.md` 中的 12 个检查标准：
- ✅ 架构设计原则（SRP、DIP、高内聚低耦合）
- ✅ 分层约束（UI/状态管理/数据层分离）
- ✅ 状态管理规则（单一数据源）
- ✅ Fail Fast 原则
- ✅ Build 方法规范
- ✅ 异步与生命周期规范
- ✅ DRY / KISS / YAGNI
- ✅ 代码健康检查
- ✅ 性能检查
- ✅ 命名与一致性
- ✅ Flutter 特有最佳实践
- ✅ 终极原则（用户体验优先）

---

## 🎯 开发阶段

### Phase 1: Firebase 基础配置（第1天）

#### 1.1 添加 Firebase 依赖
- [x] 更新 `pubspec.yaml`
  - [x] 添加 `firebase_core: ^3.15.2`
  - [x] 添加 `firebase_auth: ^5.7.0`
  - [x] 添加 `cloud_firestore: ^5.6.12`
  - [x] 添加 `go_router: ^14.8.1`
  - [x] 运行 `flutter pub get` ✅

#### 1.2 创建数据源接口（Repository Pattern）
- [x] 创建 `lib/core/repositories/i_auth_repository.dart` ✅
  - [x] 定义认证接口（遵循 DIP 原则）
  - [x] 8 个方法：signInWithEmail、signUpWithEmail、signInWithPhone、signUpWithPhone、sendPhoneVerificationCode、signOut、resetPassword、authStateChanges
  - [x] ~~signInWithApple、signInWithGoogle~~ ❌ 已移除
  - [x] 每个方法都有详细的调用者说明和 Fail Fast 验证
  - [x] 与具体实现（Firebase/自建服务器）解耦
  - [x] 无死代码（所有方法都有明确的调用者）

- [x] 创建 `lib/core/repositories/i_remote_data_repository.dart` ✅
  - [x] 定义远程数据接口
  - [x] 8 个方法：uploadRecord、uploadRecords、downloadRecords、deleteRecord、uploadStoryLine、uploadStoryLines、downloadStoryLines、deleteStoryLine
  - [x] 每个方法都有详细的调用者说明和 Fail Fast 验证
  - [x] 与具体实现解耦
  - [x] 无死代码（所有方法都有明确的调用者）

#### 1.3 创建 Firebase 实现（可替换）
- [x] 创建 `lib/core/services/firebase_service.dart` ✅
  - [x] Firebase 初始化逻辑
  - [x] 单例模式
  - [x] Fail Fast 验证（未初始化立即抛异常）
  - [x] 2 个方法：initialize、isInitialized
  - [x] 无死代码

- [x] 创建 `lib/core/repositories/firebase_auth_repository.dart` ✅
  - [x] 实现 IAuthRepository 接口
  - [x] 邮箱登录/注册（signInWithEmail、signUpWithEmail）
  - [x] 手机号登录/注册（signInWithPhone、signUpWithPhone、sendPhoneVerificationCode）
  - [x] ~~第三方登录（signInWithApple、signInWithGoogle）~~ ❌ 已移除
  - [x] 密码重置（resetPassword）
  - [x] 用户状态监听（authStateChanges、currentUser）
  - [x] 遵循 SRP 原则
  - [x] 严格的 Fail Fast 验证（邮箱格式、密码长度、手机号格式）
  - [x] 5 个私有辅助方法，全部有明确调用者
  - [x] 友好的错误信息处理
  - [x] **可替换为自建服务器实现**

- [x] 创建 `lib/core/repositories/firebase_remote_data_repository.dart` ✅
  - [x] 实现 IRemoteDataRepository 接口
  - [x] 记录操作（uploadRecord、uploadRecords、downloadRecords、deleteRecord）
  - [x] 故事线操作（uploadStoryLine、uploadStoryLines、downloadStoryLines、deleteStoryLine）
  - [x] 使用 Firestore 批量写入优化性能
  - [x] 遵循 SRP 原则
  - [x] 严格的 Fail Fast 验证（userId、recordId、storyLineId）
  - [x] 2 个私有辅助方法，全部有明确调用者
  - [x] **可替换为自建服务器实现**

#### 1.4 更新主入口
- [x] 更新 `lib/main.dart` ✅
  - [x] 添加 Firebase 初始化（调用 FirebaseService.initialize()）
  - [x] 错误处理（Fail Fast：初始化失败显示友好错误页面）
  - [x] 保持代码简洁（不添加未来才需要的路由配置）
  - [x] 遵循用户体验优先原则（友好的错误提示）

---

### Phase 2: 用户认证 UI（第2天）

#### 2.1 创建路由配置
- [x] 创建 `lib/core/router/route_names.dart` ✅
  - [x] 定义路由名称常量
  - [x] 8 个路由常量：welcome、login、register、forgotPassword、home、createRecord、recordDetail、storyLineDetail
  - [x] 2 个辅助方法：recordDetailPath、storyLineDetailPath
  - [x] 每个常量都有详细的调用者说明
  - [x] 遵循命名规范
  - [x] 无死代码（不添加未来才需要的路由）

- [x] 创建 `lib/core/router/app_router.dart` ✅
  - [x] go_router 配置
  - [x] 路由表定义（4 个当前路由：home、createRecord、recordDetail、storyLineDetail）
  - [x] 集成 PageTransitionBuilder（自定义页面过渡动画）
  - [x] 错误页面处理（Fail Fast：路由不存在显示友好错误）
  - [x] 参数验证（Fail Fast：recordId、storyLineId 缺失显示错误）
  - [x] 路由守卫预留（TODO：Phase 3 实现认证检查）
  - [x] 认证路由预留（TODO：Phase 2.2 添加）
  - [x] 遵循 YAGNI 原则（不添加未来才需要的功能）

- [x] 更新 `lib/main.dart` ✅
  - [x] 从 MaterialApp 切换到 MaterialApp.router
  - [x] 集成 go_router
  - [x] 移除硬编码的 home 参数

#### 2.2 创建通用认证组件
- [x] 创建 `lib/features/auth/widgets/auth_text_field.dart` ✅
  - [x] 统一的输入框样式
  - [x] 5 种输入类型：email、password、phone、verificationCode、text
  - [x] 邮箱/密码/手机号/验证码验证
  - [x] 密码可见性切换
  - [x] 使用 const 优化
  - [x] 遵循 Flutter 最佳实践
  - [x] 严格的 Fail Fast 验证（邮箱格式、密码长度、手机号格式、验证码长度）
  - [x] 7 个私有方法，全部有明确调用者
  - [x] 无死代码（不添加多行文本、数字输入等认证页面不需要的功能）

- [x] 创建 `lib/features/auth/widgets/auth_button.dart` ✅
  - [x] 统一的按钮样式
  - [x] 2 种按钮类型：primary（填充背景）、secondary（边框样式）
  - [x] 加载状态显示（CircularProgressIndicator）
  - [x] 禁用状态处理（Fail Fast：加载时自动禁用）
  - [x] 支持前缀图标
  - [x] 使用 const 优化
  - [x] 2 个快捷构造函数：AuthButton.primary()、AuthButton.secondary()
  - [x] 4 个私有方法，全部有明确调用者
  - [x] 无死代码（不添加图标按钮、浮动按钮等认证页面不需要的功能）

#### 2.3 创建认证页面
- [x] 创建 `lib/features/auth/welcome_page.dart` ✅
  - [x] 欢迎页 UI（Logo、Slogan、登录/注册按钮）
  - [x] 登录/注册入口（使用 Navigator.push + PageRouteBuilder）
  - [x] 遵循分层约束（UI 层不写业务逻辑）
  - [x] 3 个私有方法，全部有明确调用者
  - [x] 无死代码（不添加跳过按钮、引导页轮播）

- [x] 创建 `lib/features/auth/login_page.dart` ✅
  - [x] 邮箱登录 UI（邮箱、密码输入框）
  - [x] 手机号登录 UI（手机号、验证码输入框）
  - [x] 登录方式切换标签（邮箱/手机号）
  - [x] ~~第三方登录按钮（Apple、Google）~~ ❌ 已移除
  - [x] 表单验证（使用 AuthTextField 自动验证）
  - [x] 错误提示（使用 MessageHelper）
  - [x] 忘记密码链接（跳转到 ForgotPasswordPage）
  - [x] 注册链接（跳转到 RegisterPage）
  - [x] 登录成功跳转到 MainNavigationPage
  - [x] 使用 Navigator.push + PageRouteBuilder
  - [x] 9 个私有方法，全部有明确调用者
  - [x] 严格的 Fail Fast 验证
  - [x] 无死代码（不添加记住密码功能）

- [x] 创建 `lib/features/auth/register_page.dart` ✅
  - [x] 邮箱注册 UI（邮箱、密码、确认密码输入框）
  - [x] 手机号注册 UI（手机号、验证码输入框）
  - [x] 注册方式切换标签（邮箱/手机号）
  - [x] 密码确认验证（两次密码必须一致）
  - [x] 表单验证（使用 AuthTextField 自动验证）
  - [x] 错误提示（使用 MessageHelper）
  - [x] 登录链接（跳转到 LoginPage）
  - [x] 注册成功跳转到 MainNavigationPage
  - [x] 使用 Navigator.push + PageRouteBuilder
  - [x] 7 个私有方法，全部有明确调用者
  - [x] 严格的 Fail Fast 验证
  - [x] 无死代码

- [x] 创建 `lib/features/auth/forgot_password_page.dart` ✅
  - [x] 忘记密码 UI（邮箱输入框）
  - [x] 邮箱重置（调用 FirebaseAuthRepository.resetPassword）
  - [x] 成功提示（显示绿色提示框）
  - [x] 重新发送按钮
  - [x] 表单验证（使用 AuthTextField 自动验证）
  - [x] 错误提示（使用 MessageHelper）
  - [x] 3 个私有方法，全部有明确调用者
  - [x] 严格的 Fail Fast 验证
  - [x] 无死代码

---

### Phase 3: 状态管理 + 数据同步（第3天）

#### 3.1 创建状态管理
- [x] 创建 `lib/core/providers/auth_provider.dart` ✅
  - [x] 用户登录状态管理（StreamNotifier 监听认证状态变化）
  - [x] 使用 StreamNotifier（监听 IAuthRepository.authStateChanges）
  - [x] 单一数据源（遵循状态管理规则）
  - [x] 依赖抽象接口 IAuthRepository（遵循 DIP 原则）
  - [x] 7 个方法：signInWithEmail、signUpWithEmail、sendPhoneVerificationCode、signInWithPhone、signUpWithPhone、signOut、currentUser getter
  - [x] 严格的 Fail Fast 验证（所有参数验证）
  - [x] 异常处理（使用 AsyncValue.guard）
  - [x] 所有方法都有明确的调用者
  - [x] ~~Apple/Google 登录方法~~ ❌ 已移除

#### 3.2 创建数据同步服务（依赖接口，不依赖具体实现）
- [x] 创建 `lib/core/services/sync_service.dart` ✅
  - [x] 依赖 IRemoteDataRepository 接口（不依赖 Firebase）
  - [x] 依赖 IStorageService 接口（不依赖具体存储实现）
  - [x] 6 个方法：uploadRecord、uploadStoryLine、deleteRecord、deleteStoryLine、syncAllData、2个私有方法
  - [x] 本地数据上传到云端（uploadRecord、uploadStoryLine）
  - [x] 云端数据删除（deleteRecord、deleteStoryLine）
  - [x] 全量同步（syncAllData：上传本地数据 + 下载云端数据）
  - [x] 冲突处理（最后更新时间优先）
  - [x] 严格的 Fail Fast 验证（userId、recordId、storyLineId）
  - [x] 遵循 SRP 和 DIP 原则
  - [x] 所有方法都有明确的调用者
  - [x] 无死代码（不添加增量同步等复杂功能）
  - [x] **切换服务器时无需修改此文件**

#### 3.3 更新现有 Provider
- [x] 更新 `lib/core/providers/records_provider.dart` ✅
  - [x] 集成云端同步（依赖 SyncService 和 AuthProvider）
  - [x] saveRecord()：保存到本地 + 上传到云端（如果已登录）
  - [x] updateRecord()：更新本地 + 上传到云端（如果已登录）
  - [x] deleteRecord()：删除本地 + 删除云端（如果已登录）
  - [x] 支持离线模式（未登录时只操作本地）
  - [x] 云端同步失败不影响本地操作
  - [x] 保持向后兼容（不破坏现有功能）
  - [x] 遵循 Fail Fast 原则

- [x] 更新 `lib/core/providers/story_lines_provider.dart` ✅
  - [x] 集成云端同步（依赖 SyncService 和 AuthProvider）
  - [x] createStoryLine()：保存到本地 + 上传到云端（如果已登录）
  - [x] updateStoryLine()：更新本地 + 上传到云端（如果已登录）
  - [x] deleteStoryLine()：删除本地 + 删除云端（如果已登录）
  - [x] 支持离线模式（未登录时只操作本地）
  - [x] 云端同步失败不影响本地操作
  - [x] 保持向后兼容（不破坏现有功能）
  - [x] 遵循 Fail Fast 原则

#### 3.4 更新主导航
- [x] 更新 `lib/main.dart` ✅
  - [x] 集成认证状态监听（监听 authProvider）
  - [x] 自动登录检查（应用启动时）
  - [x] 未登录跳转到欢迎页（WelcomePage）
  - [x] 已登录跳转到主页（MainNavigationPage）
  - [x] 登录后自动触发全量同步（syncAllData）
  - [x] 支持离线模式（未登录也可以使用）
  - [x] 添加加载页面（_LoadingPage）
  - [x] 添加错误页面（_ErrorPage）
  - [x] 遵循 Build 方法规范（使用 Future.microtask 避免在 build 中调用异步）
  - [x] 遵循用户体验优先原则（同步失败不影响使用）

---

## 📁 文件清单

### 新建文件（17 个）

#### 仓库接口层（2 个）- 定义抽象，可切换实现
1. `lib/core/repositories/i_auth_repository.dart` - 认证接口
2. `lib/core/repositories/i_remote_data_repository.dart` - 远程数据接口

#### Firebase 实现层（3 个）- 可替换为自建服务器
3. `lib/core/services/firebase_service.dart` - Firebase 初始化
4. `lib/core/repositories/firebase_auth_repository.dart` - Firebase 认证实现
5. `lib/core/repositories/firebase_remote_data_repository.dart` - Firebase 数据实现

#### 业务逻辑层（1 个）- 依赖接口，不依赖具体实现
6. `lib/core/services/sync_service.dart` - 数据同步服务（依赖 IRemoteDataRepository 和 IStorageService）

#### 路由层（2 个）
7. `lib/core/router/route_names.dart` - 路由名称常量
8. `lib/core/router/app_router.dart` - 路由配置

#### 状态管理层（2 个）- 依赖接口，不依赖具体实现
9. `lib/core/providers/auth_provider.dart` - 用户状态管理（依赖 IAuthRepository）

##### UI 层（8 个）
10. `lib/features/auth/widgets/auth_text_field.dart` - 输入框组件
11. `lib/features/auth/widgets/auth_button.dart` - 按钮组件
12. `lib/features/auth/welcome_page.dart` - 欢迎页
13. `lib/features/auth/login_page.dart` - 登录页
14. `lib/features/auth/register_page.dart` - 注册页
15. `lib/features/auth/forgot_password_page.dart` - 忘记密码页

### 更新文件（4 个）
1. `serendipity_app/pubspec.yaml` - 添加 Firebase 依赖
2. `lib/main.dart` - 添加 Firebase 初始化
3. `lib/core/providers/records_provider.dart` - 集成云同步
4. `lib/core/providers/story_lines_provider.dart` - 集成云同步
5. `lib/features/home/main_navigation_page.dart` - 集成路由守卫

### 配置文件（需要手动配置，4 个）
1. `android/app/google-services.json` - Android Firebase 配置
2. `ios/Runner/GoogleService-Info.plist` - iOS Firebase 配置
3. `android/app/build.gradle` - Android 构建配置
4. `ios/Podfile` - iOS 依赖配置

**总计：25 个文件**

---

## 🏗️ 架构设计说明

### 仓库模式（Repository Pattern）架构

```
┌─────────────────────────────────────────────────────────┐
│                      UI 层（Pages）                      │
│  WelcomePage, LoginPage, RegisterPage, TimelinePage...  │
└────────────────────┬────────────────────────────────────┘
                     │ 依赖
                     ↓
┌─────────────────────────────────────────────────────────┐
│              状态管理层（Providers）                      │
│        AuthProvider, RecordsProvider, etc.              │
└────────────────────┬────────────────────────────────────┘
                     │ 依赖接口（不依赖具体实现）
                     ↓
┌─────────────────────────────────────────────────────────┐
│              仓库接口层（Interfaces）                     │
│      IAuthRepository, IRemoteDataRepository             │
└────────────────────┬────────────────────────────────────┘
                     │ 实现
                     ↓
┌─────────────────────────────────────────────────────────┐
│           具体实现层（可替换）                            │
│  ┌──────────────────────┐  ┌──────────────────────┐    │
│  │  Firebase 实现        │  │  自建服务器实现       │    │
│  │ FirebaseAuthRepo     │  │ CustomAuthRepo       │    │
│  │ FirebaseDataRepo     │  │ CustomDataRepo       │    │
│  └──────────────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 切换服务器的步骤

**当前使用 Firebase：**
```dart
// lib/core/providers/auth_provider.dart
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return FirebaseAuthRepository();  // ← 使用 Firebase 实现
});
```

**切换到自建服务器：**
```dart
// lib/core/providers/auth_provider.dart
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return CustomAuthRepository();  // ← 切换到自建服务器实现
});
```

**只需修改 1 行代码，其他代码无需改动！**

### 关键原则

1. **依赖倒置（DIP）**：
   - ✅ Provider 依赖 `IAuthRepository` 接口
   - ✅ SyncService 依赖 `IRemoteDataRepository` 接口
   - ❌ 不直接依赖 `FirebaseAuthRepository`

2. **单一职责（SRP）**：
   - `IAuthRepository` - 定义认证契约
   - `FirebaseAuthRepository` - Firebase 认证实现
   - `CustomAuthRepository` - 自建服务器认证实现（未来）
   - `AuthProvider` - 状态管理

3. **开闭原则（OCP）**：
   - 扩展：新增 `CustomAuthRepository` 实现
   - 不修改：现有的 Provider、UI 代码无需改动

### 示例代码

**接口定义：**
```dart
// lib/core/repositories/i_auth_repository.dart
abstract class IAuthRepository {
  Future<User> signInWithEmail(String email, String password);
  Future<User> signUpWithEmail(String email, String password);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}
```

**Firebase 实现：**
```dart
// lib/core/repositories/firebase_auth_repository.dart
class FirebaseAuthRepository implements IAuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapToUser(credential.user!);
  }
  // ... 其他方法
}
```

**自建服务器实现（未来）：**
```dart
// lib/core/repositories/custom_auth_repository.dart
class CustomAuthRepository implements IAuthRepository {
  final Dio _dio = Dio(baseUrl: 'https://your-server.com');
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return User.fromJson(response.data);
  }
  // ... 其他方法
}
```

**Provider 使用（无需修改）：**
```dart
// lib/core/providers/auth_provider.dart
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // 依赖接口，不依赖具体实现
    final repo = ref.watch(authRepositoryProvider);
    return repo.currentUser;
  }
  
  Future<void> signIn(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.signInWithEmail(email, password);
    state = AsyncValue.data(user);
  }
}
```

---

## ✅ 完成标准

### 功能完成标准
- [ ] 用户可以通过邮箱注册/登录
- [ ] 用户可以通过手机号注册/登录
- [ ] 用户可以重置密码
- [ ] 用户可以登出
- [ ] 未登录用户自动跳转到欢迎页
- [ ] 已登录用户自动跳转到主页
- [ ] 本地数据自动同步到云端
- [ ] 云端数据自动下载到本地

### 代码质量标准
- [ ] 所有文件遵循 12 个检查标准
- [ ] 无 linter 警告
- [ ] 无 deprecated API 使用
- [ ] 所有异步方法有异常处理
- [ ] 所有 setState 前有 mounted 检查
- [ ] 使用 const 优化性能
- [ ] 代码注释清晰
- [ ] 命名规范一致

### 测试标准
- [ ] 邮箱登录/注册流程测试通过
- [ ] 手机号登录/注册流程测试通过
- [ ] 密码重置流程测试通过
- [ ] 路由守卫测试通过
- [ ] 数据同步测试通过
- [ ] 错误处理测试通过

---

## 📊 进度追踪

### 当前进度
- **Phase 1**：✅ 4/4 完成（100%）
- **Phase 2**：✅ 2/2 完成（100%）
  - ❌ 2.1 创建路由配置（已取消 - 使用 Navigator）
  - ✅ 2.2 创建通用认证组件
  - ✅ 2.3 创建认证页面
- **Phase 3**：✅ 4/4 完成（100%）
  - ✅ 3.1 创建状态管理
  - ✅ 3.2 创建数据同步服务
  - ✅ 3.3 更新现有 Provider
  - ✅ 3.4 更新主导航
- **总体进度**：✅ 10/10 完成（100%）

### 完成时间
| 阶段 | 完成日期 |
|------|---------|
| Phase 1.1 | 2026-02-18 |
| Phase 1.2 | 2026-02-18 |
| Phase 1.3 | 2026-02-18 |
| Phase 1.4 | 2026-02-18 |
| **Phase 1 总计** | **2026-02-18** |
| Phase 2.2 | 2026-02-18 |
| Phase 2.3 | 2026-02-18 |
| **Phase 2 总计** | **2026-02-18** |
| Phase 3.1 | 2026-02-18 |
| Phase 3.2 | 2026-02-18 |
| Phase 3.3 | 2026-02-18 |
| Phase 3.4 | 2026-02-18 |
| **Phase 3 总计** | **2026-02-18** |

---

## 🎉 所有阶段已完成！

---

## 🐛 问题记录

### 遇到的问题
（暂无）

### 解决方案
（暂无）

---

## 📝 备注

### 重要提醒
1. 每完成一个文件，立即更新本文档
2. 遇到问题立即记录到"问题记录"部分
3. 严格遵循 12 个检查标准，不留技术债
4. 优先用户体验，其次代码优雅

### 参考文档
- `docs/Serendipity_Spec.md` - 产品规格
- `docs/Development_Roadmap.md` - 开发路线图
- `docs/Code_Quality_Review.md` - 代码质量标准
- `docs/开发清单_00_总览.md` - 开发清单

---

**最后更新时间**：2026-02-18  
**更新内容**：创建任务追踪文档


