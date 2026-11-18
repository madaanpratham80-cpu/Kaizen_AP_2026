-- ============================================================
-- KAIZEN: Application SQL Queries
-- CP3 Deliverable: dbms/04_queries.sql
-- ============================================================

-- R1: READ - Login user by email and fetch their player stats
SELECT u.id, u.display_name, u.email, ps.total_xp, ps.health, ps.current_streak
FROM "User" u
JOIN "PlayerState" ps ON u.id = ps.user_id
WHERE u.email = 'arjun@kaizen.app';

-- R2: READ - Get all quests created by a user
SELECT q.id, q.title, q.category, q.pillar, q.difficulty, q.reward_xp
FROM "Quest" q
JOIN "User" u ON u.id = q.user_id
WHERE u.email = 'arjun@kaizen.app'
ORDER BY q.reward_xp DESC;

-- R3: READ - Get a user's daily plan and scheduled quests for a specific date
SELECT dp.plan_date, q.title, q.difficulty, q.reward_xp, qo.status
FROM "DayPlan" dp
JOIN "QuestOccurrence" qo ON dp.id = qo.day_plan_id
JOIN "Quest" q ON q.id = qo.quest_id
WHERE dp.plan_date = '2026-11-18';

-- R4: READ - Get unlocked achievements for a user
SELECT a.code, a.title, a.bonus_xp, ua.unlocked_at
FROM "UserAchievement" ua
JOIN "Achievement" a ON a.code = ua.achievement_code
JOIN "User" u ON u.id = ua.user_id
WHERE u.email = 'arjun@kaizen.app';

-- R5: READ - Get recent XP and health progress events for a user
SELECT pe.event_kind, pe.xp_delta, pe.health_delta, pe.created_at, u.display_name
FROM "ProgressEvent" pe
JOIN "User" u ON u.id = pe.user_id
WHERE u.email = 'arjun@kaizen.app'
ORDER BY pe.created_at DESC;

-- R6: READ - Leaderboard of top 10 players by total XP
SELECT u.display_name, ps.total_xp, ps.current_streak, ps.best_streak
FROM "User" u
JOIN "PlayerState" ps ON u.id = ps.user_id
ORDER BY ps.total_xp DESC
LIMIT 10;

-- W1: WRITE - Register a new user
INSERT INTO "User" (email, display_name, password_hash, timezone)
VALUES ('rohan@kaizen.app', 'Rohan Verma', 'hashed_password_123', 'Asia/Kolkata');

-- W2: WRITE - Create a new quest for a user
INSERT INTO "Quest" (user_id, title, category, pillar, recurrence, difficulty, target, reward_xp)
VALUES ('11111111-1111-1111-1111-111111111101', 'Morning Run', 'Fitness', 'BODY', 'DAILY', 'MEDIUM', 1, 20);

-- W3: WRITE - Mark a quest occurrence as completed
UPDATE "QuestOccurrence"
SET status = 'COMPLETED', completed_at = NOW()
WHERE id = '44444444-4444-4444-4444-444444444401';

-- W4: WRITE - Add XP and increase streak after completing a quest
UPDATE "PlayerState"
SET total_xp = total_xp + 20, current_streak = current_streak + 1
WHERE user_id = '11111111-1111-1111-1111-111111111101';