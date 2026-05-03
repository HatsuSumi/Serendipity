import Image from 'next/image';
import styles from './app-screen-placeholder.module.css';

type AppScreenPlaceholderProps = {
  title: string;
  subtitle: string;
  tone?: 'violet' | 'rose' | 'blue';
  imageSrc?: string;
  imageAlt?: string;
  variant?: 'default' | 'floating';
};

export function AppScreenPlaceholder({
  title,
  subtitle,
  tone = 'violet',
  imageSrc,
  imageAlt,
  variant = 'default',
}: AppScreenPlaceholderProps) {
  return (
    <div className={[styles.frame, styles[tone], variant === 'floating' ? styles.floating : ''].join(' ')}>
      <div className={styles.notch} />

      <div className={styles.canvas}>
        {imageSrc ? (
          <Image
            src={imageSrc}
            alt={imageAlt ?? title}
            fill
            className={styles.screenshotImage}
            sizes="(max-width: 768px) 72vw, (max-width: 1200px) 32vw, 280px"
          />
        ) : (
          <>
            <div className={styles.topBar}>
              <span />
              <span />
              <span />
            </div>
            <div className={styles.previewBlockLarge} />
            <div className={styles.previewRow}>
              <div className={styles.previewBlockSmall} />
              <div className={styles.previewBlockSmall} />
            </div>
            <div className={styles.previewBlockMedium} />
          </>
        )}
      </div>

      <div className={styles.copy}>
        <p className={styles.title}>{title}</p>
        <p className={styles.subtitle}>{subtitle}</p>
      </div>
    </div>
  );
}
