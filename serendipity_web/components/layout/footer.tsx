import Image from 'next/image';
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
              <a
                className={styles.metaLink}
                href="https://beian.miit.gov.cn/"
                target="_blank"
                rel="noreferrer"
              >
                {siteConfig.icpNumber}
              </a>
            </>
          ) : null}
        </div>
        <div className={styles.metaRow}>
          <a
            className={styles.gonganLink}
            href="https://beian.mps.gov.cn/#/query/webSearch?code=44010502004038"
            target="_blank"
            rel="noreferrer"
          >
            <Image src="/images/gongan-badge.png" alt="公安备案图标" width={18} height={18} />
            <span>粤公网安备44010502004038号</span>
          </a>
        </div>
      </div>
    </footer>
  );
}
