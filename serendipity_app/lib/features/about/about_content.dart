import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class AboutSectionContent {
  final String title;
  final List<String> paragraphs;

  const AboutSectionContent({required this.title, required this.paragraphs})
    : assert(title != '');
}

class AboutPageSectionsResult {
  final List<AboutSectionContent> sections;
  final bool hasProjectStatsError;

  const AboutPageSectionsResult({
    required this.sections,
    required this.hasProjectStatsError,
  });
}

class ProjectStatsEntry {
  final String key;
  final String label;
  final int count;
  final double? percentage;

  const ProjectStatsEntry({
    required this.key,
    required this.label,
    required this.count,
    this.percentage,
  });

  factory ProjectStatsEntry.fromJson(Map<String, dynamic> json) {
    return ProjectStatsEntry(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      count: (json['count'] as num? ?? 0).toInt(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }
}

class ProjectStatsData {
  final String generatedAt;
  final int allFiles;
  final int codeFiles;
  final int codeLines;
  final int codeChars;
  final int assetFiles;
  final int assetBytes;
  final List<ProjectStatsEntry> fileCounts;
  final List<ProjectStatsEntry> codeLinesBreakdown;
  final List<ProjectStatsEntry> codeCharsBreakdown;

  const ProjectStatsData({
    required this.generatedAt,
    required this.allFiles,
    required this.codeFiles,
    required this.codeLines,
    required this.codeChars,
    required this.assetFiles,
    required this.assetBytes,
    required this.fileCounts,
    required this.codeLinesBreakdown,
    required this.codeCharsBreakdown,
  });

  factory ProjectStatsData.fromJson(Map<String, dynamic> json) {
    final totals =
        (json['totals'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    List<ProjectStatsEntry> parseEntries(String key) {
      final raw = (json[key] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map(
            (item) => ProjectStatsEntry.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false);
    }

    return ProjectStatsData(
      generatedAt: json['generated_at'] as String? ?? '',
      allFiles: (totals['all_files'] as num? ?? 0).toInt(),
      codeFiles: (totals['code_files'] as num? ?? 0).toInt(),
      codeLines: (totals['code_lines'] as num? ?? 0).toInt(),
      codeChars: (totals['code_chars'] as num? ?? 0).toInt(),
      assetFiles: (totals['asset_files'] as num? ?? 0).toInt(),
      assetBytes: (totals['asset_bytes'] as num? ?? 0).toInt(),
      fileCounts: parseEntries('file_counts'),
      codeLinesBreakdown: parseEntries('code_lines'),
      codeCharsBreakdown: parseEntries('code_chars'),
    );
  }

  List<AboutSectionContent> toAboutSections() {
    return [
      AboutSectionContent(
        title: '项目规模（文件统计）',
        paragraphs: [
          '总文件数：${_formatInt(allFiles)} 个',
          ...fileCounts.map(
            (entry) => '${entry.label}：${_formatInt(entry.count)} 个',
          ),
        ],
      ),
      AboutSectionContent(
        title: '项目规模（代码统计）',
        paragraphs: [
          '代码总行数：${_formatInt(codeLines)} 行（不含空行、注释）',
          ...codeLinesBreakdown.map(
            (entry) =>
                '${entry.label}：${_formatInt(entry.count)} 行（${entry.percentage?.toStringAsFixed(1) ?? '0.0'}%）',
          ),
          '字符总数：${_formatInt(codeChars)} 字符（不含注释）',
          ...codeCharsBreakdown.map(
            (entry) =>
                '${entry.label}：${_formatInt(entry.count)} 字符（${entry.percentage?.toStringAsFixed(1) ?? '0.0'}%）',
          ),
        ],
      ),
    ];
  }
}

const List<AboutSectionContent> _staticAboutPageSections = [
  AboutSectionContent(
    title: '状态说明',
    paragraphs: [
      '这个 app 有七种状态，核心区别在于：有没有交流过。',
      '🌫️ 错过\n第一次看到，但没说话',
      '🙈 回避\n看到了，但刻意避开\n（不敢看、低头、转身）',
      '🌟 再遇\n又看到了，但还是没说话\n（命运的第二次机会）',
      '💫 邂逅\n终于说话了！\n（第一次真正的见面）',
      '💝 重逢\n分开后再次相遇\n（需先经历别离）',
      '🥀 别离\n主动结束了\n（分手、好聚好散）',
      '🍂 失联\n被动消失，再也没见过',
      '简单来说：\n没说过话 → 错过/回避/再遇\n说过话了 → 邂逅\n分开后又遇 → 重逢\n主动结束 → 别离\n被动消失 → 失联',
    ],
  ),
  AboutSectionContent(
    title: '如何记录多次见面？',
    paragraphs: [
      '每次见面 = 一条新记录。',
      '例如：\n2月8日在地铁看到 TA\n  → 创建记录1，状态“错过”\n\n2月9日又看到 TA\n  → 创建记录2，状态“再遇”\n\n2月10日又看到 TA，但还是没说话\n  → 创建记录3，状态“再遇”\n\n2月11日终于说话了\n  → 创建记录4，状态“邂逅”\n\n2月15日分手了\n  → 创建记录5，状态“别离”\n\n3月1日又遇到了\n  → 创建记录6，状态“重逢”',
      '然后通过“故事线”功能，把这6条记录关联起来，形成完整的时间线。',
      '一直不说话，就一直选择“再遇”。',
      '不要在旧记录上修改状态！“更改状态”功能只是用来修正手滑点错的情况。',
    ],
  ),
  AboutSectionContent(
    title: '设计理念',
    paragraphs: [
      '这个 app 的侧重点是帮助你记录错过的瞬间，而不是邂逅或重逢。',
      '邂逅后如果继续在一起，就不需要再记录了，因为已经不是“错过”，而是“拥有”。',
      '只有分开了（别离/失联），才又回到“错过”的状态。这时如果再次相遇，就是“重逢”。',
      '这个 app 的核心价值是：记录、回忆、接受遗憾。',
      '有些错过，注定只能被记住。',
    ],
  ),
  AboutSectionContent(
    title: '技术栈',
    paragraphs: [
      'Flutter 3.x + Dart 3.x（SDK ^3.10.8）',
      'Riverpod 2.x（状态管理）',
      'Hive 2.x（本地存储，TypeAdapter 模式）',
      'Node.js 20 LTS + Express 5.x + TypeScript 5.x',
      'PostgreSQL 15 + Prisma ORM',
      'JWT（Access Token + Refresh Token 双 Token 机制）',
      '高德地图 API（逆地理编码）',
    ],
  ),
  AboutSectionContent(
    title: '项目说明',
    paragraphs: [
      '这是一个由一人耗时XX天，在孤独和抑郁的陪伴下完成开发的开源免费项目。',
      '一人包揽产品设计、前端开发、后端开发、架构设计、数据库设计、接口设计、运维部署、测试、维护与文档编写。',
      'Github仓库：占位链接',
    ],
  ),
];

Future<AboutPageSectionsResult> loadAboutPageSections() async {
  try {
    final rawJson = await rootBundle.loadString('assets/data/project_stats.json');
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final stats = ProjectStatsData.fromJson(decoded);

    return AboutPageSectionsResult(
      sections: List<AboutSectionContent>.unmodifiable([
      ..._staticAboutPageSections,
      ...stats.toAboutSections(),
      ]),
      hasProjectStatsError: false,
    );
  } catch (_) {
    return const AboutPageSectionsResult(
      sections: _staticAboutPageSections,
      hasProjectStatsError: true,
    );
  }
}

final List<AboutSectionContent> designDecisionSections = List.unmodifiable([
  const AboutSectionContent(
    title: '为什么树洞不能互动？',
    paragraphs: [
      '这个 app 有一个“树洞”功能，你可以匿名发布你的错过。',
      '但树洞没有评论、点赞、也无法联系发布者。',
      '你可以在树洞中看到是否有别人记录了你。',
      '为什么要这么“残酷”？',
      '第一个原因：防骗。\n\n如果树洞可以互动，骗子会怎么做？\n\n1. 看到你的记录\n2. 假装就是那个人\n3. 主动联系你\n4. 骗取信任\n\n零互动 = 骗子无法联系你。',
      '第二个原因：这才是“错过”的本质。\n\n你发布到树洞后，也许 TA 会看到，也许 TA 会想‘这不是我吗？’，但你永远不会知道。\n\n这种“也许”的不确定性，才是最美的遗憾。\n\n双方都发布到树洞，但是双方都取不到联系。\n\n如果可以评论、点赞，那就不是“错过”了，而是“社交”。',
      '第三个原因：这个 app 叫“错过了么”，不是“邂逅了么/重逢了么/失去了么”。\n\n有些错过，注定只能是错过。\n\n但至少，我们记住了。\n\n这是一种「刀子美学」设计——但这就是错过的本质——有些遗憾，注定无法弥补。',
    ],
  ),
  const AboutSectionContent(
    title: '记录和社区帖子的关系',
    paragraphs: [
      '社区帖子可以理解为记录的“快照”状态。',
      '当你发布记录到社区时，会创建一个快照，包含以下字段：\n\n错过时间\n发布时间\n地址\n地点名称\n场所类型\n省市区\n描述\n标签\n状态',
      '不包含以下字段：\n\n精确GPS坐标\n情绪强度\n对话契机\n背景音乐\n天气\n“如果再遇”备忘',
      '发布后的规则：\n\n1. 不能直接修改\n   发布后只能删除，不能修改内容。\n\n2. 可以重新发布\n   修改本地记录后，可以重新发布，会替换旧帖子。\n\n3. 修改不显示的字段\n   如果你只修改了“情绪强度”、“天气”等不显示在社区的字段，系统不会提示你重新发布，因为社区内容没有变化。',
      '为什么这样设计？\n\n保持真实性\n发布的那一刻就是你当时的真实感受\n\n防止滥用\n不能修改可以防止发布后改成广告\n\n快照机制\n本地记录和社区帖子是独立的，互不影响',
    ],
  ),
  const AboutSectionContent(
    title: '为什么不提供举报功能？',
    paragraphs: [
      '这个 app 不提供举报功能。',
      '不是因为不在乎内容质量，而是因为现实。',
      '第一个原因：一人开发，处理不过来。\n\n举报功能需要人工审核，但这是一个人的项目，没有审核团队。\n\n如果做了举报功能，却无法及时处理，反而会让用户失望。',
      '第二个原因：举报功能容易被滥用。\n\n恶意举报会导致：\n正常内容被误判隐藏\n用户之间的恶意攻击\n申诉处理不过来\n\n没有足够的人力处理这些，不如不做。',
      '第三个原因：不做技术检测。\n\n这个 app 不对内容进行自动检测和过滤。\n\n原因：\n技术检测容易误判\n影响用户体验\n依赖用户自律\n\n发布到社区时会提醒用户不要包含隐私信息。\n\n社区本身是只读的，即使有联系方式，也无法直接联系。',
      '第四个原因：社区本身就是只读的。\n\n即使有不当内容，也无法骚扰到你。\n\n你可以选择不看。',
      '如果遇到不当内容怎么办？\n\n你可以：\n不点进社区页面\n通过邮件联系开发者\n  （但不保证及时处理）\n\n这不是完美的解决方案，但这是一个人能做到的最诚实的选择。',
    ],
  ),
  const AboutSectionContent(
    title: '为什么签到系统没有补签功能？',
    paragraphs: [
      '这个 app 有签到功能，但没有补签。',
      '为什么？',
      '第一个原因：补签功能很难设计。\n\n其他 app 的常见做法：\n\n积分兑换补签券\n  → 阅读漫画 X 分钟\n  → 观看广告 X 次\n  → 完成每日任务\n\n社交货币兑换补签券\n  → 点赞 XX 次\n  → 评论 XX 次\n  → 分享 XX 次\n\n但 Serendipity 没有这些：\n  漫画\n  广告\n  点赞\n  评论\n  分享\n\n这让补签功能的设计变得非常困难。',
      '第二个原因：补签会破坏签到的意义。\n\n签到的意义是什么？是每天的小仪式。\n\n如果可以补签，用户会想：\n“反正可以补，不急”\n\n这反而降低了每日签到的动力。',
      '第三个原因：符合产品调性。\n\n这个 app 叫“Serendipity”，核心是记录“错过”。\n\n签到也可以“错过”，这本身就是一种接受遗憾的态度。\n\n错过就错过吧，就像那些擦肩而过的缘分一样。\n\n有些遗憾，注定无法弥补。\n\n但至少，我们记住了。',
      '第四个原因：保持功能简洁。\n\n不做补签功能：\n规则简单明了\n代码保持简洁\n维护成本低\n避免滥用\n\n连续签到天数更有价值，因为它是真实的。',
      '如何避免忘记签到？\n\n你可以：\n开启签到提醒\n  （每天晚上 8 点）\n自定义提醒时间\n把签到当作睡前仪式\n\n但如果真的忘了，那就接受吧。\n\n这不是惩罚，而是提醒我们：\n有些事情，错过了就是错过了。',
    ],
  ),
  const AboutSectionContent(
    title: '为什么有时候登出时会看不到之前创建的记录/故事线？',
    paragraphs: [
      '这个 app 支持多账号，每个账号的数据是完全隔离的。',
      '数据归属规则：\n\n未登录时创建的数据归属于“首次登录的账号”。',
      '场景1：未登录 → 注册账号A\n\n1. 未登录时创建3条记录\n2. 注册账号A\n3. 自动绑定：3条记录归属账号A',
      '场景2：未登录 → 登录账号A → 登出 → 登录账号B\n\n1. 未登录时创建3条记录\n2. 登录账号A\n3. 自动绑定：3条记录归属账号A\n4. 登出（不会删除已归属账号A的数据，登出后数据不可见）\n5. 登录账号B\n6. 账号B看不到那3条记录（因为归属账号A）',
      '场景3：账号A登出后离线创建新数据\n\n1. 账号A登出\n2. 未登录时创建2条新记录\n3. 登录账号A\n4. 自动绑定：2条新记录归属账号A',
      '场景4：账号A登出后离线创建新数据，然后登录账号B\n\n1. 账号A登出\n2. 未登录时创建2条新记录\n3. 登录账号B（不是账号A）\n4. 自动绑定：2条新记录归属账号B',
      '核心原则：\n“谁先登录，\n 离线数据就归谁”',
      '为什么这样设计？\n\n第一个原因：支持离线使用。\n\n你可以在未登录时创建记录，登录后自动归属到你的账号。\n\n第二个原因：数据隔离更安全。\n\n每个账号只能看到自己的数据，不会混淆。\n\n第三个原因：符合直觉。\n\n你创建数据后登录，数据自然归属该账号。',
      '如何避免数据丢失？\n\n1. 创建数据后及时登录\n2. 不要频繁切换账号\n3. 记住哪些数据归属哪个账号',
      '如果找不到数据了？\n\n数据一定在某个账号里，尝试登录所有账号查看。',
      '注意：\n数据一旦绑定到账号，就无法在登出状态下查看。\n\n这不是 bug，而是多账号数据隔离的必然结果。',
    ],
  ),
  const AboutSectionContent(
    title: '为什么系统不会自动判断状态流转是否合理？',
    paragraphs: [
      '这个 app 不会自动检测你的状态流转是否“合理”。',
      '你可以选择一些不那么常规的状态顺序，例如先“别离”再“邂逅”。',
      '虽然一般来说大家不会这么记，但系统不会拦你。',
      '为什么这样设计？',
      '第一个原因：状态判断本来就很主观。\n\n同样是一段经历，有人会觉得那次算“再遇”，也有人会觉得那次已经算“邂逅”。\n\n系统很难替你判断什么才是“真实”的感受。',
      '第二个原因：强行校验反而容易误伤真实经历。\n\n现实中的关系和情绪，并不总是按教科书顺序发展。\n\n如果系统强制要求只能先错过、再再遇、再邂逅、再别离，就会把很多复杂而真实的经历排除掉。',
      '第三个原因：这个 app 更强调记录，而不是裁判。\n\n它的职责是帮你把当时的感受留下来，而不是替你宣布“这条记录合不合理”。\n\n所以设计上刻意保留了这种自由度。',
      '当然，这不代表推荐你随便乱记。\n\n大多数时候，按自己最诚实的理解去记录，才最有意义。',
    ],
  ),
  const AboutSectionContent(
    title: '“错过”一定要是随机相遇吗？点单说了话算邂逅吗？',
    paragraphs: [
      '这是个很有意思的产品哲学问题。',
      '从产品设计角度看，这个 app 里状态的定义更偏向“行为导向”，而不是“概率导向”。\n\n核心判断标准是：有没有交流过。\n\n而不是“这次相遇是否足够随机”。',
      '比如咖啡馆员工这种“固定刷新的 NPC”场景：\n\n每天见到但没有交流 → 错过\n某天终于主动说了话 → 邂逅\n后来又在别处碰到 → 再遇 或 重逢\n\n所以，这完全是这个 app 里很经典的一种故事线。',
      '因为遗憾感恰恰来自：明明每天都能见到，却始终没有开口。\n\n这种遗憾甚至比完全随机的一面之缘更浓烈。',
      '换句话说，随机性不是“错过”的必要条件，遗憾感才是。\n\n故事线功能存在的意义，也正是把这些一天天积累起来的错过串成一整段缘分。',
      '那点单说了话，算不算“邂逅”？',
      '从字面上看，点单当然也属于“说了话”。\n\n但这里有一个关键问题：你怎么定义那次交流。',
      '如果那只是一次纯粹的服务流程，例如“一杯拿铁”→“好的”，你自己也不觉得那一刻发生了什么变化，那继续记“再遇”会更诚实。',
      '如果你特意找了个话题，或者那次交流让你有了心跳加速的感觉，哪怕只是多说了一句“今天客人多啊”，那记“邂逅”完全成立。',
      '所以这个 app 的状态判断，本质上是主观感受驱动的，没有绝对客观标准。\n\n设计上就是刻意如此——同样是“说了一句话”，你自己最清楚，那一刻到底有没有什么不同。',
    ],
  ),
  const AboutSectionContent(
    title: '为什么不提供地图视图查看所有记录的点位？',
    paragraphs: [
      '这个 app 没有地图视图来展示所有记录的位置。',
      '为什么？',
      '第一个原因：高德地图 Flutter 插件与当前 Flutter 版本不兼容。\n\namap_flutter_map 和 amap_flutter_base 包使用了 Dart 2.x 时代的 hashValues() 方法，该方法在 Dart 3.x 中已被移除。\n\n所有版本的高德地图 Flutter 插件都未更新以支持 Dart 3.x，导致无法编译。',
      '第二个原因：替代方案已经足够。\n\n虽然没有地图视图，但你可以：\n\n1. 在创建记录时自动获取 GPS 定位\n2. 手动输入地点名称\n3. 使用地点历史记录快速选择\n4. 在编辑模式下重新定位或清除 GPS\n\n这些功能已经能够满足大多数用户的需求。',
      '第三个原因：一人开发的现实限制。\n\n等待高德地图插件更新遥遥无期，而且即使更新也不一定会支持 Dart 3.x。\n\n自己实现地图功能需要大量时间和精力，对于一人项目来说不现实。\n\n所以选择了接受这个技术限制，并提供了最优的替代方案。',
    ],
  ),
  const AboutSectionContent(
    title: '为什么“手机号/邮箱注册”都不支持发送验证码？',
    paragraphs: [
      '这个 app 目前的注册和登录流程，不提供短信验证码，也不提供邮箱验证码。',
      '为什么？',
      '第一个原因：验证码服务都依赖第三方通道。\n\n手机短信验证码需要接入短信服务商，通常还要求企业资质，个人开发者又很难申请到。\n\n邮箱验证码虽然门槛比短信低，但依然需要稳定的邮件发送服务、投递率维护和风控处理。',
      '第二个原因：持续成本和维护成本高。\n\n短信按条计费，邮件服务也不是零成本。\n\n更重要的是，验证码系统不是接上就结束了，还要处理：\n\n发送失败\n延迟到达\n频率限制\n恶意刷接口\n邮件进入垃圾箱\n\n对一人开发项目来说，这是一套长期维护负担。',
      '第三个原因：现阶段没有这个必要。\n\n对于这个 app 的使用场景，账号系统更需要的是简单、稳定、可维护，而不是为了“更完整”强行接入验证码体系。',
      '第四个原因：少一层验证码，不代表更不安全。\n\n安全不只取决于有没有验证码，还取决于整体认证设计、密码存储、接口限流、设备管理和数据隔离。\n\n所以现阶段选择的是：不做一个看起来完整、实际维护不起的验证码系统。\n\n先把真正核心的体验做稳定，比形式上的“支持验证码”更重要。',
    ],
  ),
  const AboutSectionContent(
    title: '统计页的标签词云图是怎么实现的？',
    paragraphs: [
      'Flutter 最常用的图表库 fl_chart 不提供词云图。',
      '所以这个词云图是从零手写的。',
      '核心算法：\n阿基米德螺旋碰撞检测\n布局引擎',
      '简单来说：\n\n1. 按词频降序排列，\n   高频词优先占据画布中心\n\n2. 每个词从中心出发，\n   沿螺旋线依次尝试候选坐标\n\n3. 每次候选都做碰撞检测（AABB），\n   找到第一个不重叠的位置就放置\n\n4. 用 TextPainter 精确测量每个词的渲染尺寸，避免重叠或空间浪费\n\n5. 25% 的词随机竖排，模拟真实词云的纵向穿插效果\n\n6. 颜色按词频在主色→辅色之间线性渐变',
      '感兴趣的话可以在 GitHub 上查看源代码：\n\ntag_cloud_card.dart\n(serendipity_app/lib/features/statistics/widgets/)',
    ],
  ),
  const AboutSectionContent(
    title: '既然技术栈用了 Flutter，为什么只做了 Android 和 iOS 呢？',
    paragraphs: [
      '因为这个 app 的核心场景是记录日常生活中擦肩而过的人。',
      '这种瞬间往往来得很快，你需要立刻掏出设备记下。',
      '而在这种场景里，掏出手机总是比掏出电脑更快。',
      '但这还不只是“手机和电脑”的区别。',
      '这个 app 更需要的是随时、低阻力、稳定的原生移动端体验。',
      'Web 虽然也能在手机上用，但在这种场景里，它通常没有原生 app 那么直接、顺手、稳定。',
      'Flutter 确实支持多端，但支持多端不代表要先做所有端。',
      '所以即使用了 Flutter，现阶段也优先做 Android 和 iOS。',
      '桌面端和 Web 不是不能做，只是它们目前都不如原生移动端更符合这个 app 最核心的使用时刻。',
    ],
  ),
]);

String _formatInt(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final reversedIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
