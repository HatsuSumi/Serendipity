/**
 * 依赖注入容器的 Symbol key 常量
 *
 * 使用 Symbol.for() 而非字符串，避免拼写错误导致的运行时异常，
 * 并支持 IDE 追踪和重构。
 */
export const TYPES = {
  // Infrastructure
  Logger:                        Symbol.for('logger'),
  Database:                      Symbol.for('database'),
  Pool:                          Symbol.for('pool'),

  // Services (shared)
  JwtService:                    Symbol.for('jwtService'),
  PasswordHasher:                Symbol.for('passwordHasher'),
  VerificationService:           Symbol.for('verificationService'),
  SyncAccessPolicyService:       Symbol.for('syncAccessPolicyService'),

  // Repositories
  UserRepository:                Symbol.for('userRepository'),
  RefreshTokenRepository:        Symbol.for('refreshTokenRepository'),
  VerificationCodeRepository:    Symbol.for('verificationCodeRepository'),
  RecordRepository:              Symbol.for('recordRepository'),
  StoryLineRepository:           Symbol.for('storyLineRepository'),
  CommunityPostRepository:       Symbol.for('communityPostRepository'),
  MembershipRepository:          Symbol.for('membershipRepository'),
  UserSettingsRepository:        Symbol.for('userSettingsRepository'),
  CheckInRepository:             Symbol.for('checkInRepository'),
  AchievementUnlockRepository:   Symbol.for('achievementUnlockRepository'),
  FavoriteRepository:            Symbol.for('favoriteRepository'),
  PushTokenRepository:           Symbol.for('pushTokenRepository'),

  // Domain Services
  AuthService:                   Symbol.for('authService'),
  RecordService:                 Symbol.for('recordService'),
  StoryLineService:              Symbol.for('storyLineService'),
  CommunityPostService:          Symbol.for('communityPostService'),
  UserService:                   Symbol.for('userService'),
  CheckInService:                Symbol.for('checkInService'),
  PushTokenService:              Symbol.for('pushTokenService'),
  ReminderPushSender:            Symbol.for('reminderPushSender'),
  AchievementUnlockService:      Symbol.for('achievementUnlockService'),
  FavoriteService:               Symbol.for('favoriteService'),

  // Repositories (Statistics)
  StatisticsRepository:          Symbol.for('statisticsRepository'),

  // Domain Services (Statistics)
  StatisticsService:             Symbol.for('statisticsService'),

  // Controllers
  StatisticsController:          Symbol.for('statisticsController'),
  AuthController:                Symbol.for('authController'),
  RecordController:              Symbol.for('recordController'),
  StoryLineController:           Symbol.for('storyLineController'),
  CommunityPostController:       Symbol.for('communityPostController'),
  UserController:                Symbol.for('userController'),
  CheckInController:             Symbol.for('checkInController'),
  PushTokenController:           Symbol.for('pushTokenController'),
  AchievementUnlockController:   Symbol.for('achievementUnlockController'),
  FavoriteController:            Symbol.for('favoriteController'),
} as const;

