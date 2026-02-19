# Firebase 配置指南

本文档提供 Serendipity 项目的 Firebase 配置步骤。

---

## 📋 前置准备

- Google 账号
- Flutter 开发环境
- Android Studio（用于 Android 配置）
- Xcode（用于 iOS 配置，仅 macOS）

---

## 🔥 步骤 1：创建 Firebase 项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击 **"添加项目"**
3. 输入项目名称：`Serendipity`（或其他名称）
4. 选择是否启用 Google Analytics（建议启用）
5. 点击 **"创建项目"**
6. 等待项目创建完成

---

## 📱 步骤 2：配置 Android 应用

### 2.1 添加 Android 应用

1. 在 Firebase 项目中，点击 **Android 图标**
2. 输入以下信息：
   - **Android 包名**：`com.serendipity.serendipity_app`
   - **应用昵称**（可选）：`Serendipity Android`
   - **调试签名证书 SHA-1**（可选，暂时跳过）
3. 点击 **"注册应用"**

### 2.2 下载配置文件

1. 下载 `google-services.json` 文件
2. 将文件放到项目的 `android/app/` 目录下

```
serendipity_app/
  android/
    app/
      google-services.json  ← 放在这里
      build.gradle.kts
```

### 2.3 验证配置

Android 配置文件已自动修改完成：
- ✅ `android/build.gradle.kts` - 已添加 Google Services 插件
- ✅ `android/app/build.gradle.kts` - 已应用插件

---

## 🍎 步骤 3：配置 iOS 应用

### 3.1 添加 iOS 应用

1. 在 Firebase 项目中，点击 **iOS 图标**
2. 输入以下信息：
   - **iOS 捆绑包 ID**：`com.serendipity.serendipityApp`
   - **应用昵称**（可选）：`Serendipity iOS`
   - **App Store ID**（可选，暂时跳过）
3. 点击 **"注册应用"**

### 3.2 下载配置文件

1. 下载 `GoogleService-Info.plist` 文件
2. 将文件放到项目的 `ios/Runner/` 目录下

```
serendipity_app/
  ios/
    Runner/
      GoogleService-Info.plist  ← 放在这里
      Info.plist
```

### 3.3 配置 Xcode（可选）

如果需要在 iOS 上运行：
1. 打开 `ios/Runner.xcworkspace`（不是 `.xcodeproj`）
2. 在 Xcode 中，将 `GoogleService-Info.plist` 拖到 `Runner` 目录
3. 确保 **"Copy items if needed"** 被勾选

---

## 🌐 步骤 4：配置 Web 应用（可选）

### 4.1 添加 Web 应用

1. 在 Firebase 项目中，点击 **Web 图标**（`</>`）
2. 输入应用昵称：`Serendipity Web`
3. 点击 **"注册应用"**

### 4.2 复制配置代码

复制 Firebase 提供的配置代码，类似：

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef"
};
```

### 4.3 更新 Web 配置

编辑 `web/index.html`，在 `<body>` 标签前添加：

```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
<script>
  const firebaseConfig = {
    // 粘贴你的配置
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

---

## 🔐 步骤 5：启用 Firebase 服务

### 5.1 启用 Authentication

1. 在 Firebase Console 左侧菜单，点击 **"Authentication"**
2. 点击 **"开始使用"**
3. 在 **"Sign-in method"** 标签页，启用以下登录方式：
   - ✅ **电子邮件/密码**：点击启用
   - ✅ **电话**：点击启用（需要配置）

### 5.2 启用 Firestore Database

1. 在 Firebase Console 左侧菜单，点击 **"Firestore Database"**
2. 点击 **"创建数据库"**
3. 选择 **"以测试模式启动"**（开发阶段）
4. 选择数据库位置（建议选择离用户最近的区域）
5. 点击 **"启用"**

### 5.3 配置 Firestore 安全规则（重要！）

在 Firestore 的 **"规则"** 标签页，替换为以下规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## ✅ 步骤 6：验证配置

### 6.1 运行应用

```bash
cd serendipity_app
flutter run
```

### 6.2 检查 Firebase 初始化

如果配置正确，应用应该正常启动并显示欢迎页。

如果看到 "Firebase 初始化失败" 错误：
- 检查 `google-services.json` 是否在正确位置
- 检查包名是否匹配
- 运行 `flutter clean` 后重新编译

---

## 🐛 常见问题

### 问题 1：找不到 google-services.json

**解决方案**：
- 确保文件在 `android/app/google-services.json`
- 文件名必须完全匹配（不能是 `google-services (1).json`）

### 问题 2：包名不匹配

**错误信息**：`No matching client found for package name`

**解决方案**：
- 检查 Firebase Console 中的包名是否为 `com.serendipity.serendipity_app`
- 检查 `android/app/build.gradle.kts` 中的 `applicationId`

### 问题 3：iOS 配置文件未找到

**解决方案**：
- 确保 `GoogleService-Info.plist` 在 `ios/Runner/` 目录
- 在 Xcode 中检查文件是否被正确添加到项目

### 问题 4：Web 应用无法初始化

**解决方案**：
- 检查 `web/index.html` 中的 Firebase 配置
- 确保 Firebase SDK 版本正确
- 检查浏览器控制台的错误信息

---

## 📚 下一步

配置完成后，你可以：

1. **测试邮箱登录**：
   - 运行应用
   - 点击"注册"
   - 使用邮箱和密码注册
   - 检查 Firebase Console 的 Authentication 页面

2. **测试数据同步**：
   - 登录后创建一条记录
   - 检查 Firestore Database 中是否有数据

3. **测试多设备同步**：
   - 在另一台设备登录同一账号
   - 检查数据是否同步

---

## 🔗 参考链接

- [Firebase 官方文档](https://firebase.google.com/docs)
- [FlutterFire 文档](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

---

**配置完成时间**：2026-02-18  
**项目包名**：`com.serendipity.serendipity_app`

