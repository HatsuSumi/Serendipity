/**
 * 密码哈希服务接口
 * 用于抽象密码哈希算法，便于扩展和测试
 */
export interface IPasswordHasher {
  /**
   * 哈希密码
   * @param password - 明文密码
   * @returns 哈希后的密码
   */
  hash(password: string): Promise<string>;

  /**
   * 验证密码
   * @param password - 明文密码
   * @param hash - 哈希后的密码
   * @returns 是否匹配
   */
  compare(password: string, hash: string): Promise<boolean>;
}

/**
 * Bcrypt 密码哈希实现
 * 使用 bcrypt 算法进行密码哈希
 */
export class BcryptPasswordHasher implements IPasswordHasher {
  private readonly saltRounds: number;

  /**
   * 构造函数
   * @param saltRounds - 盐轮数，默认 10
   */
  constructor(saltRounds: number = 10) {
    this.saltRounds = saltRounds;
  }

  /**
   * 哈希密码
   * @param password - 明文密码
   * @returns 哈希后的密码
   */
  async hash(password: string): Promise<string> {
    const bcrypt = await import('bcrypt');
    return bcrypt.hash(password, this.saltRounds);
  }

  /**
   * 验证密码
   * @param password - 明文密码
   * @param hash - 哈希后的密码
   * @returns 是否匹配
   */
  async compare(password: string, hash: string): Promise<boolean> {
    const bcrypt = await import('bcrypt');
    return bcrypt.compare(password, hash);
  }
}

