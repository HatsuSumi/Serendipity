# Statistics Refactoring Plan

## Background

The current statistics page in `serendipity_app` is implemented as a hybrid of:

- local-first personal data aggregation
- authenticated account data display
- remote-backed favorites data
- premium gating via local membership state

After reviewing the current Flutter client and the existing server code, the key architectural fact is:

> The statistics page is **not** currently a server-side reporting page.
> Most statistics are derived from local Hive-backed domain data through Riverpod providers and `StatisticsService`.

At the same time, the project supports multi-device usage. That means some statistics should eventually reflect **account-global truth**, not only the current device snapshot.

This document defines:

1. the current source of every statistics field
2. which fields should remain local for now
3. which fields should move to backend-owned statistics
4. a phased refactoring plan aligned with the current project architecture

---

## Codebase facts confirmed during review

### Statistics page entry

- `serendipity_app/lib/features/statistics/statistics_page.dart`
- `serendipity_app/lib/features/statistics/widgets/basic_statistics_section.dart`
- `serendipity_app/lib/features/statistics/widgets/advanced_statistics_section.dart`

### Main statistics providers

- `serendipity_app/lib/core/providers/statistics_provider.dart`
- `basicStatisticsProvider`
- `statisticsOverviewProvider`
- `advancedStatisticsProvider`

### Local aggregation service

- `serendipity_app/lib/core/services/statistics_service.dart`

### Local data sources used by statistics

- `recordsProvider` -> `RecordRepository` -> `StorageService(Hive)`
- `storyLinesProvider` -> `StoryLineRepository` -> `StorageService(Hive)`
- `checkInProvider` -> `CheckInRepository` -> `StorageService(Hive)`
- `membershipProvider` -> `MembershipRepository` -> `StorageService(Hive)`

### Remote-backed data already used by statistics

- `favoritesProvider` -> `CommunityRepository` -> remote favorite APIs
- account registration time comes from `authProvider.current user.createdAt`

### Server-side status confirmed

In `serendipity_server`, favorite APIs already exist:

- `src/routes/favorite.routes.ts`
- `src/controllers/favoriteController.ts`
- `src/services/favoriteService.ts`

But there is **no existing statistics API** in the server at the time of writing.

---

## Current statistics source map

This section describes the statistics page as it works today.

## A. Overview section

### 1. Account registration time
- UI field: `账号注册时间`
- Current source: `authProvider -> currentUser?.createdAt`
- Nature: account metadata
- Current ownership: remote/account domain, displayed from client auth state

### 2. Record count
- UI field: `记录数量`
- Current source: `recordsProvider`
- Aggregation: local
- Current ownership: local Hive replica of personal records

### 3. Story line count
- UI field: `故事线数量`
- Current source: `storyLinesProvider`
- Aggregation: local
- Current ownership: local Hive replica

### 4. Total check-in days
- UI field: `累计签到天数`
- Current source: `checkInProvider / CheckInRepository.getTotalCheckInDays`
- Aggregation: local
- Current ownership: local Hive replica

### 5. Longest consecutive check-in streak
- UI field: `最长连续签到天数`
- Current source: `CheckInRepository.calculateLongestConsecutiveStreak`
- Aggregation: local
- Current ownership: local Hive replica

### 6. Linked story line record count
- UI field: `已关联故事线记录`
- Current source: `recordsProvider`
- Aggregation: local in `statisticsOverviewProvider`

### 7. Unlinked story line record count
- UI field: `未关联故事线记录`
- Current source: `recordsProvider`
- Aggregation: local in `statisticsOverviewProvider`

### 8. Favorited record count
- UI field: `已收藏记录`
- Current source: `favoritesProvider`
- Aggregation: remote result count
- Ownership: remote favorite relationship, local snapshot only for deleted item fallback

### 9. Favorited post count
- UI field: `已收藏帖子`
- Current source: `favoritesProvider`
- Aggregation: remote result count
- Ownership: remote favorite relationship, local snapshot only for deleted item fallback

### 10. Pinned record count
- UI field: `已置顶记录`
- Current source: `recordsProvider`
- Aggregation: local

### 11. Pinned story line count
- UI field: `已置顶故事线`
- Current source: `storyLinesProvider`
- Aggregation: local

---

## B. Basic statistics section

All of the following currently come from:

- `recordsProvider`
- `StatisticsService.calculateBasicStatistics(records)`

### Status counts
- total records
- missed count
- avoid count
- reencounter count
- met count
- reunion count
- farewell count
- lost count

### Derived field
- success rate

### Frequency-based fields
- most common place name
- most common place type
- most common province
- most common city
- most common area
- most common hour
- most common weather

All are currently local-first and computed on the client.

---

## C. Advanced statistics section

All advanced charts currently depend on:

- `advancedStatisticsProvider`
- `recordsProvider`
- `StatisticsService.calculateAdvancedStatistics(records)`

### Current fields
- tag cloud
- monthly record distribution
- emotion intensity distribution
- weather distribution
- place type distribution
- monthly success rate trend
- field ranking details

These are currently local-only aggregations over local record replicas.

---

## Architectural decision

## Final target direction

Because the project supports multi-device usage, the long-term statistical truth should be:

> **Backend-owned account-global statistics** for high-value summary metrics.

However, because the current app is strongly local-first and already has mature local aggregation for record-based charts, the correct refactor is **not** to move everything to backend immediately.

### Final decision

Use a **hybrid statistics architecture**:

- backend owns account-global summary truth
- local keeps high-interaction chart computation for now
- UI consumes a unified statistics model and must not care whether the source is local or remote

---

## Field ownership policy

## Category 1: Backend-owned now or first

These fields should be treated as backend-owned truth because users will naturally interpret them as account-global metrics across devices.

### Overview metrics to migrate first

1. account registration time
2. total record count
3. total story line count
4. total check-in days
5. longest consecutive check-in streak
6. linked story line record count
7. unlinked story line record count
8. favorited record count
9. favorited post count
10. pinned record count
11. pinned story line count
12. status counts
13. overall success rate

### Why these should move first

- small response payload
- easy to expose as one overview DTO
- highly visible to users
- users expect cross-device consistency
- low interactivity compared with charts
- relatively stable business definitions

---

## Category 2: Keep local for now

These fields should remain local in the short term.

### Advanced chart metrics

1. tag cloud
2. monthly record distribution
3. emotion intensity distribution
4. weather distribution
5. place type distribution
6. monthly success rate trend
7. field ranking details
8. most common place / province / city / area / hour / weather / place type

### Why they stay local first

- high UI interaction frequency
- filter/range switching is frequent
- current local implementation is already complete
- backend API design would be much larger and more complex
- the main product value loss from temporary device-local variance is lower than for top-level overview numbers

---

## Category 3: Conditional / later migration candidates

The following fields are currently local but are legitimate candidates for later backend migration when one of these conditions becomes true:

- strong multi-device consistency complaints
- much larger record volume
- need for Web/admin analytics parity
- need for exported reports
- need for reusable server-side BI/reporting capability

### Later candidates
- most common place family fields
- monthly record charts
- success rate trend
- all field ranking dimensions

---

## Recommended target architecture

## 1. Separate overview from charts

Instead of a single local-heavy statistics path, split statistics into two domains.

### A. Overview statistics
Purpose:
- account-global summary numbers
- multi-device consistency first

Ownership:
- backend truth source
- local cache optional

### B. Chart statistics
Purpose:
- interactive visual exploration
- range switching
- local responsiveness first

Ownership:
- short-term local
- long-term optional backend migration

---

## 2. Keep UI model unified

The widget layer should not know where the data comes from.

### Keep using domain models such as
- `StatisticsOverview`
- `AdvancedStatistics`

But replace the current direct provider composition with a repository/facade split.

Recommended new application-layer structure:

- `StatisticsOverviewRepository`
- `StatisticsChartsRepository`
- or a single `StatisticsRepository` with explicit methods:
  - `getOverview()`
  - `getCharts()`

Then providers depend on this abstraction instead of directly composing local providers in UI-facing code.

---

## 3. Introduce local and remote data sources explicitly

Recommended structure:

- `LocalStatisticsDataSource`
- `RemoteStatisticsDataSource`
- `StatisticsRepository`

### Repository responsibility

- decide when to use remote truth
- decide when to fall back to local calculation
- unify DTO -> domain model mapping
- hide local/remote source selection from Riverpod consumers

---

## Phased refactoring plan

## Phase 0: No product behavior change, only architectural preparation

### Goals
- avoid breaking current statistics page
- isolate statistics access behind repository abstraction
- preserve current local calculations

### Tasks
1. create statistics repository abstraction in app layer
2. move current local calculation entry into `LocalStatisticsDataSource`
3. let providers read repository instead of directly orchestrating everything themselves
4. keep all current UI models unchanged

### Output
- no visible feature change
- codebase prepared for remote overview introduction

---

## Phase 1: Migrate overview statistics to backend

### Backend work
Add a new endpoint such as:

- `GET /statistics/overview`

Recommended response shape:

```json
{
  "registeredAt": "2026-03-20T12:34:56.000Z",
  "totalRecords": 123,
  "storyLineCount": 11,
  "linkedRecordCount": 70,
  "unlinkedRecordCount": 53,
  "linkedRecordPercentage": 56.9,
  "unlinkedRecordPercentage": 43.1,
  "totalCheckInDays": 45,
  "totalCheckInStartDate": "2026-01-01T00:00:00.000Z",
  "totalCheckInEndDate": "2026-03-23T00:00:00.000Z",
  "longestCheckInStreakDays": 10,
  "longestCheckInStreakStartDate": "2026-02-05T00:00:00.000Z",
  "longestCheckInStreakEndDate": "2026-02-14T00:00:00.000Z",
  "favoritedRecordCount": 6,
  "favoritedPostCount": 4,
  "pinnedRecordCount": 8,
  "pinnedStoryLineCount": 2,
  "statusCounts": {
    "missed": 10,
    "avoid": 5,
    "reencounter": 7,
    "met": 40,
    "reunion": 12,
    "farewell": 3,
    "lost": 1
  },
  "successRate": 42.3,
  "sourceVersion": 1,
  "computedAt": "2026-03-23T10:00:00.000Z"
}
```

### Client work
1. implement `RemoteStatisticsDataSource.getOverview()`
2. map remote DTO to existing `StatisticsOverview`
3. switch `statisticsOverviewProvider` to repository-backed flow
4. keep local fallback only when remote unavailable

### Important note
At this phase, the app should treat overview values as account-global truth when logged in.

---

## Phase 2: Keep advanced charts local but route through repository

### Goals
- preserve current UX
- stop binding UI directly to local statistics service
- prepare future backend migration without changing widgets again

### Tasks
1. implement `StatisticsRepository.getAdvancedStatistics()`
2. internally call local chart aggregation first
3. keep `advancedStatisticsProvider` repository-backed

### Result
- current UX preserved
- charts remain fast
- later migration becomes incremental

---

## Phase 3: Optional backend chart migration

Only do this if justified by product or scale.

### Candidate endpoints
- `GET /statistics/charts/monthly-records`
- `GET /statistics/charts/success-rate-trend`
- `GET /statistics/charts/distributions`
- `GET /statistics/charts/tag-cloud`
- `GET /statistics/charts/field-rankings`

### Warning
Do not expose many narrowly-coupled widget-specific endpoints. Prefer domain-level chart endpoints with stable semantics.

---

## Source of truth rules

To avoid future confusion, define explicit truth rules.

## Logged-in user

### Overview metrics
- source of truth: backend
- local role: cache / fallback / skeleton substitute only

### Chart metrics
- source of truth in short term: local synced replica
- future option: backend

## Logged-out user

### All metrics
- source of truth: local only
- no remote statistics

This distinction is important because the app supports offline and non-authenticated usage.

---

## Consistency rules that must be documented before backend migration

Before implementing remote statistics, these rules must be frozen and shared between client and server.

## Required business definitions

1. Which timestamp drives monthly charts?
   - `record.timestamp` or `record.createdAt`

2. Which timezone is authoritative?
   - user local timezone, fixed business timezone, or UTC

3. Are soft-deleted or orphaned entities counted?

4. How are weather multi-values counted?
   - one record can contribute multiple weather buckets or only one

5. How is `successRate` defined exactly?
   - currently `(met + reunion) / totalRecords * 100`

6. How are ties handled for “most common” fields?

7. Should pinned statistics be account-global across devices?
   - current answer should be yes if pin state sync remains cross-device

8. Are offline unsynced records included in overview while logged in?
   - recommended answer: no for remote truth, yes for local fallback only

Without these rules, moving statistics to backend will create silent inconsistencies.

---

## Recommended provider refactor in Flutter

## Current problem

`statisticsOverviewProvider` currently mixes:
- local record aggregation
- story line aggregation
- check-in repository direct reads
- auth user metadata
- favorites remote provider

This works, but it couples UI-facing provider logic too tightly to multiple domain sources.

## Recommended target

### Introduce
- `statisticsRepositoryProvider`
- `StatisticsRepository`
- `LocalStatisticsDataSource`
- `RemoteStatisticsDataSource`

### Provider responsibilities after refactor
- `statisticsOverviewProvider`: only asks repository for overview
- `advancedStatisticsProvider`: only asks repository for advanced statistics
- repository decides local vs remote strategy

This keeps statistics policy out of widget-facing provider code.

---

## Recommended server additions

The server currently has favorite APIs but no statistics APIs.

### First server milestone
Add:
- `GET /statistics/overview`

### Data sources server-side
The server implementation should aggregate from:
- records
- story lines
- check-ins
- favorites
- user account metadata

### Good server design constraint
Do not make the first version over-generalized. Start with overview only.

---

## Non-goals

This refactor should **not** do the following in the first iteration:

1. do not move all charts to backend at once
2. do not redesign widget models
3. do not build a generic BI/reporting engine
4. do not couple endpoints to card/widget names
5. do not break logged-out local statistics support

---

## Final recommendation summary

## Final architectural position

For `Serendipity`, the correct long-term statistics strategy is:

> **Backend-owned overview truth + local-first advanced charts, with a unified statistics repository hiding source differences.**

## Immediate implementation recommendation

### Migrate to backend first
- account registration time
- overview counts
- status counts
- success rate
- check-in summary
- favorites summary
- pinned summary
- linked/unlinked summary

### Keep local for now
- tag cloud
- distributions
- trend charts
- field rankings
- most-common derived chart-like frequency fields

### Refactor first, migrate second
Do not directly replace providers with ad hoc remote calls.
Create repository/data-source layers first, then move fields by category.

---

## Checklist

### Flutter app
- [x] add statistics repository abstraction (`IStatisticsDataSource`)
- [x] add local statistics data source (`LocalStatisticsDataSource`)
- [x] add remote statistics data source (`RemoteStatisticsDataSource`)
- [x] move overview provider to repository (`statisticsOverviewProvider` → `StatisticsRepository`)
- [x] move advanced statistics provider to repository (`advancedStatisticsProvider` → `StatisticsRepository`)
- [x] keep current models stable (`StatisticsOverview`, `BasicStatistics`, `AdvancedStatistics` unchanged)
- [x] narrow catch clauses in `StatisticsRepository` to infrastructure errors only (rethrow others)
- [x] add `getLocalBasicStatistics()` to `IStatisticsDataSource` and implement in `LocalStatisticsDataSource`
- [x] merge local `mostCommon*` fields into remote overview via `_mergeLocalBasicIntoRemote()`

### Server
- [x] add overview statistics route (`GET /statistics/overview`)
- [x] add overview statistics controller / service / repository logic
- [x] freeze business definitions for all overview fields (see Consistency rules section)
- [ ] return a versioned DTO (`sourceVersion`, `computedAt` — deferred, not yet needed)

### Product/architecture
- [x] document fallback behavior when remote overview fails (graceful degradation to local)
- [ ] document timezone rule (deferred — currently using local device timezone)
- [x] document success rate rule (`(met + reunion) / totalRecords * 100`)
- [ ] document favorite count rule (deferred)
- [ ] document orphan/deleted entity counting rule (deferred)

---

## Implementation notes

### Deviation: `mostCommon*` fields temporarily broken after Phase 1

During Phase 1 implementation, `RemoteStatisticsDataSource._mapOverviewDto` hardcoded all 7
local-aggregation fields (`mostCommonPlace`, `mostCommonPlaceType`, `mostCommonProvince`,
`mostCommonCity`, `mostCommonArea`, `mostCommonHour`, `mostCommonWeather`) as `null`.

This caused logged-in users to see "未知" for those fields, which was a regression from
pre-refactor behaviour.

**Root cause**: The fields were (correctly) classified as "keep local for now" in this document,
but the implementation forgot to re-inject them after fetching the remote overview.

**Fix applied** (commit `e713da7`):
- Added `getLocalBasicStatistics({required String? userId})` to `IStatisticsDataSource`
- `LocalStatisticsDataSource` implements it by delegating to `StatisticsService.calculateBasicStatistics`
- `RemoteStatisticsDataSource` throws `UnsupportedError` (not applicable)
- `StatisticsRepository._fetchOverview` now calls `_local.getLocalBasicStatistics` after a
  successful remote fetch and merges the 7 fields via `_mergeLocalBasicIntoRemote()`
- All other fields in the remote response remain authoritative

**Current field ownership (logged-in)**:

| Field group | Source |
|---|---|
| Count/summary fields (records, check-ins, story lines, favorites, pinned, status counts, success rate) | Server (`GET /statistics/overview`) |
| `mostCommonPlace/PlaceType/Province/City/Area/Hour/Weather` | Local (`StatisticsService.calculateBasicStatistics`) |
| `registeredAt` | Server (via `currentUser.createdAt`) |

### `sourceVersion` / `computedAt` not implemented

The planned DTO fields `sourceVersion` and `computedAt` are not yet returned by the server
nor consumed by the client. This is intentional — they are only useful when:
- multiple app versions coexist in production
- client-side caching of overview data is introduced
- UI needs to display data freshness

Deferred until one of the above conditions is met.

