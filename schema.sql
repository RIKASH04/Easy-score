-- ============================================================
-- Easy-Score Database Schema
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================

-- Enable uuid-ossp extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Drop existing tables (clean slate)
-- ============================================================
DROP TABLE IF EXISTS scores CASCADE;
DROP TABLE IF EXISTS events CASCADE;
DROP TABLE IF EXISTS judges CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;

-- ============================================================
-- 1. Rooms Table
-- ============================================================
CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    secret_code VARCHAR(8) UNIQUE NOT NULL,
    judge_count_required INT NOT NULL CHECK (judge_count_required IN (2, 3)),
    created_by TEXT NOT NULL,  -- admin email
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================
-- 2. Judges Table (room membership)
-- ============================================================
CREATE TABLE judges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(email, room_id)
);

-- ============================================================
-- 3. Events Table
-- ============================================================
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT '',
    participant_count INT NOT NULL CHECK (participant_count >= 1 AND participant_count <= 30),
    created_by TEXT NOT NULL,  -- judge email
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);


-- ============================================================
-- 4. Scores Table (no participant names — numbered only)
-- ============================================================
CREATE TABLE scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    judge_email TEXT NOT NULL,
    participant_number INT NOT NULL CHECK (participant_number >= 1),
    score INT NOT NULL CHECK (score >= 0 AND score <= 100),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    UNIQUE(event_id, judge_email, participant_number)
);

-- ============================================================
-- Enable Realtime for all tables
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE judges;
ALTER PUBLICATION supabase_realtime ADD TABLE events;
ALTER PUBLICATION supabase_realtime ADD TABLE scores;

-- ============================================================
-- Row Level Security
-- ============================================================
ALTER TABLE rooms   ENABLE ROW LEVEL SECURITY;
ALTER TABLE judges  ENABLE ROW LEVEL SECURITY;
ALTER TABLE events  ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores  ENABLE ROW LEVEL SECURITY;

-- Rooms policies
CREATE POLICY "rooms_select" ON rooms FOR SELECT USING (true);
CREATE POLICY "rooms_insert" ON rooms FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Judges policies
CREATE POLICY "judges_select" ON judges FOR SELECT USING (true);
CREATE POLICY "judges_insert" ON judges FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Events policies
CREATE POLICY "events_select" ON events FOR SELECT USING (true);
CREATE POLICY "events_insert" ON events FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Scores policies
CREATE POLICY "scores_select" ON scores FOR SELECT USING (true);
CREATE POLICY "scores_insert" ON scores FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "scores_update" ON scores FOR UPDATE USING (auth.role() = 'authenticated');
