import styles from './shell.module.css';
import { Header } from '@/components/layout/header';
import { Footer } from '@/components/layout/footer';

type SiteShellProps = {
  children: React.ReactNode;
};

export function SiteShell({ children }: SiteShellProps) {
  return (
    <div className={styles.shell}>
      <Header />
      <main className={styles.main}>{children}</main>
      <Footer />
    </div>
  );
}
