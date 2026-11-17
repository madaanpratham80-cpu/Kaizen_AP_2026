-- ============================================================
-- KAIZEN: Database Schema (PostgreSQL)
-- CP2 Deliverable: dbms/03_schema.sql
-- ============================================================

-- 1. Users
CREATE TABLE "User" (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         VARCHAR(255) UNIQUE NOT NULL,
    display_name  VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    timezone      VARCHAR(50)  NOT NULL DEFAULT 'UTC',
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- 2. Player State (1-to-1 Gamification State)
CREATE TABLE "PlayerState" (
    user_id        UUID PRIMARY KEY REFERENCES "User"(id) ON DELETE CASCADE,
    total_xp       INT NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
    health         INT NOT NULL DEFAULT 70 CHECK (health BETWEEN 0 AND 100),
    current_streak INT NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    best_streak    INT NOT NULL DEFAULT 0 CHECK (best_streak >= 0)
);

-- 3. Quests (Commitment Templates)
CREATE TABLE "Quest" (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    title      VARCHAR(200) NOT NULL,
    category   VARCHAR(50)  NOT NULL,
    pillar     VARCHAR(50)  NOT NULL,
    recurrence VARCHAR(50)  NOT NULL DEFAULT 'DAILY',
    difficulty VARCHAR(20)  NOT NULL DEFAULT 'MEDIUM',
    target     INT          NOT NULL DEFAULT 1,
    reward_xp  INT          NOT NULL DEFAULT 10
);

CREATE INDEX idx_quest_user ON "Quest"(user_id);

-- 4. Day Plans (Daily Agendas)
CREATE TABLE "DayPlan" (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    plan_date     DATE NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    planned_count INT NOT NULL DEFAULT 0,
    UNIQUE (user_id, plan_date)
);

-- 5. Quest Occurrences (Daily Quest Execution)
CREATE TABLE "QuestOccurrence" (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quest_id     UUID NOT NULL REFERENCES "Quest"(id) ON DELETE CASCADE,
    day_plan_id  UUID NOT NULL REFERENCES "DayPlan"(id) ON DELETE CASCADE,
    status       VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    completed_at TIMESTAMPTZ,
    UNIQUE (quest_id, day_plan_id)
);

CREATE INDEX idx_occurrence_plan ON "QuestOccurrence"(day_plan_id, status);

-- 6. Progress Events (Ledger of XP / Health Changes)
CREATE TABLE "ProgressEvent" (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    occurrence_id UUID REFERENCES "QuestOccurrence"(id) ON DELETE SET NULL,
    event_kind    VARCHAR(50) NOT NULL,
    xp_delta      INT NOT NULL DEFAULT 0,
    health_delta  INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_user ON "ProgressEvent"(user_id, created_at);

-- 7. Achievements (Badge Catalog)
CREATE TABLE "Achievement" (
    code        VARCHAR(50) PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    bonus_xp    INT NOT NULL DEFAULT 50
);

-- 8. User Achievements (Earned Badges)
CREATE TABLE "UserAchievement" (
    user_id          UUID NOT NULL REFERENCES "User"(id) ON DELETE CASCADE,
    achievement_code VARCHAR(50) NOT NULL REFERENCES "Achievement"(code) ON DELETE CASCADE,
    unlocked_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, achievement_code)
);
