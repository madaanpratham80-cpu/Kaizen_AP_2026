# KAIZEN — Database Normalization (1NF → 2NF → 3NF → BCNF)

**App:** KAIZEN — Gamified personal routine tracker (quests, XP, health, streaks, achievements)
**DB:** PostgreSQL · **Deliverable:** CP1 `dbms/01_normalization.md`

---

## Unnormalized Form (UNF)

Single flat record per user with repeating groups:
```
KAIZEN_UNF(user_id, email, display_name, timezone,
  {goals[]},
  total_xp, health, streak,
  {sessions[]},
  {quests[ {schedule_versions[ weekdays[] ]} ]},
  {day_plans[ {occurrences[]} ]},
  {progress_events[]},
  {achievements[ eligibility_rule ]})
```
**Anomalies:** Cannot store a user without quests (insert); deleting a user removes global achievement definitions (delete); renaming a user requires updates across every row (update).

---

## 1NF — Eliminate Repeating Groups

Split every nested/array attribute into separate flat tables. Each table gets a primary key.

| Table | Primary Key | Key Functional Dependencies |
|---|---|---|
| `User` | `id` | `id → email, display_name, timezone` |
| `UserGoal` | `(userId, goal)` | All prime — no non-key attributes |
| `PlayerState` | `userId` | `userId → xp, health, streak, state_version` |
| `Session` | `id` | `id → tokenHash, userId, expiresAt` |
| `Quest` | `id` | `id → userId, title, category, pillar` |
| `ScheduleVersion` | `id` | `id → questId, effectiveFrom, recurrence, difficulty, target` |
| `ScheduleWeekday` | `(scheduleId, weekday)` | All prime |
| `DayPreferenceVersion` | `id` | `id → userId, effectiveFrom, effectiveTo` |
| `DayPreferenceRestWeekday` | `(dayPrefId, restWeekday)` | All prime |
| `DayPlan` | `id` | `id → userId, localDate, status, timezone_snapshot` |
| `QuestOccurrence` | `id` | `id → userId, questId, dayPlanId, status, rewardXp` |
| `ProgressEvent` | `id` | `id → userId, sequence, award_key, xpDelta, healthDelta` |
| `CompletionReceipt` | `(userId, operationId)` | `(userId, operationId) → requestHash, responseBody` |
| `Achievement` | `(code, ruleVersion)` | `(code, ruleVersion) → eligibilityRule` |
| `UserAchievement` *(1NF)* | `(userId, achievementCode)` | Also stores `eligibilityRule` — **violates 2NF** |
| `CalendarTimezoneTransition` | `id` | `id → userId, fromTz, toTz, lastOldDate, firstNewDate` |

---

## 2NF — Eliminate Partial Dependencies

**Rule:** Every non-prime attribute must depend on the *whole* candidate key.

**Only violation found:** `UserAchievement` in 1NF stores `eligibilityRule`, which depends only on `(achievementCode, ruleVersion)` — a **partial dependency** on its `(userId, achievementCode)` key.

**Fix:** Split into two tables:

| Table | Primary Key | Attributes |
|---|---|---|
| `Achievement` | `(code, ruleVersion)` | `eligibilityRule` |
| `UserAchievement` | `(userId, achievementCode)` | `ruleVersion`, `unlockedAt`, `qualifyingOccurrenceId`, `qualifyingDayId`, `bonusXp` |

All other tables have single-attribute PKs or all-prime composite keys → no partial dependencies possible.

---

## 3NF — Eliminate Transitive Dependencies

**Rule:** No non-prime attribute may depend on another non-prime attribute (no $X \to Y \to Z$ where $X$ is a PK and $Y$ is not).

Potential transitive chains identified and resolved during decomposition:

| Transitive Chain (Before) | Resolution |
|---|---|
| `occurrence_id → dayPlanId → localDate, timezone_snapshot` | `localDate` stored only in `DayPlan`; `QuestOccurrence` holds only `dayPlanId` FK |
| `event_id → (sealCode, ruleVersion) → eligibilityRule` | `ProgressEvent` stores only `(sealCode, ruleVersion)` FK to `Achievement` |
| `schedule_id → questId → title, category, pillar` | Quest metadata stays in `Quest`; `ScheduleVersion` holds only `questId` FK |
| `userId in PlayerState → userId in User → email, display_name` | `PlayerState` has own PK `userId`; no user metadata duplicated |

No transitive dependencies remain → all 16 tables satisfy **3NF**.

---

## BCNF — Verify Every Determinant is a Superkey

**Rule:** For every non-trivial FD $X \to Y$, $X$ must be a superkey.

| Table | Determinants | Superkey? | BCNF? |
|---|---|---|:---:|
| `User` | `id`, `normalizedEmail` | Both candidate keys | ✅ |
| `PlayerState` | `userId` | Candidate key | ✅ |
| `Session` | `id`, `tokenHash` | Both candidate keys | ✅ |
| `Quest` | `id`, `(userId, id)` | Both candidate keys | ✅ |
| `ScheduleVersion` | `id`, `(userId, questId, effectiveFrom)` | Both candidate keys | ✅ |
| `DayPlan` | `id`, `(userId, localDate)` | Both candidate keys | ✅ |
| `QuestOccurrence` | `id`, `(questId, dayPlanId)` | Both candidate keys | ✅ |
| `ProgressEvent` | `id`, `(userId, sequence)`, `(userId, awardKey)` | All candidate keys | ✅ |
| `Achievement` | `(code, ruleVersion)` | Candidate key | ✅ |
| `UserAchievement` | `(userId, achievementCode)` | Candidate key | ✅ |
| `CompletionReceipt` | `(userId, operationId)` | Candidate key | ✅ |
| All-prime tables | Key itself | Trivially superkeys | ✅ |

**Result: Zero BCNF violations.** The schema achieves BCNF with lossless-join decomposition and full dependency preservation.

---

## Final Schema Overview (16 Tables)

```
User ──< UserGoal
 │
 ├──(1:1)── PlayerState
 ├──────< Session
 ├──────< CalendarTimezoneTransition
 ├──────< CompletionReceipt
 ├──────< DayPreferenceVersion ──< DayPreferenceRestWeekday
 ├──────< Quest ──< ScheduleVersion ──< ScheduleWeekday
 │              └──< QuestOccurrence >──── DayPlan
 │                        │                  │
 └──────< ProgressEvent <────────────────────┘
 │
 └──────< UserAchievement >── Achievement
```
