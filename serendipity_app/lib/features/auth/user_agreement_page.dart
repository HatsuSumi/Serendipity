import 'package:flutter/material.dart';

/// 用户协议页面
/// 
/// 显示用户协议内容
/// 
/// 调用者：
/// - AgreementNotice：点击《用户协议》链接
class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

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
        title: const Text('用户协议'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('欢迎使用 Serendipity', style: titleStyle),
            Text(
              '感谢你选择 Serendipity（错过了么）。在开始使用之前，请花几分钟阅读这份协议。我尽量用人话写，不绕弯子。',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('1. 这是什么应用？', style: sectionTitleStyle),
            Text(
              'Serendipity 是一个情感记录应用，帮助你记录生活中那些错过的瞬间。你可以：\n'
              '记录错过的人和故事\n'
              '将多次记录关联成故事线\n'
              '匿名分享到社区（树洞）\n'
              '解锁成就，回顾统计',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('2. 你需要遵守的规则', style: sectionTitleStyle),
            Text(
              '为了让 Serendipity 保持纯粹和安全，请你：\n\n'
              '✅ 真实记录你的感受和经历\n'
              '✅ 尊重他人隐私，不要在描述中透露他人的详细个人信息\n'
              '✅ 保持友善和理性\n\n'
              '❌ 不要发布色情、暴力、政治敏感内容\n'
              '❌ 不要在记录或社区中留下联系方式（微信、QQ、手机号等）\n'
              '❌ 不要发布广告或垃圾信息',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('3. 关于内容审核', style: sectionTitleStyle),
            Text(
              'Serendipity 是一个人开发的项目，没有审核团队，也不做自动内容检测。\n\n'
              '我相信大部分用户都是善良的，会自觉遵守规则。\n\n'
              '但请理解：我无法保证所有内容都符合你的期待，也无法对用户发布的内容负责。',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('4. 会员与付费', style: sectionTitleStyle),
            Text(
              'Serendipity 采用"自愿付费"模式：\n\n'
              '免费版提供完整的核心功能\n'
              '会员版解锁更多高级功能（多设备同步、无限故事线、词云图等）\n'
              '你可以自己决定付费金额（¥0-648/月）\n'
              '即使选择 ¥0，也能解锁会员功能\n\n'
              '这是一个为爱发电的项目，你的支持会让它走得更远。',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('5. 账号管理', style: sectionTitleStyle),
            Text(
              '目前仅支持邮箱注册\n'
              '注册时会生成恢复密钥，请务必保存好\n'
              '如果忘记密码，需要使用恢复密钥重置\n'
              '请妥善保管你的账号密码和恢复密钥',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),

            Text('6. 免责声明', style: sectionTitleStyle),
            Text(
              'Serendipity 仅提供记录和分享平台，不对用户发布的内容负责\n'
              '我不保证服务永远可用（可能因维护、故障、时间、精力、成本和开发者抑郁症加重等原因中断）\n'
              '我不对因使用本应用导致的任何损失负责\n'
              '社区内容由用户自行发布，不代表开发者立场',
              style: bodyStyle,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

