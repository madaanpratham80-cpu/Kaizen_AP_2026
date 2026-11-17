# KAIZEN — Database Normalization (1NF → 2NF → 3NF → BCNF)

**App:** KAIZEN — Gamified Personal Progression & Routine Tracker  
**Database:** PostgreSQL 15+ · **Deliverable:** CP1 `dbms/01_normalization.md`

---

## 1. Unnormalized Form (UNF)

A single unnormalized record capturing user profile, stats, commitments, daily executions, and rewards:

```text
KAIZEN_UNF (
    user_id, email, display_name, password_hash, timezone, created_at,
    total_xp, health, current_streak, best_streak,
    { quests [quest_id, title, category, pillar, recurrence, difficulty, target, reward_xp] },
    { day_plans [day_plan_id, plan_date, status, planned_count,
        { occurrences [occurrence_id, quest_id, occ_status, completed_at] } ] },
    { progress_events [event_id, occurrence_id, event_kind, xp_delta, health_delta, event_time] },
    { achievements [achievement_code, title, description, bonus_xp, unlocked_at] }
)
```

**Anomalies:**
- **Insert:** Cannot define global achievements or quests without registering a user.
- **Delete:** Deleting a user deletes global achievement definitions and execution logs.
- **Update:** Changing an achievement's bonus XP or a quest's title requires updates across redundant duplicate rows.

---

## 2. First Normal Form (1NF)

**Rule:** Eliminate repeating groups and nested arrays; ensure atomic attribute values and assign unique primary keys.

| Table | Primary Key | Key Functional Dependencies |
|---|---|---|
| `User` | `id` | `id → email, display_name, password_hash, timezone, created_at` |
| `PlayerState` | `user_id` | `user_id → total_xp, health, current_streak, best_streak` |
| `Quest` | `id` | `id → user_id, title, category, pillar, recurrence, difficulty, target, reward_xp` |
| `DayPlan` | `id` | `id → user_id, plan_date, status, planned_count` |
| `QuestOccurrence` | `id` | `id → quest_id, day_plan_id, status, completed_at` |
| `ProgressEvent` | `id` | `id → user_id, occurrence_id, event_kind, xp_delta, health_delta, created_at` |
| `UserAchievement` *(1NF)* | `(user_id, achievement_code)` | `(user_id, achievement_code) → unlocked_at, title, description, bonus_xp` |

> **2NF Violation Identified in 1NF:** In `UserAchievement(1NF)`, `achievement_code → title, description, bonus_xp`. Since `achievement_code` is a proper subset of candidate key `(user_id, achievement_code)`, these non-prime attributes are partially dependent.

---

## 3. Second Normal Form (2NF)

**Rule:** Eliminate partial dependencies. Every non-prime attribute must depend on the whole candidate key.

**Decomposition:** Split `UserAchievement(1NF)` into:
1. `Achievement` (`code` PK, `title`, `description`, `bonus_xp`)
2. `UserAchievement` (`(user_id, achievement_code)` PK, `unlocked_at`)

All other tables have single-attribute primary keys (`id` or `user_id`), naturally satisfying 2NF.

---

## 4. Third Normal Form (3NF)

**Rule:** Eliminate transitive dependencies ($X \to Y \to Z$ where $X$ is key and $Y$ is non-key).

| Potential Transitive Dependency | Resolution Applied |
|---|---|
| `occurrence_id → day_plan_id → plan_date` | `plan_date` stays in `DayPlan`; `QuestOccurrence` stores only FK `day_plan_id` |
| `occurrence_id → quest_id → title, reward_xp` | Quest metadata remains in `Quest`; `QuestOccurrence` stores only FK `quest_id` |
| `event_id → user_id → email, timezone` | User profile stored solely in `User`; `ProgressEvent` stores only FK `user_id` |
| `user_id in PlayerState → user_id in User` | 1:1 relation isolated to keep high-frequency state updates off auth profile |

All non-prime attributes now depend directly and non-transitively on candidate keys. The schema satisfies **3NF**.

---

## 5. Boyce-Codd Normal Form (BCNF)

**Rule:** For every non-trivial functional dependency $X \to Y$, determinant $X$ must be a superkey.

| Table | Candidate Keys | Determinants ($X$) | Superkey? | BCNF? |
|---|---|---|:---:|:---:|
| `User` | `{id}`, `{email}` | `id`, `email` | Yes | ✅ |
| `PlayerState` | `{user_id}` | `user_id` | Yes | ✅ |
| `Quest` | `{id}` | `id` | Yes | ✅ |
| `DayPlan` | `{id}`, `{user_id, plan_date}` | `id`, `(user_id, plan_date)` | Yes | ✅ |
| `QuestOccurrence` | `{id}`, `{quest_id, day_plan_id}` | `id`, `(quest_id, day_plan_id)` | Yes | ✅ |
| `ProgressEvent` | `{id}` | `id` | Yes | ✅ |
| `Achievement` | `{code}` | `code` | Yes | ✅ |
| `UserAchievement` | `{user_id, achievement_code}` | `(user_id, achievement_code)` | Yes | ✅ |

**Assessment:** Every determinant is a candidate key. The decomposition is lossless and preserves all functional dependencies.

---

## 6. Final Schema Overview (8 Core Tables)

```
User ──(1:1)── PlayerState
 │
 ├──(1)────< Quest ──────────< QuestOccurrence >───(1) DayPlan
 ├──(1)────< ProgressEvent <─────────┘                    │
 └──(1)────< UserAchievement >───(1) Achievement         │
                 ▲                                        │
                 └────────────────────────────────────────┘
```
