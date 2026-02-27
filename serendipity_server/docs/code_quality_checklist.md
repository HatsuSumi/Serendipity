# Serendipity 代码质量检查清单

**版本**：v1.0  
**创建时间**：2026-02-26  
**适用范围**：所有后端代码  
**检查频率**：每个 Phase 完成后

---

## 📋 使用说明

本文档定义了 Serendipity 项目的代码质量标准。每次代码审查时，必须逐项检查以下所有原则。

**检查方式：**
- ✅ 符合
- ⚠️ 部分符合（需改进）
- ❌ 不符合（必须修复）

---

## 🎯 一、SOLID 原则

### 1.1 单一职责原则 (Single Responsibility Principle)

**定义：** 一个类/模块/函数只负责一件事

**检查项：**

- 每个类只有一个修改的理由
- 每个函数只做一件事
- 每个模块职责明确且单一
- 没有"上帝类"（God Class）

**反例：**
```typescript
// ❌ 一个类做了太多事
class UserController {
  login() { ... }           // 认证
  generateToken() { ... }   // Token 生成
  sendEmail() { ... }       // 邮件发送
  validateInput() { ... }   // 输入验证
}
```

**正例：**
```typescript
// ✅ 职责分离
class AuthController {
  login() { ... }
}

class JwtService {
  generateToken() { ... }
}

class EmailService {
  sendEmail() { ... }
}

class ValidationService {
  validateInput() { ... }
}
```

**检查方法：**
1. 问自己：这个类/函数是否只做一件事？
2. 如果用"和"来描述功能，说明违反了 SRP
3. 检查类名/函数名是否清晰表达单一职责

---

### 1.2 开闭原则 (Open/Closed Principle)

**定义：** 对扩展开放，对修改关闭

**检查项：**

- 添加新功能时无需修改现有代码
- 使用接口/抽象类实现扩展
- 使用策略模式、工厂模式等设计模式
- 配置驱动而非硬编码

**反例：**
```typescript
// ❌ 添加新中间件需要修改这个文件
function setupMiddlewares(app: Application) {
  app.use(helmet());
  app.use(cors());
  app.use(express.json());
  // 添加新中间件 → 必须修改这里
}
```

**正例：**
```typescript
// ✅ 扩展无需修改
interface MiddlewareConfig {
  apply(app: Application): void;
}

class SecurityMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    app.use(helmet());
  }
}

// 添加新中间件 → 创建新类即可
class CustomMiddleware implements MiddlewareConfig {
  apply(app: Application): void {
    // 新逻辑
  }
}
```

**检查方法：**
1. 模拟添加新功能，是否需要修改现有代码？
2. 是否使用了接口/抽象类？
3. 是否有硬编码的 if-else 或 switch？

---

### 1.3 里氏替换原则 (Liskov Substitution Principle)

**定义：** 子类可以替换父类而不影响程序正确性

**检查项：**

- 子类不改变父类的行为
- 子类不抛出父类没有的异常
- 子类的前置条件不比父类更严格
- 子类的后置条件不比父类更宽松

**反例：**
```typescript
// ❌ 子类改变了父类行为
class Bird {
  fly() { console.log('Flying'); }
}

class Penguin extends Bird {
  fly() { throw new Error('Cannot fly'); }  // 违反 LSP
}
```

**正例：**
```typescript
// ✅ 正确的继承
interface Bird {
  move(): void;
}

class FlyingBird implements Bird {
  move() { this.fly(); }
  fly() { console.log('Flying'); }
}

class Penguin implements Bird {
  move() { this.swim(); }
  swim() { console.log('Swimming'); }
}
```

**检查方法：**
1. 子类是否可以完全替换父类？
2. 子类是否改变了父类的预期行为？
3. 继承关系是否符合"is-a"关系？

---

### 1.4 接口隔离原则 (Interface Segregation Principle)

**定义：** 接口应该小而专注，不强迫实现不需要的方法

**检查项：**

- 接口职责单一
- 没有"胖接口"（Fat Interface）
- 客户端不依赖不使用的方法
- 接口粒度合适

**反例：**
```typescript
// ❌ 胖接口
interface IUser {
  // 用户基本操作
  findById(id: string): Promise<User>;
  create(data: any): Promise<User>;
  update(id: string, data: any): Promise<User>;
  delete(id: string): Promise<void>;
  
  // 认证相关
  login(email: string, password: string): Promise<string>;
  logout(token: string): Promise<void>;
  
  // 邮件相关
  sendVerificationEmail(email: string): Promise<void>;
  sendPasswordResetEmail(email: string): Promise<void>;
}
```

**正例：**
```typescript
// ✅ 接口隔离
interface IUserRepository {
  findById(id: string): Promise<User>;
  create(data: any): Promise<User>;
  update(id: string, data: any): Promise<User>;
  delete(id: string): Promise<void>;
}

interface IAuthService {
  login(email: string, password: string): Promise<string>;
  logout(token: string): Promise<void>;
}

interface IEmailService {
  sendVerificationEmail(email: string): Promise<void>;
  sendPasswordResetEmail(email: string): Promise<void>;
}
```

**检查方法：**
1. 接口是否包含多个不相关的方法？
2. 实现类是否需要实现所有方法？
3. 接口是否可以进一步拆分？

---

### 1.5 依赖倒置原则 (Dependency Inversion Principle)

**定义：** 依赖抽象而非具体实现

**检查项：**

- 高层模块不依赖低层模块
- 都依赖于抽象（接口/抽象类）
- 抽象不依赖细节
- 细节依赖抽象

**反例：**
```typescript
// ❌ 依赖具体实现
import prisma from './utils/prisma';
import { logger } from './utils/logger';

export class UserService {
  async getUser(id: string) {
    logger.info('Getting user');  // 硬编码依赖
    return prisma.user.findUnique({ where: { id } });  // 硬编码依赖
  }
}
```

**正例：**
```typescript
// ✅ 依赖抽象
interface ILogger {
  info(message: string): void;
}

interface IDatabase {
  user: {
    findUnique(args: any): Promise<User>;
  };
}

export class UserService {
  constructor(
    private logger: ILogger,
    private db: IDatabase
  ) {}

  async getUser(id: string) {
    this.logger.info('Getting user');
    return this.db.user.findUnique({ where: { id } });
  }
}
```

**检查方法：**
1. 是否直接 import 具体实现？
2. 是否定义了抽象接口？
3. 是否通过构造函数注入依赖？

---

## 🔄 二、DRY 原则 (Don't Repeat Yourself)

**定义：** 避免重复代码，提取公共逻辑

**检查项：**

- 没有复制粘贴的代码
- 相似逻辑已提取为函数/类
- 使用工具函数/工具类
- 配置统一管理

**反例：**
```typescript
// ❌ 重复代码
app.post('/api/users', (req, res) => {
  res.status(200).json({
    success: true,
    data: userData
  });
});

app.post('/api/posts', (req, res) => {
  res.status(200).json({
    success: true,
    data: postData
  });
});
```

**正例：**
```typescript
// ✅ 提取公共逻辑
function sendSuccess(res: Response, data: any) {
  res.status(200).json({
    success: true,
    data
  });
}

app.post('/api/users', (req, res) => {
  sendSuccess(res, userData);
});

app.post('/api/posts', (req, res) => {
  sendSuccess(res, postData);
});
```

**检查方法：**
1. 搜索相似的代码片段
2. 检查是否有 3 次以上的重复
3. 是否可以提取为函数/类？

---

## 💋 三、KISS 原则 (Keep It Simple, Stupid)

**定义：** 保持简单，避免过度设计

**检查项：**

- 代码简单易懂
- 没有不必要的抽象
- 没有过度工程
- 新人可以快速理解

**反例：**
```typescript
// ❌ 过度设计
class AbstractFactoryProviderSingletonManager {
  private static instance: AbstractFactoryProviderSingletonManager;
  
  private constructor() {}
  
  static getInstance(): AbstractFactoryProviderSingletonManager {
    if (!this.instance) {
      this.instance = new AbstractFactoryProviderSingletonManager();
    }
    return this.instance;
  }
  
  createFactory(): AbstractFactory {
    return new ConcreteFactoryImpl();
  }
}

// 只是为了创建一个对象...
```

**正例：**
```typescript
// ✅ 简单直接
export const createUser = (data: UserData): User => {
  return {
    id: generateId(),
    ...data,
    createdAt: new Date()
  };
};
```

**检查方法：**
1. 代码是否容易理解？
2. 是否有不必要的设计模式？
3. 是否可以用更简单的方式实现？

---

## 🚫 四、YAGNI 原则 (You Aren't Gonna Need It)

**定义：** 不要实现暂时不需要的功能

**检查项：**

- 只实现当前需要的功能
- 没有"以后可能用到"的代码
- 没有未使用的函数/类
- 没有过度的配置项

**反例：**
```typescript
// ❌ 实现了不需要的功能
class UserService {
  async getUser(id: string) { ... }
  async createUser(data: any) { ... }
  
  // 以下功能当前不需要
  async exportUsersToCSV() { ... }
  async importUsersFromXML() { ... }
  async syncWithLDAP() { ... }
  async generateUserReport() { ... }
}
```

**正例：**
```typescript
// ✅ 只实现需要的
class UserService {
  async getUser(id: string) { ... }
  async createUser(data: any) { ... }
}

// 需要时再添加其他功能
```

**检查方法：**
1. 这个功能当前是否真的需要？
2. 是否有未使用的代码？
3. 是否为"可能的需求"编写代码？

---

## ⚡ 五、Fail Fast 原则

**定义：** 尽早发现错误，立即失败

**检查项：**

- 配置错误在启动时就报错
- 参数验证在函数开始时进行
- 不隐藏错误
- 不使用默认值掩盖问题

**反例：**
```typescript
// ❌ 延迟失败
export const config = {
  jwtSecret: process.env.JWT_SECRET || 'default_secret',  // 危险！
  port: process.env.PORT || 3000
};

// 程序启动了，但 JWT_SECRET 可能未配置
// 直到第一次使用时才发现问题
```

**正例：**
```typescript
// ✅ 立即失败
function getRequiredEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

export const config = {
  jwtSecret: getRequiredEnv('JWT_SECRET'),  // 启动时就检查
  port: parseInt(process.env.PORT || '3000', 10)
};
```

**检查方法：**
1. 必需的配置是否有验证？
2. 是否使用了 `||` 提供默认值？
3. 错误是否被捕获后忽略？

---

## 🎯 六、关注点分离 (Separation of Concerns)

**定义：** 不同的关注点分离到不同的模块

**检查项：**

- 业务逻辑、数据访问、表现层分离
- 每层职责明确
- 层与层之间通过接口通信
- 没有跨层调用

**反例：**
```typescript
// ❌ 所有逻辑混在一起
app.post('/api/users', async (req, res) => {
  // 验证
  if (!req.body.email) {
    return res.status(400).json({ error: 'Email required' });
  }
  
  // 业务逻辑
  const hashedPassword = await bcrypt.hash(req.body.password, 10);
  
  // 数据访问
  const user = await prisma.user.create({
    data: { email: req.body.email, password: hashedPassword }
  });
  
  // 响应
  res.status(201).json({ success: true, data: user });
});
```

**正例：**
```typescript
// ✅ 分层清晰
// Controller 层
app.post('/api/users', validateBody(createUserSchema), async (req, res) => {
  const user = await userService.createUser(req.body);
  sendSuccess(res, user, 201);
});

// Service 层
class UserService {
  async createUser(data: CreateUserDto) {
    const hashedPassword = await this.hashPassword(data.password);
    return this.userRepository.create({ ...data, password: hashedPassword });
  }
}

// Repository 层
class UserRepository {
  async create(data: any) {
    return prisma.user.create({ data });
  }
}
```

**检查方法：**
1. 是否有明确的分层？
2. Controller 是否包含业务逻辑？
3. Service 是否直接操作数据库？

---

## 💉 七、依赖注入 (Dependency Injection)

**定义：** 通过构造函数或参数注入依赖

**检查项：**

- 依赖通过构造函数注入
- 没有全局单例（或使用容器管理）
- 便于测试（可以 mock）
- 生命周期管理清晰

**反例：**
```typescript
// ❌ 全局单例，难以测试
import prisma from './utils/prisma';
import { logger } from './utils/logger';

export class UserService {
  async getUser(id: string) {
    logger.info('Getting user');  // 无法 mock
    return prisma.user.findUnique({ where: { id } });  // 无法 mock
  }
}
```

**正例：**
```typescript
// ✅ 依赖注入
export class UserService {
  constructor(
    private logger: ILogger,
    private db: IDatabase
  ) {}

  async getUser(id: string) {
    this.logger.info('Getting user');
    return this.db.user.findUnique({ where: { id } });
  }
}

// 使用容器管理
const container = Container.getInstance();
const logger = container.get<ILogger>('logger');
const db = container.get<IDatabase>('database');
const userService = new UserService(logger, db);
```

**检查方法：**
1. 是否直接 import 依赖？
2. 是否通过构造函数注入？
3. 测试时是否可以替换依赖？

---

## 🔒 八、不可变性 (Immutability)

**定义：** 数据一旦创建就不可修改

**检查项：**

- 配置对象使用 `Object.freeze`
- 使用 `const` 而非 `let`
- 避免修改参数
- 返回新对象而非修改原对象

**反例：**
```typescript
// ❌ 可变配置
export const config = {
  port: 3000,
  jwtSecret: 'secret'
};

// 其他地方可能误修改
config.port = 8080;  // 危险！
```

**正例：**
```typescript
// ✅ 不可变配置
export const config = Object.freeze({
  port: 3000,
  jwtSecret: 'secret'
});

// 尝试修改会失败
config.port = 8080;  // TypeError in strict mode
```

**检查方法：**
1. 导出的对象是否冻结？
2. 是否使用 `const`？
3. 函数是否修改参数？

---

## 📝 九、Clean Code 原则

### 9.1 命名规范

**检查项：**

- 变量名清晰表达意图
- 函数名使用动词开头
- 类名使用名词
- 常量使用大写
- 布尔值使用 is/has/can 开头

**反例：**
```typescript
// ❌ 糟糕的命名
const d = new Date();  // d 是什么？
function proc(x: any) { ... }  // proc 做什么？
class Mgr { ... }  // Mgr 是什么？
```

**正例：**
```typescript
// ✅ 清晰的命名
const createdAt = new Date();
function processUserData(userData: UserData) { ... }
class UserManager { ... }
const MAX_RETRY_COUNT = 3;
const isAuthenticated = true;
```

---

### 9.2 函数规范

**检查项：**

- 函数简短（< 30 行）
- 参数少（< 4 个）
- 只做一件事
- 没有副作用

**反例：**
```typescript
// ❌ 函数太长，做太多事
function processUser(id: string, email: string, password: string, role: string, status: string) {
  // 50 行代码...
  // 验证、创建、发邮件、记录日志...
}
```

**正例：**
```typescript
// ✅ 函数简短，职责单一
function validateUser(data: UserData): void { ... }
function createUser(data: UserData): User { ... }
function sendWelcomeEmail(email: string): void { ... }
```

---

### 9.3 注释规范

**检查项：**

- 注释解释"为什么"而非"是什么"
- 复杂逻辑有注释
- 公共 API 有 JSDoc
- 没有注释掉的代码

**反例：**
```typescript
// ❌ 无用的注释
// 创建用户
function createUser() { ... }

// i 加 1
i++;

// 旧代码
// function oldFunction() { ... }
```

**正例：**
```typescript
// ✅ 有价值的注释
/**
 * 使用 bcrypt 而非 md5，因为 md5 已不安全
 * 成本因子设为 10，平衡安全性和性能
 */
const hashedPassword = await bcrypt.hash(password, 10);

/**
 * 获取用户信息
 * @param id - 用户 ID
 * @returns 用户对象，不存在则返回 null
 */
async function getUser(id: string): Promise<User | null> { ... }
```

---

### 9.4 错误处理

**检查项：**

- 使用自定义错误类
- 错误信息清晰
- 统一错误码
- 不吞掉错误

**反例：**
```typescript
// ❌ 糟糕的错误处理
try {
  await someOperation();
} catch (err) {
  console.log('Error');  // 信息不明确
}

throw new Error('Error');  // 错误信息太模糊
```

**正例：**
```typescript
// ✅ 良好的错误处理
try {
  await someOperation();
} catch (err) {
  logger.error('Failed to process user data', { error: err, userId });
  throw new AppError('Failed to process user data', ErrorCode.PROCESSING_ERROR);
}
```

---

## 🧪 十、可测试性

**检查项：**

- 函数是纯函数（无副作用）
- 依赖可以 mock
- 没有全局状态
- 测试覆盖率 > 80%

**反例：**
```typescript
// ❌ 难以测试
import prisma from './prisma';

export async function getUser(id: string) {
  return prisma.user.findUnique({ where: { id } });  // 无法 mock prisma
}
```

**正例：**
```typescript
// ✅ 易于测试
export async function getUser(
  db: IDatabase,
  id: string
) {
  return db.user.findUnique({ where: { id } });
}

// 测试时
const mockDb = { user: { findUnique: jest.fn() } };
await getUser(mockDb, '123');
```

---

## 🔐 十一、安全性

**检查项：**

- 输入验证
- SQL 注入防护（使用 ORM）
- XSS 防护
- CSRF 防护
- 敏感信息加密
- 密码哈希（bcrypt）
- JWT 安全配置

**反例：**
```typescript
// ❌ 不安全
const query = `SELECT * FROM users WHERE email = '${email}'`;  // SQL 注入
const password = req.body.password;  // 明文密码
res.json({ user, password });  // 泄露密码
```

**正例：**
```typescript
// ✅ 安全
const user = await prisma.user.findUnique({ where: { email } });  // ORM 防注入
const hashedPassword = await bcrypt.hash(password, 10);  // 密码哈希
res.json({ user: { id: user.id, email: user.email } });  // 不返回敏感信息
```

---

## 📊 十二、性能优化

**检查项：**

- 避免 N+1 查询
- 使用索引
- 分页查询
- 缓存热点数据
- 异步操作
- 连接池管理

**反例：**
```typescript
// ❌ N+1 查询
const users = await prisma.user.findMany();
for (const user of users) {
  user.posts = await prisma.post.findMany({ where: { userId: user.id } });
}
```

**正例：**
```typescript
// ✅ 使用 include 避免 N+1
const users = await prisma.user.findMany({
  include: { posts: true }
});
```

---

## 📏 十三、代码度量标准

### 13.1 复杂度

| 指标 | 标准 | 说明 |
|------|------|------|
| 函数长度 | < 30 行 | 超过需要拆分 |
| 参数个数 | < 4 个 | 超过使用对象 |
| 圈复杂度 | < 10 | 超过需要简化 |
| 嵌套深度 | < 3 层 | 超过需要提取函数 |

### 13.2 可维护性

| 指标 | 标准 | 说明 |
|------|------|------|
| 代码重复率 | < 5% | 超过需要提取公共代码 |
| 测试覆盖率 | > 80% | 核心逻辑 100% |
| 注释率 | 10-20% | 过多或过少都不好 |
| 文件长度 | < 300 行 | 超过需要拆分 |

---

## ✅ 检查清单模板

每次代码审查时，复制以下清单进行检查：

```markdown
## 代码审查清单

**审查文件：** _____________
**审查时间：** _____________
**审查者：** _____________

### SOLID 原则
- [ ] 单一职责原则 (SRP)
- [ ] 开闭原则 (OCP)
- [ ] 里氏替换原则 (LSP)
- [ ] 接口隔离原则 (ISP)
- [ ] 依赖倒置原则 (DIP)

### 其他原则
- [ ] DRY 原则
- [ ] KISS 原则
- [ ] YAGNI 原则
- [ ] Fail Fast 原则
- [ ] 关注点分离
- [ ] 依赖注入
- [ ] 不可变性

### Clean Code
- [ ] 命名规范
- [ ] 函数规范
- [ ] 注释规范
- [ ] 错误处理

### 质量指标
- [ ] 可测试性
- [ ] 安全性
- [ ] 性能优化
- [ ] 代码度量

### 问题记录
1. 
2. 
3. 

### 改进建议
1. 
2. 
3. 

### 总体评分
- [ ] ⭐⭐⭐⭐⭐ 优秀
- [ ] ⭐⭐⭐⭐ 良好
- [ ] ⭐⭐⭐ 合格
- [ ] ⭐⭐ 需改进
- [ ] ⭐ 不合格
```

---

## 📚 参考资料

### 书籍
- 《Clean Code》 - Robert C. Martin
- 《重构：改善既有代码的设计》 - Martin Fowler
- 《设计模式》 - Gang of Four
- 《代码大全》 - Steve McConnell

### 在线资源
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Clean Code JavaScript](https://github.com/ryanmcdermott/clean-code-javascript)
- [Refactoring Guru](https://refactoring.guru/)

---

## 🔄 文档更新记录

| 版本 | 日期 | 修改内容 | 修改人 |
|------|------|---------|--------|
| v1.0 | 2026-02-26 | 初始版本 | AI Assistant |

---

**使用建议：**

1. **每个 Phase 完成后必须审查**
2. **发现问题立即修复**
3. **定期更新此文档**
4. **团队共同遵守**

**记住：代码质量不是一次性的，而是持续的过程！** 🚀

