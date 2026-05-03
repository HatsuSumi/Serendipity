import styles from './app-screen-placeholder.module.css';

type AppScreenPlaceholderProps = {
  title: string;
  subtitle: string;
  tone?: 'violet' | 'rose' | 'blue';
};

export function AppScreenPlaceholder({
  title,
  subtitle,
  tone = 'violet',
}: AppScreenPlaceholderProps) {
  return (
    <div className={[styles.frame, styles[tone]].join(' ')}>
      <div className={styles.notch} />

      <div className={styles.canvas}>
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
      </div>

      <div className={styles.copy}>
        <p className={styles.title}>{title}</p>
        <p className={styles.subtitle}>{subtitle}</p>
      </div>
    </div>
  );
}
