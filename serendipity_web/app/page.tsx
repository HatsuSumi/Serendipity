import type { Metadata } from 'next';
import { SiteShell } from '@/components/layout/site-shell';
import { ButtonLink } from '@/components/ui/button-link';
import { Container } from '@/components/ui/container';
import { SectionHeading } from '@/components/ui/section-heading';
import { AppScreenPlaceholder } from '@/components/ui/app-screen-placeholder';
import { ScrollButton } from '@/components/ui/scroll-button';
import {
  builderStory,
  downloadTrustItems,
  experiencePillars,
  featureItems,
  highlights,
  privacyPrinciples,
  screenshotPlaceholders,
} from '@/content/site-content';
import { siteConfig } from '@/config/site';
import styles from './page.module.css';

export const metadata: Metadata = {
  title: '首页',
};

const placeholderTones = ['violet', 'rose', 'blue', 'violet', 'blue', 'rose'] as const;

export default function HomePage() {
  return (
    <SiteShell>
      <section className={styles.hero}>
        <Container>
          <div className={styles.heroGrid}>
            <div className={styles.heroCopy}>
              <p className={styles.eyebrow}>Serendipity · 错过了么</p>
              <div className={styles.heroTitleGroup}>
                <h1 className={styles.heroTitle}>记录那些擦肩而过的瞬间。</h1>
                <p className={styles.heroDescription}>
                  Serendipity 是一款情感记录类移动应用，帮助你把那些短暂心动、没有开口、却停留很久的相遇，安静而认真地留下来。
                </p>
              </div>
              <div className={styles.heroActions}>
                <ButtonLink href={siteConfig.primaryDownloadUrl} external download>
                  {siteConfig.primaryDownloadLabel}
                </ButtonLink>
                <ButtonLink href={siteConfig.secondaryDownloadUrl} variant="secondary" external>
                  {siteConfig.secondaryDownloadLabel}
                </ButtonLink>
                <ScrollButton targetId="features">查看功能</ScrollButton>
              </div>
              <div className={styles.heroMeta}>
                <span>Android 5.0 及以上</span>
                <span>版本 {siteConfig.currentVersion}</span>
                <span>更新于 {siteConfig.updatedAt}</span>
              </div>
            </div>

            <div className={styles.heroVisualStack}>
              <div className={styles.heroVisualMain}>
                <AppScreenPlaceholder
                  title="首页预览"
                  subtitle="从第一次打开开始，界面就保持安静、克制而清晰的节奏。"
                  tone="violet"
                />
              </div>
              <div className={styles.heroVisualFloatTop}>
                <AppScreenPlaceholder
                  title="记录卡片"
                  subtitle="把一瞬间认真留下。"
                  tone="rose"
                />
              </div>
              <div className={styles.heroVisualFloatBottom}>
                <AppScreenPlaceholder
                  title="故事线"
                  subtitle="让多次相遇连成上下文。"
                  tone="blue"
                />
              </div>
            </div>
          </div>
        </Container>
      </section>

      <section className={styles.pillarsSection}>
        <Container>
          <div className={styles.pillarsGrid}>
            {experiencePillars.map((item) => (
              <article key={item.title} className={styles.pillarCard}>
                <h3>{item.title}</h3>
                <p>{item.description}</p>
              </article>
            ))}
          </div>
        </Container>
      </section>

      <section id="features">
        <Container>
          <SectionHeading
            eyebrow="核心功能"
            title="不是为了制造关系，而是为了留住那些本会消失的情绪。"
            description="功能不追求喧闹堆砌，而是围绕记录、整理、回看与克制表达来展开。"
          />
          <div className={styles.featureGrid}>
            {featureItems.map((item, index) => (
              <article key={item.title} className={styles.featureCard}>
                <span className={styles.featureIndex}>0{index + 1}</span>
                <h3>{item.title}</h3>
                <p>{item.description}</p>
              </article>
            ))}
          </div>
        </Container>
      </section>

      <section>
        <Container>
          <div className={styles.highlightGrid}>
            {highlights.map((item) => (
              <article key={item.title} className={styles.highlightCard}>
                <p className={styles.cardEyebrow}>{item.eyebrow}</p>
                <h3>{item.title}</h3>
                <p>{item.description}</p>
              </article>
            ))}
          </div>
        </Container>
      </section>

      <section>
        <Container>
          <div className={styles.privacySection}>
            <SectionHeading
              eyebrow="边界与信任"
              title="克制，是这个产品最重要的设计原则之一。"
              description="官网不重复搬运 App 内完整文案，但会保留下载前最必要的信任信息。"
            />
            <div className={styles.privacyList}>
              {privacyPrinciples.map((principle) => (
                <div key={principle} className={styles.privacyItem}>
                  <p>{principle}</p>
                </div>
              ))}
            </div>
          </div>
        </Container>
      </section>

      <section>
        <Container>
          <div className={styles.builderStorySection}>
            <p className={styles.cardEyebrow}>{builderStory.eyebrow}</p>
            <h2>{builderStory.title}</h2>
            <div className={styles.builderStoryHighlights}>
              {builderStory.highlights.map((item) => (
                <div key={item.label} className={styles.builderStoryHighlightItem}>
                  <strong>{item.value}</strong>
                  <span>{item.label}</span>
                </div>
              ))}
            </div>
            <div className={styles.builderStoryCopy}>
              {builderStory.paragraphs.map((paragraph) => (
                <p key={paragraph}>{paragraph}</p>
              ))}
            </div>
          </div>
        </Container>
      </section>

      <section>
        <Container>
          <div className={styles.downloadTrustSection}>
            <SectionHeading
              eyebrow="下载说明"
              title="把安装路径做得清楚，也是官网可信度的一部分。"
              description="主按钮走官方下载域名，辅助入口保留版本说明页面，既方便安装，也方便核对版本。"
            />
            <div className={styles.downloadTrustGrid}>
              {downloadTrustItems.map((item) => (
                <article key={item.title} className={styles.downloadTrustCard}>
                  <h3>{item.title}</h3>
                  <p>{item.description}</p>
                </article>
              ))}
            </div>
          </div>
        </Container>
      </section>

      <section>
        <Container>
          <SectionHeading
            eyebrow="界面预览"
            title="从首页、记录到故事线，提前感受产品的整体界面气质。"
            description="界面保持移动端竖屏节奏，信息层级清晰，阅读路径自然。"
          />
          <div className={styles.screenGrid}>
            {screenshotPlaceholders.map((item, index) => (
              <AppScreenPlaceholder
                key={item.title}
                title={item.title}
                subtitle={item.subtitle}
                tone={placeholderTones[index]}
              />
            ))}
          </div>
        </Container>
      </section>

      <section>
        <Container>
          <div className={styles.ctaPanel}>
            <div className={styles.ctaCopy}>
              <p className={styles.cardEyebrow}>准备下载</p>
              <h2>想要立刻开始记录，就直接下载。想先确认版本细节，也可以先看看这次更新带来了什么。</h2>
              <p>
                两种方式都保留：一键下载用于最快安装，查看最新版本用于了解发布记录、更新说明与资源详情。
              </p>
            </div>
            <div className={styles.ctaActions}>
              <ButtonLink href={siteConfig.primaryDownloadUrl} external download>
                {siteConfig.primaryDownloadLabel}
              </ButtonLink>
              <ButtonLink href={siteConfig.secondaryDownloadUrl} variant="secondary" external>
                {siteConfig.secondaryDownloadLabel}
              </ButtonLink>
            </div>
          </div>
        </Container>
      </section>
    </SiteShell>
  );
}
