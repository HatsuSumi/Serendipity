import 'package:flutter/material.dart';

/// 隐私协议页面
/// 
/// 显示隐私协议内容
/// 
/// 调用者：
/// - AgreementNotice：点击《隐私协议》链接
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
      height: 2,
    );
    final sectionTitleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
      height: 2,
    );
    final bodyStyle = TextStyle(
      fontSize: 14,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      height: 1.8,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私协议'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('我如何保护你的隐私', style: titleStyle),
            Text(
              '隐私对我很重要。这份协议会告诉你，我收集了哪些信息、如何使用、如何保护。',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('1. 我收集哪些信息？', style: sectionTitleStyle),
            Text(
              '为了提供服务，我会收集以下信息：\n\n'
              '📧 账号信息\n'
              '邮箱地址（用于登录）\n'
              '密码（加密存储）\n\n'
              '📍 位置信息\n'
              'GPS 坐标（创建记录时获取）\n'
              '地址信息（通过高德地图 API 获取）\n\n'
              '📝 记录内容\n'
              '你创建的记录（时间、地点、描述、标签等）\n'
              '故事线信息\n'
              '签到记录\n'
              '发布到社区的内容\n\n'
              '⚙️ 使用数据\n'
              '应用设置（主题、动画偏好等）\n'
              '成就解锁记录\n'
              '会员状态',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('2. 我如何使用这些信息？', style: sectionTitleStyle),
            Text(
              '我收集信息的唯一目的是提供服务：\n\n'
              '✅ 账号信息：用于登录验证\n'
              '✅ 位置信息：在地图上显示记录、统计常去地点\n'
              '✅ 记录内容：保存你的记录，支持云同步\n'
              '✅ 使用数据：提供个性化体验\n\n'
              '❌ 我不会：\n'
              '将你的信息出售给第三方\n'
              '用你的信息投放广告\n'
              '在未经你同意的情况下公开你的信息',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('3. 数据存储在哪里？', style: sectionTitleStyle),
            Text(
              '数据存储在两个地方：\n\n'
              '📱 本地存储\n'
              '使用 Hive 数据库存储在你的设备上\n'
              '即使没有网络也能正常使用\n\n'
              '☁️ 云端存储\n'
              '登录后数据会自动同步到服务器\n'
              '支持多设备访问（会员功能）\n'
              '服务器架构：Node.js + PostgreSQL\n\n'
              '🔒 安全措施\n'
              '密码使用行业标准加密算法\n'
              'HTTPS 传输加密\n'
              'JWT Token 认证',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('4. 社区发布的隐私保护', style: sectionTitleStyle),
            Text(
              '当你将记录发布到社区（树洞）时：\n\n'
              '✅ 完全匿名\n'
              '不显示你的用户名、头像、任何身份信息\n'
              '其他用户无法知道是谁发布的\n\n'
              '✅ 位置脱敏\n'
              '不显示精确 GPS 坐标\n'
              '只显示地址或地点名称\n\n'
              '⚠️ 请注意\n'
              '不要在描述中透露你的个人信息\n'
              '不要留下联系方式\n'
              '发布前会有提示，请仔细阅读',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('5. 第三方服务', style: sectionTitleStyle),
            Text(
              'Serendipity 使用以下第三方服务：\n\n'
              '🗺️ 高德地图 API\n'
              '用途：GPS 定位、地址解析、地图显示\n'
              '隐私政策：https://lbs.amap.com/home/privacy/',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('6. 你的权利', style: sectionTitleStyle),
            Text(
              '你对自己的数据拥有完全控制权：\n\n'
              '🗑️ 删除数据\n'
              '你可以删除单条记录或整个故事线\n'
              '删除后无法恢复\n\n'
              '📱 卸载应用\n'
              '卸载应用后，所有本地数据将被清除',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('7. 未成年人保护', style: sectionTitleStyle),
            Text(
              'Serendipity 面向 18 岁以上用户。如果你未满 18 岁，请在监护人同意和指导下使用。',
              style: bodyStyle,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

