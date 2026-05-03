import Link from 'next/link';
import styles from './button.module.css';

type ButtonLinkProps = {
  href: string;
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'ghost';
  external?: boolean;
  download?: boolean;
};

export function ButtonLink({
  href,
  children,
  variant = 'primary',
  external = false,
  download = false,
}: ButtonLinkProps) {
  const className = [styles.button, styles[variant]].join(' ');

  if (external || download) {
    return (
      <a
        className={className}
        href={href}
        target="_blank"
        rel="noreferrer"
        {...(download ? { download: true } : {})}
      >
        <span>{children}</span>
      </a>
    );
  }

  return (
    <Link className={className} href={href}>
      <span>{children}</span>
    </Link>
  );
}
