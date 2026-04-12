# 数据字段同步问题审计（2026-04-12）

> 审计目标：梳理当前项目中“本地字段 / 云端字段 / 同步链路”之间的不一致，重点找出会导致**换设备后数据丢失或状态不一致**的问题。
>
> 审计范围：
> - Flutter 客户端模型、Provider、Repository、SyncService、本地存储接口
> - Node.js 服务端 DTO、Route、Controller、Service、Repository、Prisma schema
>
> 结论原则：
> - **已确认问题**：代码链路已经核对，能够明确证明存在缺口
> - **设计风险 / 待确认项**：暂未看到完整证据链，先不定性为 bug
>
---

## 一、总体结论

当前项目的同步架构已经覆盖了以下核心数据：

- 遇见记录 `EncounterRecord`
- 故事线 `StoryLine`
- 签到记录 `CheckInRecord`
- 成就解锁记录 `AchievementUnlock`
- 用户设置 `UserSettings`
- 收藏关系
- Push Token 注册状态

但仍然存在几类**明确的同步缺口**：

1. **会员 `Membership` 仍是纯本地数据，没有云端真源**
2. **故事线 `StoryLine.isPinned` 只在客户端模型中存在，服务端未落库也未同步**
3. **`StoryLine.ownerId` 只在客户端模型中存在，服务端未落库也未同步**
4. **用户模型 `User` 的部分字段在客户端存在，但服务端返回链路不完整，导致换设备后可能丢失或回退**
5. **用户设置上传接口没有使用服务端返回值，客户端与服务端时间戳可能漂移**

其中最严重的是前两项：

- `Membership.*`
- `StoryLine.isPinned`

这两项都会直接影响用户跨设备体验，而且都属于用户可感知状态。

---

## 二、已确认问题清单

---

### 问题 1：会员 `Membership` 只有本地存储，没有云端同步

**严重级别：P0**

#### 现象

客户端存在完整的 `Membership` 模型和本地仓储：

- `id`
- `userId`
- `tier`
- `status`
- `startedAt`
- `expiresAt`
- `createdAt`
- `updatedAt`

但客户端 `MembershipRepository` 只依赖本地 `IStorageService`：

- `getMembership()`
- `saveMembership()`
- `deleteMembership()`

没有任何远端仓储调用。

服务端侧也未发现完整的会员模块：

- 没有会员路由
- 没有会员 DTO
- 没有会员 Controller / Service / Repository
- 当前审计过程中也未发现 Prisma 中有成体系的会员同步接口链路

#### 风险

用户在设备 A 开通或重置会员后：

- 设备 B 登录时无法从云端恢复会员状态
- 会员主题权限可能丢失
- 纪念日提醒等会员能力可能不一致
- 故事线数量限制等权限判断可能不一致

#### 结论

`Membership` 当前是**纯本地状态**，属于明确的跨设备丢失问题。

---

### 问题 2：`StoryLine.isPinned` 未进入服务端 DTO / Repository / 持久化

**严重级别：P0**

#### 现象

客户端 `StoryLine` 模型包含：

- `id`
- `name`
- `recordIds`
- `createdAt`
- `updatedAt`
- `isPinned`
- `ownerId`

并且 `toJson()` / `fromJson()` 都包含 `isPinned`。

但服务端故事线 DTO `storyline.dto.ts` 只有：

- `id`
- `name`
- `recordIds`
- `createdAt`
- `updatedAt`

服务端 `StoryLineRepository` 在 create / batchCreate / update 中处理的字段也只有：

- `name`
- `recordIds`
- `updatedAt`

未处理 `isPinned`。

#### 风险

用户在设备 A 置顶故事线后：

- 云端不会保存该状态
- 设备 B 下载故事线时，`isPinned` 会回退为默认值 `false`
- 置顶排序、首页展示、故事线管理体验会直接不一致

#### 结论

`StoryLine.isPinned` 是**已确认仅客户端存在、未同步到云端**的字段。

---

### 问题 3：`StoryLine.ownerId` 仅存在客户端模型，服务端未落库

**严重级别：P1**

#### 现象

客户端 `StoryLine` 模型中包含 `ownerId`，并写入 `toJson()` / `fromJson()`。

但服务端故事线 DTO / Repository 中均未看到 `ownerId` 字段。

服务端使用的是认证上下文里的 `userId` 来持久化故事线归属，而不是接受客户端传入的 `ownerId`。

#### 风险

这里要分两层看：

1. **如果 `ownerId` 只是客户端本地过滤字段的镜像**
   - 那服务端可通过认证用户归属补足，业务风险较低

2. **如果客户端有任何逻辑依赖 `StoryLine.ownerId` 本地存在且要求服务端下载后原样恢复**
   - 那换设备后该字段无法从云端恢复
   - 客户端逻辑可能依赖默认值或额外重建逻辑

#### 结论

`ownerId` 不是当前最危险的跨设备问题，但它确实是**客户端模型多出来、云端没有正式对齐**的字段，属于模型层不一致。

---

### 问题 4：`User` 模型字段比服务端返回字段更全，部分字段无法稳定跨设备恢复

**严重级别：P1**

#### 客户端 `User` 模型字段

- `id`
- `email`
- `phoneNumber`
- `displayName`
- `avatarUrl`
- `authProvider`
- `isEmailVerified`
- `isPhoneVerified`
- `lastLoginAt`
- `createdAt`
- `updatedAt`

#### 客户端映射行为

客户端 `CustomServerAuthRepository._convertToAppUser()` 会尝试从服务端响应中读取：

- `displayName`
- `avatarUrl`
- `isEmailVerified`
- `isPhoneVerified`
- `updatedAt`

但未读取 `lastLoginAt`。

#### 服务端 DTO 现状

- `AuthResponseDto.user` 中只有：
  - `id`
  - `email`
  - `phoneNumber`
  - `authProvider`
  - `createdAt`

- `UserMeDto` 中有：
  - `displayName`
  - `membership`

- `UserProfileDto` 中有：
  - `displayName`
  - `avatarUrl`

但在本次审计链路内，没有看到一套**统一、稳定、完整**的用户字段返回契约，能够始终覆盖客户端 `User` 模型中的全部字段。

#### 已确认问题点

##### 4.1 `lastLoginAt` 无法从服务端恢复

客户端 `User` 模型有 `lastLoginAt`，但 `_convertToAppUser()` 根本没有读取它。

即使服务端未来返回该字段，当前客户端也不会恢复。

**结论：`lastLoginAt` 当前无法通过现有客户端映射跨设备恢复。**

##### 4.2 `isEmailVerified` / `isPhoneVerified` 依赖服务端是否返回，否则会被默认回退为 `false`

客户端 `_convertToAppUser()` 中：

- `isEmailVerified: data['isEmailVerified'] as bool? ?? false`
- `isPhoneVerified: data['isPhoneVerified'] as bool? ?? false`

只要服务端没返回，就会自动变成 `false`。

而服务端当前公开 DTO 中，并没有看到这两个字段被稳定声明在核心认证响应里。

**风险：**
- 用户真实已验证
- 换设备后客户端因字段缺失而显示未验证
- 导致账号状态展示错误，甚至可能影响某些前端逻辑判断

##### 4.3 `updatedAt` 同样依赖服务端是否返回，否则客户端会退化到 `createdAt`

客户端 `User` 构造函数里：
- `updatedAt` 缺失时会降级为 `createdAt`

这意味着：
- 服务端不返回 `updatedAt`
- 客户端用户对象会保留一个不真实的降级时间

这不一定立刻造成功能错误，但会制造用户元数据不一致。

#### 结论

`User` 模型不是“完全无法同步”，但已经确认存在如下问题：

- `lastLoginAt`：客户端完全不恢复
- `isEmailVerified` / `isPhoneVerified`：若服务端不返回就退回 `false`
- `updatedAt`：若服务端不返回就退回 `createdAt`

这类问题会导致**换设备后账号状态字段不可信**。

---

### 问题 5：用户设置上传后未采用服务端返回值，时间戳可能漂移

**严重级别：P1**

#### 现象

客户端远端仓储 `uploadSettings()`：

- 调用了 `PUT /users/settings`
- 但忽略服务端响应内容
- 直接返回本地传入的 `settings`

而上层 `SyncService.uploadSettings()` / `UserSettingsNotifier._uploadToCloud()` 的设计意图显然是：

- 采用服务端最新设置作为回写结果
- 用服务端时间戳统一本地与云端

#### 风险

如果服务端：
- 自动写入 `updatedAt`
- 自动修正某些组更新时间
- 做了最终规范化

那么客户端当前不会拿到这些服务端最终值。

结果是：
- 本地和服务端的 `updatedAt` 可能不一致
- 分组时间戳可能产生漂移
- 以后做 LWW 合并时，可能增加冲突判断误差

#### 结论

这不是“字段只存在本地”的问题，但它是**同步正确性缺口**，应当修复。

---

## 三、设计风险 / 次级问题（本次不定性为主 bug）

---

### 风险 1：收藏快照只保存在本地，换设备后无法恢复“已删除内容”的完整展示

客户端本地保存：

- `FavoritedPostSnapshot`
- `FavoritedRecordSnapshot`

其用途是：
- 收藏对象被服务端删除后
- 仍可在本地展示旧快照

#### 现状判断

- 收藏关系本身是走云端的
- 本地快照只是补充展示能力

#### 风险

用户换设备后：
- 收藏关系还能从云端恢复
- 但“已删除项目的完整旧内容快照”不会同步过去

#### 结论

这属于**体验级缺口**，不是主业务真相丢失，因此本次不作为 P0/P1 主问题。

---

### 风险 2：客户端模型与服务端 DTO 存在“客户端更宽、服务端更窄”的趋势

已观察到的例子：

- `StoryLine.ownerId`
- `StoryLine.isPinned`
- `User` 的多个元字段

#### 风险

这种趋势会导致：
- 客户端本地字段越积越多
- 服务端 DTO 不跟进
- 最终形成“单机功能正常，换设备就退化”的问题堆积

#### 结论

建议后续做一次**字段级同步契约审计**，为每个模型建立：

- 本地字段表
- 云端字段表
- 上传字段表
- 下载字段表
- 冲突合并策略表

---

## 四、当前确认“已同步较完整”的模块

本次审计中，下列模块没有发现明确的“只存在本地、完全不上云”的问题：

### 1. `UserSettings`
已具备：
- 服务端 DTO
- 用户设置路由
- 服务端 upsert
- 客户端下载 / 上传
- 分组更新时间戳

### 2. `CheckInRecord`
已具备：
- 创建
- 下载
- 删除
- 状态查询

### 3. `AchievementUnlock`
已具备：
- 上传
- 下载

### 4. 收藏关系
已具备：
- 收藏帖子
- 取消收藏帖子
- 收藏记录
- 取消收藏记录
- 服务端获取收藏列表

### 5. Push Token
已具备：
- 注册
- 注销
- 查询

> 注意：以上只代表“主同步链路基本存在”，不等于所有边界情况都完美。

---

## 五、建议优先级

### P0：必须优先修

1. 为 `Membership` 建立完整云端真源
   - 服务端 Prisma / DTO / Route / Controller / Service / Repository
   - 客户端远端仓储与同步入口
   - 登录后下载，变更后上传

2. 为 `StoryLine.isPinned` 建立完整云端字段链路
   - 服务端 DTO 增加 `isPinned`
   - Prisma 落库
   - Repository create / update / query 全链路支持

### P1：尽快修

3. 统一 `User` 字段契约
   - 明确哪些字段由服务端权威返回
   - `lastLoginAt` 加入客户端映射或删除客户端字段
   - `isEmailVerified` / `isPhoneVerified` 不要依赖静默默认值掩盖缺失
   - `updatedAt` 应明确由服务端返回

4. 修复 `uploadSettings()` 返回值问题
   - 使用服务端返回 DTO
   - 回写本地，统一时间戳

### P2：后续优化

5. 评估是否需要跨设备同步收藏快照
   - 如果产品希望“已删除内容也能在所有设备查看旧快照”，则需引入服务端快照策略
   - 如果不需要，则保持现状即可

---

## 六、可直接跟踪的修复任务

- [ ] 为 `Membership` 增加服务端数据模型与 API
- [ ] 为客户端 `Membership` 增加远端仓储与同步逻辑
- [ ] 为 `StoryLine.isPinned` 增加服务端 DTO / Prisma / Repository 支持
- [ ] 评估 `StoryLine.ownerId` 是否仍需要保留在客户端模型中
- [ ] 统一 `User` 返回字段契约
- [ ] 修复 `User.lastLoginAt` 映射缺失
- [ ] 修复 `User.isEmailVerified` / `isPhoneVerified` 的服务端返回缺口
- [ ] 修复 `User.updatedAt` 的服务端返回缺口
- [ ] 让 `uploadSettings()` 使用服务端返回值而不是原样返回本地对象
- [ ] 对所有核心模型补一份字段级同步矩阵文档

---

## 七、本次审计的保守说明

本文件只记录**已经核对到代码证据链**的问题。

以下情况本次刻意没有误报：

- 没有把“本地缓存”一律当作 bug
- 没有把“服务端可能存在但本次没读到的内部实现”武断写成结论
- 没有把所有字段默认都要求双端同步

本文件中的“已确认问题”，都已经过客户端模型、客户端仓储/同步层、服务端 DTO / 路由 / Repository 等至少两层以上核对。

