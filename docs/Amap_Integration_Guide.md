# 高德地图 API 集成指南

## 概述

本项目使用**高德地图 Web 服务 API** 进行逆地理编码（GPS 坐标 → 地址）。

## 为什么使用高德地图？

1. **国内服务稳定**：高德地图在中国大陆地区服务稳定，响应速度快
2. **地址准确**：对中国地址的识别和格式化更准确
3. **免费额度充足**：个人开发者每日有充足的免费调用额度
4. **无需翻墙**：不受网络限制，Web 端也能正常使用

## 获取高德地图 API Key

### 步骤 1：注册账号

1. 访问高德开放平台：https://lbs.amap.com/
2. 点击右上角"注册"，使用手机号注册账号
3. 完成实名认证（个人开发者）

### 步骤 2：创建应用

1. 登录后，进入"控制台"：https://console.amap.com/
2. 点击左侧菜单"应用管理" → "我的应用"
3. 点击"创建新应用"
4. 填写应用信息：
   - 应用名称：`Serendipity`
   - 应用类型：选择"其他"

### 步骤 3：添加 Key

1. 在应用列表中，找到刚创建的应用
2. 点击"添加 Key"
3. 填写 Key 信息：
   - Key 名称：`Web 服务`
   - 服务平台：选择 **"Web 服务"**（重要！）
   - 其他选项保持默认
4. 点击"提交"
5. 复制生成的 Key（格式类似：`a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`）

### 步骤 4：配置到项目

1. 打开文件：`lib/core/config/amap_config.dart`
2. 找到 `apiKey` 字段
3. 将复制的 Key 粘贴进去：

```dart
static const String apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

4. 保存文件

## 安全建议

### 1. 不要将 API Key 提交到公开仓库

在 `.gitignore` 中添加：

```
# 高德地图配置（包含 API Key）
lib/core/config/amap_config.dart
```

### 2. 设置 IP 白名单（可选）

1. 进入高德控制台
2. 找到你的 Key，点击"设置"
3. 在"IP 白名单"中添加服务器 IP
4. 这样只有指定 IP 才能使用此 Key

### 3. 监控使用量

1. 在高德控制台查看"数据统计"
2. 监控每日调用量，避免超出免费额度
3. 免费额度：
   - 个人开发者：每日 30 万次
   - 企业开发者：每日 100 万次

## API 调用说明

### 逆地理编码 API

**接口地址**：`https://restapi.amap.com/v3/geocode/regeo`

**请求参数**：
- `key`：API Key
- `location`：经度,纬度（注意顺序）
- `output`：返回格式（json）

**返回示例**：

```json
{
  "status": "1",
  "info": "OK",
  "regeocode": {
    "formatted_address": "北京市朝阳区建国门外大街1号",
    "addressComponent": {
      "province": "北京市",
      "city": [],
      "district": "朝阳区",
      "township": "建外街道",
      "street": "建国门外大街",
      "streetNumber": "1号"
    }
  }
}
```

### 代码实现

逆地理编码的实现位于：`lib/core/services/geolocator_location_service.dart`

核心方法：`_getAddressFromAmap()`

```dart
Future<String> _getAddressFromAmap(double latitude, double longitude) async {
  // 1. 检查 API Key 是否已配置
  if (!AmapConfig.isConfigured) {
    throw Exception('高德地图 API Key 未配置');
  }
  
  // 2. 构建请求 URL
  final url = Uri.parse(AmapConfig.geocoderUrl).replace(queryParameters: {
    'key': AmapConfig.apiKey,
    'location': '$longitude,$latitude', // 注意：经度在前
    'output': 'json',
  });
  
  // 3. 发送 HTTP 请求
  final response = await http.get(url).timeout(
    Duration(seconds: AmapConfig.timeoutSeconds),
  );
  
  // 4. 解析响应
  final data = json.decode(response.body);
  
  // 5. 提取地址
  return data['regeocode']['formatted_address'];
}
```

## 测试

### 测试逆地理编码

1. 运行应用
2. 进入"设置" → "GPS 定位测试"
3. 点击"获取当前位置"
4. 查看是否显示地址

### 预期结果

- ✅ 显示格式化地址（如"北京市朝阳区建国门外大街1号"）
- ✅ 地址为中文
- ✅ 响应速度快（< 2 秒）

### 常见问题

#### 1. 显示"高德地图 API Key 未配置"

**原因**：未在 `amap_config.dart` 中配置 API Key

**解决**：按照上述步骤获取并配置 API Key

#### 2. 显示"逆地理编码失败：INVALID_USER_KEY"

**原因**：API Key 无效或已过期

**解决**：
1. 检查 Key 是否复制完整
2. 检查 Key 类型是否为"Web 服务"
3. 在高德控制台检查 Key 状态

#### 3. 显示"逆地理编码失败：DAILY_QUERY_OVER_LIMIT"

**原因**：超出每日免费额度

**解决**：
1. 等待第二天重置
2. 或升级为付费版本

#### 4. Web 端无法获取地址

**原因**：浏览器跨域限制

**解决**：
- 高德地图 Web 服务 API 支持跨域，无需额外配置
- 如果仍有问题，检查浏览器控制台的错误信息

## 与 geocoding 插件的对比

| 特性 | geocoding 插件 | 高德地图 API |
|------|---------------|-------------|
| 服务提供商 | Google | 高德 |
| 国内稳定性 | ❌ 需要翻墙 | ✅ 稳定 |
| 地址准确性 | ⚠️ 中国地址不准 | ✅ 准确 |
| Web 端支持 | ✅ 支持 | ✅ 支持 |
| 免费额度 | 有限 | 充足 |
| 配置复杂度 | 简单 | 需要申请 Key |

## 参考资料

- 高德开放平台：https://lbs.amap.com/
- 逆地理编码 API 文档：https://lbs.amap.com/api/webservice/guide/api/georegeo
- 控制台：https://console.amap.com/

---

**最后更新**：2026-02-21  
**文档版本**：v1.0

