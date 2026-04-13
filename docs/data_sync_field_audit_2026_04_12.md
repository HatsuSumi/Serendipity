# 数据字段同步兜底审计（2026-04-12）

> 审计目标：继续核对当前项目中“本地字段 / 云端字段 / 同步链路”是否一致，重点找出**只存在本地、换设备后会丢失**的字段。
>
> 本轮审计方法：
> - 先看 Flutter 客户端模型与本地持久化
> - 再看远端仓储请求体 / 响应体
> - 最后核对 Node.js 服务端 DTO / Service / Repository / Prisma
>
> 结论分级：
> - **已确认同步完整**：本地字段已经进入远端请求、服务端持久化、下载返回链路
> - **本地缓存但非主真相**：本地有额外缓存，但不属于必须上云的主业务真相
> - **仍需关注**：不是“字段只存在本地”，但仍可能造成同步语义偏差或局部体验退化

---

## 一、总体结论

这轮兜底复核后，之前最担心的两类字段现在都已经有完整云端链路：

- `Membership`：已具备客户端远端接口、服务端路由、Service、Repository、Prisma 持久化
- `StoryLine.isPinned`：已进入客户端上传、服务端 DTO、Repository 持久化、下载返回

同时，核心可同步数据链路已经覆盖：

- `EncounterRecord`
- `StoryLine`
- `CheckInRecord`
- `AchievementUnlock`
- `UserSettings`
- `Membership`
- 收藏关系
- `PushToken` 注册状态
- 认证返回的 `User` 基本元数据

**本轮没有再发现新的 P0 级“只存在本地、完全不上云”的核心字段缺口。**

当前更值得继续盯的是两类问题：

1. **客户端模型里存在一些“本地辅助字段 / 本地缓存字段”**，它们不是服务端真相，但需要明确标注，避免后续误判为漏同步。
2. **个别链路存在语义不完全对齐的点**，例如认证接口返回的用户字段集合不完全一致、收藏已删除快照跨设备不保证等。

---

## 二、已确认同步完整的主干模块

---

### 1. `Membership` 已具备完整云端链路

#### 客户端侧

客户端远端仓储 `CustomServerRemoteDataRepository` 已提供：

- `downloadMembership(String userId)`
- `activateMembership(String userId, double monthlyAmount)`

客户端本地模型 `Membership` 包含：

- `id`
- `userId`
- `tier`
- `status`
- `startedAt`
- `expiresAt`
- `monthlyAmount`
- `autoRenew`
- `createdAt`
- `updatedAt`

并且能够从服务端 JSON 正常反序列化。

#### 服务端侧

服务端已具备：

- Prisma `Membership` model
- `GET /users/membership`
- `POST /users/membership`
- `MembershipRepository`
- `UserService.getMembership()`
- `UserService.activateMembership()`
- `MembershipDto`

`Membership` 已真实落库到 PostgreSQL，不再是纯本地状态。

#### 结论

旧结论“`Membership` 只有本地存储，没有云端真源”已经过期，当前代码里**不成立**。

---

### 2. `StoryLine.isPinned` 已进入完整同步链路

#### 客户端侧

客户端 `StoryLine.toJson()` 会上传：

- `isPinned`

远端仓储：

- `uploadStoryLine()` 上传 `isPinned`
- `updateStoryLine()` 上传 `isPinned`
- `uploadStoryLines()` 批量上传 `isPinned`
- `downloadStoryLines()` / `downloadStoryLinesSince()` 会从响应恢复 `isPinned`

#### 服务端侧

服务端已具备：

- Prisma `StoryLine.isPinned`
- `CreateStoryLineDto.isPinned`
- `UpdateStoryLineDto.isPinned`
- `StoryLineRepository.create()` 持久化 `isPinned`
- `StoryLineRepository.batchCreate()` 持久化 `isPinned`
- `StoryLineRepository.update()` 持久化 `isPinned`
- `StoryLineService.toResponseDto()` 返回 `isPinned`

#### 结论

旧结论“`StoryLine.isPinned` 只在客户端存在、服务端未落库”已经过期，当前代码里**不成立**。

---

### 3. `EncounterRecord` 主字段链路完整

客户端 `EncounterRecord` 的主字段包括：

- `timestamp`
- `location.{latitude, longitude, address, placeName, placeType, province, city, area}`
- `description`
- `tags`
- `emotion`
- `status`
- `storyLineId`
- `ifReencounter`
- `conversationStarter`
- `backgroundMusic`
- `weather`
- `isPinned`
- `createdAt`
- `updatedAt`

这些字段已经进入：

- 客户端上传请求体
- 服务端 `record.dto.ts`
- Prisma `Record` model
- 服务端下载返回

#### 说明

`ownerId` 仍是客户端本地辅助字段；服务端以认证用户 `userId` 作为归属真相，不接受客户端上传的 `ownerId` 作为持久化字段。

这属于**本地辅助归属字段**，不是新的漏同步结论。

---

### 4. `StoryLine.userId` 下载链路完整

客户端 `StoryLine` 模型使用 `userId` 表示本地归属。

服务端 `StoryLineResponseDto` 已返回：

- `userId`
- `name`
- `recordIds`
- `isPinned`
- `createdAt`
- `updatedAt`

因此当前不再存在“故事线归属字段完全下不来”的问题。

---

### 5. `UserSettings` 同步链路完整

`UserSettings` 已具备：

- 客户端上传 `toServerDto()`
- 客户端下载 `fromServerDto()`
- 服务端 `UserSettingsDto` / `UpdateUserSettingsDto`
- 服务端 upsert
- 分组时间戳：
  - `themeUpdatedAt`
  - `notificationsUpdatedAt`
  - `checkInUpdatedAt`
  - `communityUpdatedAt`

并且客户端远端仓储 `uploadSettings()` 现在已经使用服务端响应重新构造 `UserSettings`，不是简单回传本地对象。

#### 结论

旧结论“用户设置上传后忽略服务端返回值”在当前代码里**已修复**。

---

### 6. `User` 基本元数据链路已比之前完整

客户端 `User` 模型字段：

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

当前客户端认证仓储 `_convertToAppUser()` 已经明确读取：

- `displayName`
- `avatarUrl`
- `isEmailVerified`
- `isPhoneVerified`
- `lastLoginAt`
- `createdAt`
- `updatedAt`

服务端 `toAuthUserDto()` / `toUserProfileDto()` 也已经统一了大部分字段来源。

#### 结论

旧结论“客户端完全不恢复 `lastLoginAt`”在当前代码里**已不成立**。

---

## 三、本地缓存但不属于主真相的字段

---

### 1. `EncounterRecord.ownerId`

客户端本地 `EncounterRecord` 仍保存 `ownerId`。

但服务端记录归属的真相是：

- 认证上下文里的 `userId`
- Prisma `Record.userId`

客户端上传时带了 `ownerId`，服务端 DTO / 持久化并不使用它。

#### 定性

这更像是**本地离线归属辅助字段**，不是必须一比一上云的业务真相。

#### 风险

如果后续有人把 `ownerId` 误当成服务端正式契约字段，会造成认知混乱。

---

### 2. `StoryLine.userId`

这里和旧文档里提到的 `ownerId` 已经不是同一个事实：

- 当前客户端模型是 `userId`
- 服务端响应也返回 `userId`

因此它不再是同步缺口。

真正需要注意的是：

- 服务端并不是信任客户端上传的 `userId`
- 真正的归属仍由认证用户决定

这是合理设计，不算问题。

---

### 3. 收藏已删除对象的本地快照

本地存储里存在：

- `favorited_record_snapshots`
- `favorited_post_snapshots`

服务端收藏接口也会返回：

- `deletedPosts`
- `deletedPostIds`
- `deletedRecords`
- `deletedRecordIds`

#### 定性

收藏关系本身已经上云。

“已删除对象的完整快照展示能力”更偏向体验增强，不等同于主业务真相。

#### 风险

跨设备时，历史删除快照的呈现完整度仍可能受限于：

- 服务端快照是否完整保留
- 客户端本地缓存是否仍在

这属于**体验级风险**，不是主同步断链。

---

## 四、仍需关注的点

---

### 1. 删除同步的“发起删除”与“其他设备感知删除”不是同一件事

当前客户端已经把几类删除动作在**发起删除的设备**上直接推到云端：

- `RecordsProvider.deleteRecord()` 会调用 `SyncService.deleteRecord()`，同时联动删除对应社区帖子
- `StoryLinesProvider.deleteStoryLine()` 会调用 `SyncService.deleteStoryLine()`
- `SyncService.refreshMembership()` 会在云端无会员记录时删除本地缓存
- 登录用户签到状态整体上以服务端为准，本地只是缓存

但自动同步阶段还存在一个非常关键的语义差异：

- **增量同步只能下载“仍然存在且 updatedAt 变了的数据”**
- **被远端删除的数据不会出现在增量结果里**
- 因此当前实现里，**其他设备无法靠普通增量同步感知删除**

`SyncService._downloadRemoteData()` 的注释已经明确写明：

- `lastSyncTime != null` 的增量同步**无法感知删除操作**
- 跨设备删除同步依赖**下一次全量同步**

而真正执行“把远端已删除内容从本地清掉”的逻辑，确实只出现在：

- `_mergeRecords(..., isFullSync: true)`
- `_mergeStoryLines(..., isFullSync: true)`
- `_mergeCheckIns(..., isFullSync: true)`

也就是：只有**全量同步**时，客户端才会把“云端已经不存在”的本地数据删掉。

#### 进一步确认：当前客户端几乎没有稳定的“手动全量同步”入口

继续复核客户端触发链路后，可以确认：

- `appStartup`：读取 `getLastSyncTime(user.id)`，通常走增量同步
- `networkReconnect`：读取 `getLastSyncTime(user.id)`，通常走增量同步
- `login`：会员版会下载，但同样先读 `lastSyncTime`，通常还是增量同步
- `register`：`skipDownload: true`，只上传不下载
- 免费版 `login`：`skipDownload: true`，根本不下载云端数据
- `ManualSyncDialog`：同样先读 `getLastSyncTime(user.id)`，然后调用 `syncAllData()`，**仍然是增量同步**

这意味着当前代码里：

- **手动同步不是强制全量同步**
- **同步说明文案把手动同步描述为增量同步，这与实现一致**
- 删除要想跨设备真正落地，通常只能依赖：
  - `lastSyncTime` 丢失
  - `getLastSyncTime()` 读取失败后回退到 `null`
  - 某处显式传入 `lastSyncTime: null` 或清空同步时间

换句话说，**“删除传播依赖全量同步”虽然在逻辑上成立，但当前产品里缺少稳定、显式、可预期的全量同步触发器**。

进一步看本地存储实现还能确认：

- `lastSyncTime` 以 `last_sync_time_<userId>` 持久化保存
- `clearAuthData()` 登出时只删除 `user_settings`
- **登出不会清掉该用户的 `lastSyncTime`**

这意味着：

- 同一账号登出再登录，通常仍会沿用旧的 `lastSyncTime`
- 这条路径也**不会自然把增量同步切回全量同步**

#### 服务端侧进一步确认

服务端增量接口当前也没有提供删除墓碑：

- `RecordRepository.findByUserId()`：条件为 `updatedAt > lastSyncTime`
- `StoryLineRepository.findByUserId()`：条件为 `updatedAt > lastSyncTime`
- `CheckInRepository.findByUserId()`：条件为 `updatedAt > lastSyncTime`

同时，本轮没有发现：

- `deletedAt`
- `isDeleted`
- tombstone / soft delete 表达
- “删除事件流”式的增量返回

因此现在不是“客户端没接墓碑”，而是**前后端整体都没有设计删除增量传播机制**。

#### 结论

这不是“删除根本没上云”，而是：

- **删除发起端：已直删云端，语义成立**
- **其他设备：删除感知并不实时，且不保证发生在下一次普通自动同步**
- **当前连手动同步也通常只是增量，同步模型里缺少稳定的全量删除传播入口**

这是当前同步模型里最需要被明确记录的删除语义风险。

#### 影响范围

受这条规则影响的主干数据包括：

- `EncounterRecord`
- `StoryLine`
- `CheckInRecord`

其中：

- 记录 / 故事线：删除动作本身会打到云端，但他端清理依赖全量同步
- 签到：虽然日常是服务端权威读取，但 `syncAllData()` 的通用合并逻辑里，真正的“远端不存在则删本地”也只发生在全量同步
- 免费版登录：由于 `skipDownload: true`，连增量下载都不会发生，更谈不上删除传播

---

### 2. 认证返回与 `/auth/me` 返回的用户字段集合并不完全相同

当前服务端存在至少两类用户返回：

- `AuthResponseDto.user`
- `UserMeDto`

其中 `/auth/me` 还额外包含：

- `membership`

而登录 / 注册响应主要返回认证用户本体。

#### 风险

这不是字段不上云的问题，而是**不同接口返回契约不完全一致**。

后续如果客户端把某些页面逻辑建立在“任意用户接口都一定返回同一批字段”之上，仍有可能出现：

- 某些字段只在部分接口能拿到
- 页面首次进入与刷新后的字段来源不一致

#### 建议

后续把用户返回契约继续收口：

- 明确“认证态用户最小契约”
- 明确“完整个人资料契约”
- 明确“带会员扩展信息的当前用户契约”

---

### 3. `Membership` 客户端仍然同时存在本地仓储和远端接口

当前客户端既有：

- 本地 `MembershipRepository`
- 远端 `downloadMembership()` / `activateMembership()`

#### 风险

这不代表出 bug，但说明会员在客户端存在“双层来源”：

- 本地缓存 / 本地读取
- 服务端真源

如果上层 Provider 没有明确规定“何时信任远端、何时只读本地缓存”，以后仍可能出现短暂状态不一致。

#### 建议

后续把会员状态明确为：

- **服务端真源**
- 本地只做缓存
- 页面刷新或登录后优先拉远端并覆盖本地

---

### 3. `PushToken` 客户端模型比当前展示模型更窄

客户端上报 `PushTokenRegistration` 只有：

- `token`
- `platform`
- `timezone`

而服务端真实返回 `PushTokenResponseDto` 还包括：

- `id`
- `isActive`
- `lastUsedAt`
- `invalidatedAt`
- `invalidReason`
- `createdAt`
- `updatedAt`

当前客户端只在“查询注册状态”侧使用了一个精简展示模型 `RepositoryPushTokenRecord`。

#### 风险

现在不算缺口，因为客户端并没有声明自己要完整持有 `PushToken` 领域模型。

但如果后续要做更细的推送管理页，就要避免：

- 服务端字段已经很多
- 客户端却只接了一半

---

## 六、Provider / 页面层复核结论

### 1. `MembershipProvider`：当前以本地缓存为读模型，但刷新与全量同步都回到服务端真源

现状：

- `build()` 先读本地 `MembershipRepository`
- `refresh()` 会调用 `SyncService.refreshMembership()`
- `syncAllData()` 里也会执行 `_syncMembership()`
- `refreshMembership()` 明确采用“云端存在则覆盖本地、云端不存在则删除本地”的策略

结论：

- **会员真源已经是服务端**
- Provider 层只是先消费本地缓存，避免页面首屏阻塞
- 这不属于假同步

仍需关注：

- `MembershipNotifier.build()` 首次渲染仍优先显示本地缓存
- 在同步完成前，页面可能短暂展示旧会员状态
- 但 `syncCompletedProvider` 已被 watch，同步完成后会自动重建，风险可控

### 2. `UserSettingsProvider`：本地先写、服务端回写覆盖，职责清晰

现状：

- 所有设置修改都先落本地
- 然后统一走 `_uploadToCloud()`
- `_uploadToCloud()` 通过 `SyncService.uploadSettings()` 上传
- 上传成功后会用**服务端返回的最新设置**覆盖本地
- 登录同步时，`SyncService._syncUserSettings()` 会做字段级 LWW 合并

结论：

- **不存在“Provider 永远优先信本地旧值、不吃服务端结果”的问题**
- 当前设计是“本地交互态 + 服务端最终态回写”，同步语义成立

### 3. `AuthProvider`：登录/注册后会触发同步，登出时会清认证态并刷新数据 Provider

现状：

- 登录 / 注册成功后触发 `_triggerSync()`
- 会刷新记录、故事线、签到、成就、社区等数据 Provider
- 登出前会先注销 push token
- 登出后清认证态，再刷新各业务 Provider

结论：

- **认证态切换后，主业务 Provider 会重新走当前用户链路**
- 没看到“用户切换后继续长期持有前一个用户云端数据”的明显问题

### 4. `FavoritesProvider`：服务端列表为主，本地快照只用于已删除项目兜底展示

现状：

- 初始化时并发从服务端拉收藏帖子 / 收藏记录
- `deletedPosts` / `deletedRecords` 优先使用云端返回快照
- 只有云端没给完整快照时，才退回本地快照
- 收藏 / 取消收藏时本地快照只是辅助缓存

结论：

- **收藏主真相仍在服务端**
- 本地快照只是“已删除内容展示增强”，不是假同步来源

### 5. Push 诊断与注册状态：当前已直接核对服务端，不是只看本地状态

现状：

- `PushTokenSyncService` 在登录后自动注册 token
- 推送诊断页会实时读取：
  - 设备通知权限
  - 当前设备 token
  - 服务端已注册 token 列表
  - 最近一次同步结果
- `PushDiagnosticsSnapshot.fromRemoteStatus()` 会直接判断“当前 token 是否已注册到服务端”

结论：

- **Push 诊断不是假本地状态**
- 当前页面展示已经把“设备侧现状”和“服务端注册现状”对齐了

---

## 七、当前审计结论汇总

### 已确认同步完整

- `Membership`
- `StoryLine.isPinned`
- `StoryLine.userId` 下载返回
- `EncounterRecord` 主业务字段
- `CheckInRecord`
- `AchievementUnlock`
- `UserSettings`
- 收藏关系
- `PushToken` 注册状态主链路
- `User.lastLoginAt` 当前客户端已可恢复
- `MembershipProvider` / `SyncService` 已以服务端作为会员真源
- `UserSettingsProvider` 已采用服务端回写结果作为最终状态
- Push 诊断页已直接核对服务端 token 注册状态

### 本地辅助字段 / 本地缓存

- `EncounterRecord.ownerId`
- 收藏删除快照的本地缓存
- 会员与设置的本地缓存副本（用于首屏与离线访问，不是最终真相）

### 仍需关注但不是“只存在本地不上云”

- 用户不同接口返回契约仍未完全收口
- 会员页面首次渲染会先消费本地缓存，同步完成前可能短暂显示旧状态
- `PushToken` 客户端展示模型仍是精简版

---

## 六、最终结论

**这轮继续兜底审计后，没有再发现新的核心字段“只存在本地、完全不上云”的明确缺口。**

前一版文档里最严重的两个结论：

- `Membership` 纯本地
- `StoryLine.isPinned` 不上云

在当前代码版本里都已经被代码事实推翻，必须视为**过期结论**。

现在项目的主要问题已经从“主字段漏同步”转向：

- 契约收口
- 本地缓存与远端真源职责边界
- 个别模块的字段集合是否需要继续统一

后续再做下一轮审计，最值得继续深挖的是：

1. 上层 Provider 是否始终以服务端为会员真源
2. 用户相关接口的返回契约是否要统一
3. 客户端是否还有别的“本地辅助字段”被误认为云端正式字段
