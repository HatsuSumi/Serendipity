import Link from 'next/link';
import styles from './footer.module.css';
import { siteConfig } from '@/config/site';

export function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={styles.inner}>
        <div className={styles.brandBlock}>
          <p className={styles.brand}>
            {siteConfig.name} · {siteConfig.chineseName}
          </p>
          <p className={styles.copy}>{siteConfig.tagline}</p>
        </div>

        <div className={styles.links}>
          <Link href="/">首页</Link>
          <Link href={siteConfig.githubUrl} target="_blank" rel="noreferrer">
            GitHub
          </Link>
        </div>
      </div>

      <div className={styles.meta}>
        <p className={styles.contactLead}>
          如有任何建议、意见、问题，或是想说句鼓励的话，都欢迎发邮件至：
        </p>
        <div className={styles.metaRow}>
          <a className={styles.metaLink} href={`mailto:${siteConfig.contactEmail}`}>
            {siteConfig.contactEmail}
          </a>
          <span className={styles.metaDivider} aria-hidden="true">
            ·
          </span>
          <span>{siteConfig.copyright}</span>
          {siteConfig.icpNumber ? (
            <>
              <span className={styles.metaDivider} aria-hidden="true">
                ·
              </span>
              <span>{siteConfig.icpNumber}</span>
            </>
          ) : null}
        </div>
      </div>
    </footer>
  );
}
