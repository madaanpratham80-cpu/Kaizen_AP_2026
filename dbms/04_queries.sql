-- ============================================================
-- KAIZEN: Application SQL Queries
-- CP3 Deliverable: dbms/04_queries.sql
-- ============================================================

-- R1: READ - Login by email and get player stats
SELECT u.id, u.email, u.display_name, u.password_hash, ps.total_xp, ps.health, ps.current_streak
FROM "User" u
JOIN "PlayerState" ps ON ps.user_id = u.id
WHERE u.email = 'arjun@kaizen.app';

-- R2: READ - Get all quests created by a user
SELECT q.id, q.title, q.category, q.pillar, q.difficulty, q.reward_xp, u.display_name
FROM "Quest" q
JOIN "User" u ON u.id = q.user_id
WHERE q.user_id = '11111111-1111-1111-1111-111111111101'
ORDER BY q.reward_xp DESC;

-- R3: READ - Get a user's daily plan and scheduled quests for a date
SELECT dp.plan_date, dp.status, q.title, q.difficulty, q.reward_xp, qo.status AS quest_status
FROM "DayPlan" dp
JOIN "QuestOccurrence" qo ON qo.day_plan_id = dp.id
JOIN "Quest" q ON q.id = qo.quest_id
WHERE dp.user_id = '11111111-1111-1111-1111-111111111101'
  AND dp.plan_date = '2026-11-18';

-- R4: READ - Count completed quests per category for a user
SELECT q.category, COUNT(qo.id) AS completed_quests
FROM "Quest" q
JOIN "QuestOccurrence" qo ON qo.quest_id = q.id
WHERE q.user_id = '11111111-1111-1111-1111-111111111101'
  AND qo.status = 'COMPLETED'
GROUP BY q.category
ORDER BY completed_quests DESC;

-- R5: READ - Get recent XP and health progress events with quest titles
SELECT pe.event_kind, pe.xp_delta, pe.health_delta, pe.created_at, q.title
FROM "ProgressEvent" pe
JOIN "QuestOccurrence" qo ON qo.id = pe.occurrence_id
JOIN "Quest" q ON q.id = qo.quest_id
WHERE pe.user_id = '11111111-1111-1111-1111-111111111101'
ORDER BY pe.created_at DESC
LIMIT 10;

-- R6: READ - Get unlocked achievements and badge details for a user
SELECT a.code, a.title, a.description, a.bonus_xp, ua.unlocked_at
FROM "UserAchievement" ua
JOIN "Achievement" a ON a.code = ua.achievement_code
WHERE ua.user_id = '11111111-1111-1111-1111-111111111101'
ORDER BY ua.unlocked_at DESC;

-- R7: READ - Leaderboard of top 10 users by total XP
SELECT u.display_name, ps.total_xp, ps.current_streak, ps.best_streak
FROM "User" u
JOIN "PlayerState" ps ON ps.user_id = u.id
ORDER BY ps.total_xp DESC
LIMIT 10;

-- R8: READ - Total XP gained per pillar for a user
SELECT q.pillar, SUM(pe.xp_delta) AS total_pillar_xp
FROM "ProgressEvent" pe
JOIN "QuestOccurrence" qo ON qo.id = pe.occurrence_id
JOIN "Quest" q ON q.id = qo.quest_id
WHERE pe.user_id = '11111111-1111-1111-1111-111111111101'
GROUP BY q.pillar
ORDER BY total_pillar_xp DESC;

-- W1: WRITE - Register a new user
INSERT INTO "User" (id, email, display_name, password_hash, timezone)
VALUES ('11111111-1111-1111-1111-111111111999', 'rohan@kaizen.app', 'Rohan Verma', 'hashed_pw_999', 'Asia/Kolkata');

-- W2: WRITE - Create a new daily quest for a user
INSERT INTO "Quest" (id, user_id, title, category, pillar, recurrence, difficulty, target, reward_xp)
VALUES ('22222222-2222-2222-2222-222222222999', '11111111-1111-1111-1111-111111111101', 'Read 10 pages', 'Reading', 'MIND', 'DAILY', 'EASY', 1, 15);

-- W3: WRITE - Mark a scheduled quest occurrence as completed
UPDATE "QuestOccurrence"
SET status = 'COMPLETED', completed_at = NOW()
WHERE id = '44444444-4444-4444-4444-444444444402';

-- W4: WRITE - Log a progress event after completing a quest
INSERT INTO "ProgressEvent" (user_id, occurrence_id, event_kind, xp_delta, health_delta)
VALUES ('11111111-1111-1111-1111-111111111101', '44444444-4444-4444-4444-444444444402', 'QUEST_COMPLETED', 20, 5);

-- W5: WRITE - Update player XP and streak after completing a quest
UPDATE "PlayerState"
SET total_xp = total_xp + 20, current_streak = current_streak + 1
WHERE user_id = '11111111-1111-1111-1111-111111111101';