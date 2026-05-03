type ContainerProps = {
  children: React.ReactNode;
};

export function Container({ children }: ContainerProps) {
  return <div style={{ width: 'min(calc(100% - 2rem), var(--container-width))', margin: '0 auto' }}>{children}</div>;
}
