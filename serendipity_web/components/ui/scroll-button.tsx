'use client';

import styles from './scroll-button.module.css';

type ScrollButtonProps = {
  targetId: string;
  children: React.ReactNode;
};

export function ScrollButton({ targetId, children }: ScrollButtonProps) {
  const handleClick = () => {
    const target = document.getElementById(targetId);
    if (!target) return;

    const headerOffset = 92;
    const targetTop = target.getBoundingClientRect().top + window.scrollY - headerOffset;
    const startTop = window.scrollY;
    const distance = targetTop - startTop;
    const duration = 700;
    const startTime = performance.now();

    const easeInOutCubic = (t: number) =>
      t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

    const tick = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const easedProgress = easeInOutCubic(progress);

      window.scrollTo({
        top: startTop + distance * easedProgress,
      });

      if (progress < 1) {
        window.requestAnimationFrame(tick);
      }
    };

    window.requestAnimationFrame(tick);
  };

  return (
    <button className={styles.button} type="button" onClick={handleClick}>
      <span>{children}</span>
    </button>
  );
}
