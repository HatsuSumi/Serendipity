import Image from 'next/image';
import Link from 'next/link';
import styles from './header.module.css';
import { primaryNavItems, siteConfig } from '@/config/site';

export function Header() {
  return (
    <header className={styles.header}>
      <div className={styles.inner}>
        <Link className={styles.brand} href="/">
          <span className={styles.brandMark}>
            <Image
              src="/images/logo.png"
              alt={`${siteConfig.name} logo`}
              width={44}
              height={44}
              className={styles.brandLogo}
              priority
            />
          </span>
          <span className={styles.brandText}>
            <strong>{siteConfig.name}</strong>
            <span>{siteConfig.chineseName}</span>
          </span>
        </Link>

        <nav className={styles.nav} aria-label="Primary">
          {primaryNavItems.map((item) => (
            <Link key={item.href} className={styles.navLink} href={item.href}>
              {item.label}
            </Link>
          ))}
        </nav>

        <div className={styles.actions}>
          <Link className={styles.secondaryCta} href={siteConfig.secondaryDownloadUrl} target="_blank" rel="noreferrer">
            查看版本
          </Link>
          <Link className={styles.cta} href={siteConfig.primaryDownloadUrl} target="_blank" rel="noreferrer">
            下载 APK
          </Link>
        </div>
      </div>
    </header>
  );
}
