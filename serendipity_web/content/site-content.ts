export type FeatureItem = {
  title: string;
  description: string;
};

export type HighlightItem = {
  eyebrow: string;
  title: string;
  description: string;
};

export type ScreenshotPlaceholder = {
  title: string;
  subtitle: string;
};

export const featureItems: FeatureItem[] = [
  {
    title: '记录瞬间',
    description:
      '用时间、地点、状态、标签、天气与感受，保存那些原本会消失的心动片段。',
  },
  {
    title: '故事线',
    description:
      '把同一个人的多次相遇串成一条故事线，让每一次擦肩而过都有上下文。',
  },
  {
    title: '时间轴',
    description:
      '清晰回看每一条记录，按自己的节奏整理、筛选、理解那些记忆。',
  },
  {
    title: '树洞',
    description:
      '匿名发布，不强调互动，不追求打扰，只保留适度表达的空间。',
  },
  {
    title: '统计与成就',
    description:
      '从记录中看见自己的偏好、轨迹与变化，让感受拥有被理解的轮廓。',
  },
  {
    title: '同步与提醒',
    description:
      '本地可用，登录后同步；支持签到与提醒能力，把重要的日子轻轻留住。',
  },
];

export const highlights: HighlightItem[] = [
  {
    eyebrow: '不是社交软件',
    title: '它不帮你制造关系，它只是允许你保存情绪。',
    description:
      '多数产品都在鼓励连接，但有些相遇并不会变成故事。Serendipity 承认这一点。',
  },
  {
    eyebrow: '克制的边界',
    title: '不公开精确位置，不鼓励骚扰，也不放大短暂情绪。',
    description:
      '这是一个关于“记住”的产品，而不是一个关于“占有”或“追逐”的产品。',
  },
];

export const privacyPrinciples = [
  '不公开精确 GPS 坐标，仅以脱敏后的方式帮助记录地点记忆。',
  '支持本地使用，登录后再开启账号同步与更多云端能力。',
  '树洞保持匿名表达，不提供会诱发骚扰的强互动机制。',
];

export const screenshotPlaceholders: ScreenshotPlaceholder[] = [
  {
    title: '时间轴',
    subtitle: '回看每一次擦肩而过。',
  },
  {
    title: '创建记录',
    subtitle: '把感觉安静地写下来。',
  },
  {
    title: '故事线',
    subtitle: '把多次相遇连成一条线。',
  },
  {
    title: '树洞',
    subtitle: '匿名表达，不必打扰。',
  },
  {
    title: '统计',
    subtitle: '看见自己的偏好与轨迹。',
  },
  {
    title: '关于',
    subtitle: '理解它为什么存在。',
  },
  {
    title: '记录详情',
    subtitle: '把一次相遇的细节完整展开。',
  },
  {
    title: '故事线详情',
    subtitle: '在一条线里回看关系的推进。',
  },
  {
    title: '会员',
    subtitle: '查看权益、订阅与支持计划，价格完全自定义！',
  },
];

export const experiencePillars = [
  {
    title: '离线优先',
    description: '不登录也能开始记录，先让记忆留下来，再决定是否同步。',
  },
  {
    title: '轻度表达',
    description: '不把情绪推向喧闹，保留一种安静、克制、可回看的叙事方式。',
  },
  {
    title: '长期整理',
    description: '从单次心动到故事线，再到统计视角，慢慢看见自己的变化。',
  },
] as const;

export const builderStory = {
  eyebrow: '开发者自述',
  title: '这是一个由一人耗时 71 天完成的开源免费项目。',
  highlights: [
    { value: '71 天', label: '持续开发周期' },
    { value: '一人完成', label: '覆盖设计到运维' },
    { value: '开源免费', label: '长期公开维护' },
  ],
  paragraphs: [
    '它诞生于孤独与抑郁长期陪伴的那段时间里，也是在那样的状态下，被一点点做出来的。',
    '从产品设计、前端开发、后端开发，到架构设计、数据库设计、接口设计、运维部署、测试、维护与文档编写，几乎所有环节都由一人完成。',
    '如果说一人比不过团队，如果说一人无法开发出接近团队规模的项目，那么至少在这个项目上，我想亲手打破这个规则。如今，我已经做到了。',
  ],
  website: {
    label: '我的个人网站，作品集',
    href: 'https://hatsusumi.github.io/FinalTestamentProofILived/',
  },
} as const;

export const downloadTrustItems = [
  {
    title: '官方下载',
    description: '主按钮优先使用官方下载域名，避免把安装体验完全绑定到第三方平台。',
  },
  {
    title: '版本可追溯',
    description: '同时保留查看最新版本入口，方便用户查看发布说明、版本记录与历史资源。',
  },
  {
    title: '安装可预期',
    description: '当前仅提供 Android APK，首次安装若出现未知来源提示，属于正常系统流程。',
  },
] as const;
