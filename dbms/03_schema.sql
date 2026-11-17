-- ============================================================
-- KAIZEN — Gamified Personal Routine Tracker
-- PostgreSQL Schema (dbms/03_schema.sql)
-- CP2 deliverable for AP Repo
-- ============================================================

-- Enums
CREATE TYPE day_status        AS ENUM ('OPEN', 'ACTIVE', 'MISSED', 'REST', 'EMPTY');
CREATE TYPE occurrence_status AS ENUM ('PENDING', 'COMPLETED');
CREATE TYPE quest_difficulty  AS ENUM ('EASY', 'MEDIUM', 'HARD');

-- ============================================================
-- 1. User
-- ============================================================
CREATE TABLE "User" (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    "normalizedEmail" TEXT          NOT NULL,
    "displayName"     TEXT          NOT NULL,
    "passwordHash"    TEXT          NOT NULL,
    timezone          TEXT          NOT NULL,
    goals             TEXT[]        NOT NULL DEFAULT '{}',
    "createdAt"       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT "User_normalizedEmail_key" UNIQUE ("normalizedEmail")
);

-- ============================================================
-- 2. Session
-- ============================================================
CREATE TABLE "Session" (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    "tokenHash" CHAR(64)    NOT NULL,
    "userId"    UUID        NOT NULL,
    "expiresAt" TIMESTAMPTZ NOT NULL,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "Session_tokenHash_key" UNIQUE ("tokenHash"),
    CONSTRAINT "Session_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

CREATE INDEX "Session_userId_idx"    ON "Session"("userId");
CREATE INDEX "Session_expiresAt_idx" ON "Session"("expiresAt");

-- ============================================================
-- 3. PlayerState  (1-to-1 with User)
-- ============================================================
CREATE TABLE "PlayerState" (
    "userId"              UUID  PRIMARY KEY,
    "totalXp"             INT   NOT NULL DEFAULT 0,
    health                INT   NOT NULL DEFAULT 70,
    "currentStreak"       INT   NOT NULL DEFAULT 0,
    "bestStreak"          INT   NOT NULL DEFAULT 0,
    "lastFinalizedDate"   DATE,
    "stateVersion"        INT   NOT NULL DEFAULT 0,
    "nextEventSequence"   INT   NOT NULL DEFAULT 1,

    CONSTRAINT "PlayerState_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

-- ============================================================
-- 4. CalendarTimezoneTransition
-- ============================================================
CREATE TABLE "CalendarTimezoneTransition" (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"        UUID        NOT NULL,
    "fromTimezone"  TEXT        NOT NULL,
    "toTimezone"    TEXT        NOT NULL,
    "lastOldDate"   DATE        NOT NULL,
    "firstNewDate"  DATE        NOT NULL,
    "gapStartsAt"   TIMESTAMPTZ NOT NULL,
    "effectiveAt"   TIMESTAMPTZ NOT NULL,
    "appliedAt"     TIMESTAMPTZ,

    CONSTRAINT "CalendarTimezoneTransition_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

CREATE INDEX "CalendarTimezoneTransition_userId_appliedAt_idx"
    ON "CalendarTimezoneTransition"("userId", "appliedAt");

-- ============================================================
-- 5. Quest
-- ============================================================
CREATE TABLE "Quest" (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"                UUID        NOT NULL,
    title                   TEXT        NOT NULL,
    category                TEXT        NOT NULL,
    pillar                  TEXT        NOT NULL,
    "archivedAt"            TIMESTAMPTZ,
    "archiveEffectiveDate"  DATE,
    version                 INT         NOT NULL DEFAULT 1,

    CONSTRAINT "Quest_userId_id_key"  UNIQUE ("userId", id),
    CONSTRAINT "Quest_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

CREATE INDEX "Quest_userId_archivedAt_idx" ON "Quest"("userId", "archivedAt");

-- ============================================================
-- 6. ScheduleVersion
-- ============================================================
CREATE TABLE "ScheduleVersion" (
    id              UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"        UUID                NOT NULL,
    "questId"       UUID                NOT NULL,
    "effectiveFrom" DATE                NOT NULL,
    "effectiveTo"   DATE,
    recurrence      TEXT                NOT NULL,
    weekdays        INT[]               NOT NULL DEFAULT '{}',
    title           TEXT                NOT NULL,
    category        TEXT                NOT NULL,
    pillar          TEXT                NOT NULL,
    difficulty      quest_difficulty    NOT NULL,
    target          INT                 NOT NULL,
    "ruleVersion"   INT                 NOT NULL,

    CONSTRAINT "ScheduleVersion_userId_questId_effectiveFrom_key"
        UNIQUE ("userId", "questId", "effectiveFrom"),
    CONSTRAINT "ScheduleVersion_quest_fkey"
        FOREIGN KEY ("userId", "questId") REFERENCES "Quest"("userId", id) ON DELETE RESTRICT
);

-- ============================================================
-- 7. DayPreferenceVersion
-- ============================================================
CREATE TABLE "DayPreferenceVersion" (
    id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"        UUID    NOT NULL,
    "effectiveFrom" DATE    NOT NULL,
    "effectiveTo"   DATE,
    "restWeekdays"  INT[]   NOT NULL DEFAULT '{}',

    CONSTRAINT "DayPreferenceVersion_userId_effectiveFrom_key"
        UNIQUE ("userId", "effectiveFrom"),
    CONSTRAINT "DayPreferenceVersion_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

-- ============================================================
-- 8. DayPlan
-- ============================================================
CREATE TABLE "DayPlan" (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"                UUID        NOT NULL,
    "localDate"             DATE        NOT NULL,
    "timezoneSnapshot"      TEXT        NOT NULL,
    "startsAtUtc"           TIMESTAMPTZ NOT NULL,
    "deadlineUtc"           TIMESTAMPTZ NOT NULL,
    status                  day_status  NOT NULL,
    "priorityId"            UUID,
    "priorityLockedAt"      TIMESTAMPTZ,
    "plannedCount"          INT         NOT NULL DEFAULT 0,
    "healthGainAccounted"   INT         NOT NULL DEFAULT 0,
    "streakApplied"         BOOLEAN     NOT NULL DEFAULT FALSE,
    "closedAt"              TIMESTAMPTZ,

    CONSTRAINT "DayPlan_userId_localDate_key" UNIQUE ("userId", "localDate"),
    CONSTRAINT "DayPlan_userId_id_key"        UNIQUE ("userId", id),
    CONSTRAINT "DayPlan_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

-- ============================================================
-- 9. QuestOccurrence
-- ============================================================
CREATE TABLE "QuestOccurrence" (
    id            UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"      UUID                NOT NULL,
    "questId"     UUID                NOT NULL,
    "dayPlanId"   UUID                NOT NULL,
    planned       BOOLEAN             NOT NULL,
    status        occurrence_status   NOT NULL DEFAULT 'PENDING',
    "completedAt" TIMESTAMPTZ,
    title         TEXT                NOT NULL,
    category      TEXT                NOT NULL,
    pillar        TEXT                NOT NULL,
    difficulty    quest_difficulty    NOT NULL,
    target        INT                 NOT NULL,
    "rewardXp"    INT                 NOT NULL,
    "ruleVersion" INT                 NOT NULL,

    CONSTRAINT "QuestOccurrence_userId_id_key"          UNIQUE ("userId", id),
    CONSTRAINT "QuestOccurrence_questId_dayPlanId_key"  UNIQUE ("questId", "dayPlanId"),
    CONSTRAINT "QuestOccurrence_userId_dayPlanId_id_key" UNIQUE ("userId", "dayPlanId", id),
    CONSTRAINT "QuestOccurrence_quest_fkey"
        FOREIGN KEY ("userId", "questId") REFERENCES "Quest"("userId", id) ON DELETE RESTRICT,
    CONSTRAINT "QuestOccurrence_dayPlan_fkey"
        FOREIGN KEY ("userId", "dayPlanId") REFERENCES "DayPlan"("userId", id) ON DELETE RESTRICT
);

CREATE INDEX "QuestOccurrence_dayPlanId_status_idx" ON "QuestOccurrence"("dayPlanId", status);

-- DayPlan priority self-reference (added after QuestOccurrence exists)
ALTER TABLE "DayPlan"
    ADD CONSTRAINT "DayPlan_priority_fkey"
        FOREIGN KEY ("userId", id, "priorityId")
        REFERENCES "QuestOccurrence"("userId", "dayPlanId", id)
        ON DELETE NO ACTION ON UPDATE NO ACTION
        DEFERRABLE INITIALLY DEFERRED;

-- ============================================================
-- 10. ProgressEvent
-- ============================================================
CREATE TABLE "ProgressEvent" (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId"        UUID        NOT NULL,
    sequence        INT         NOT NULL,
    "awardKey"      TEXT        NOT NULL,
    kind            TEXT        NOT NULL,
    "occurrenceId"  UUID,
    "dayId"         UUID,
    "sealCode"      TEXT,
    "xpDelta"       INT         NOT NULL,
    "healthDelta"   INT         NOT NULL,
    "ruleVersion"   INT         NOT NULL,
    "recordedAt"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "ProgressEvent_userId_sequence_key"  UNIQUE ("userId", sequence),
    CONSTRAINT "ProgressEvent_userId_awardKey_key"  UNIQUE ("userId", "awardKey"),
    CONSTRAINT "ProgressEvent_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT,
    CONSTRAINT "ProgressEvent_day_fkey"
        FOREIGN KEY ("userId", "dayId") REFERENCES "DayPlan"("userId", id) ON DELETE RESTRICT,
    CONSTRAINT "ProgressEvent_occurrence_fkey"
        FOREIGN KEY ("userId", "occurrenceId") REFERENCES "QuestOccurrence"("userId", id) ON DELETE RESTRICT
);

CREATE INDEX "ProgressEvent_userId_recordedAt_idx" ON "ProgressEvent"("userId", "recordedAt");

-- ============================================================
-- 11. CompletionReceipt  (idempotency ledger)
-- ============================================================
CREATE TABLE "CompletionReceipt" (
    "userId"        UUID        NOT NULL,
    "operationId"   UUID        NOT NULL,
    "requestHash"   CHAR(64)    NOT NULL,
    "responseBody"  JSONB       NOT NULL,
    "createdAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT "CompletionReceipt_pkey" PRIMARY KEY ("userId", "operationId"),
    CONSTRAINT "CompletionReceipt_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT
);

CREATE INDEX "CompletionReceipt_createdAt_idx" ON "CompletionReceipt"("createdAt");

-- ============================================================
-- 12. Achievement  (global definitions)
-- ============================================================
CREATE TABLE "Achievement" (
    code              TEXT    NOT NULL,
    "ruleVersion"     INT     NOT NULL,
    "eligibilityRule" JSONB   NOT NULL,

    CONSTRAINT "Achievement_pkey" PRIMARY KEY (code, "ruleVersion")
);

-- ============================================================
-- 13. UserAchievement
-- ============================================================
CREATE TABLE "UserAchievement" (
    "userId"                    UUID        NOT NULL,
    "achievementCode"           TEXT        NOT NULL,
    "ruleVersion"               INT         NOT NULL,
    "unlockedAt"                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "qualifyingOccurrenceId"    UUID,
    "qualifyingDayId"           UUID,
    "bonusXp"                   INT         NOT NULL,

    CONSTRAINT "UserAchievement_pkey"
        PRIMARY KEY ("userId", "achievementCode"),
    CONSTRAINT "UserAchievement_userId_fkey"
        FOREIGN KEY ("userId") REFERENCES "User"(id) ON DELETE RESTRICT,
    CONSTRAINT "UserAchievement_achievement_fkey"
        FOREIGN KEY ("achievementCode", "ruleVersion")
        REFERENCES "Achievement"(code, "ruleVersion") ON DELETE RESTRICT,
    CONSTRAINT "UserAchievement_qualifyingDay_fkey"
        FOREIGN KEY ("userId", "qualifyingDayId")
        REFERENCES "DayPlan"("userId", id) ON DELETE RESTRICT,
    CONSTRAINT "UserAchievement_qualifyingOccurrence_fkey"
        FOREIGN KEY ("userId", "qualifyingOccurrenceId")
        REFERENCES "QuestOccurrence"("userId", id) ON DELETE RESTRICT
);
