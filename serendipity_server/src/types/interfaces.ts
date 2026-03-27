export interface IDatabase {
  user: {
    findUnique: (args: unknown) => Promise<unknown>;
    create: (args: unknown) => Promise<unknown>;
    update: (args: unknown) => Promise<unknown>;
    delete: (args: unknown) => Promise<unknown>;
  };
  $disconnect: () => Promise<void>;
}

export interface IJwtService {
  verify(token: string): Promise<unknown>;
  sign(payload: unknown, options?: unknown): string;
}

export interface ILogger {
  info(message: string, meta?: unknown): void;
  error(message: string, meta?: unknown): void;
  warn(message: string, meta?: unknown): void;
  debug(message: string, meta?: unknown): void;
}

export interface IConfig {
  port: number;
  nodeEnv: string;
  database: {
    url: string;
  };
  jwt: {
    secret: string;
    expiresIn: string;
    refreshTokenExpiresIn: string;
  };
  cors: {
    origin: string;
  };
}

