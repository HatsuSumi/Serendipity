# Serendipity Web

Serendipity 官网子项目。

## 技术栈

- Next.js 15
- React 19
- TypeScript
- CSS Modules

## 页面范围

当前首版为单页官网：

- `Home`：品牌展示、功能介绍、产品边界、界面预览与下载引导

## 下载策略

首页保留两种下载方式：

- **主下载入口**：指向官方下载域名的 APK 文件地址
- **次下载入口**：跳转到 GitHub Releases 最新发布页

这样既兼顾最快安装，也保留查看发布详情与版本资产的入口。

## 设计原则

- 页面少而聚焦，不重复搬运 App 内完整说明页
- 组件按职责拆分，避免首页文件臃肿
- 视觉克制、留白充足、适配移动端与桌面端
- 截图区域先使用竖版占位图，后续可无缝替换真实素材
- 下载配置采用主入口 / 次入口语义，便于后续切换下载源

## 本地开发

```bash
npm install
npm run dev
```

## 构建

```bash
npm run build
npm run start
```
