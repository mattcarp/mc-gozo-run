-- GozoRun Live Tracking Tables
-- Run this in your Supabase SQL Editor

-- Runner position updates (written every 5s during race)
CREATE TABLE IF NOT EXISTS gozo_live_positions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    race_code text NOT NULL DEFAULT 'GOZO2026',
    runner_name text NOT NULL,
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    distance_km double precision DEFAULT 0,
    pace text DEFAULT '--:--',
    elapsed_seconds integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

-- Cheers sent from spectators to runner
CREATE TABLE IF NOT EXISTS gozo_cheers (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    race_code text NOT NULL DEFAULT 'GOZO2026',
    spectator_name text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Enable Realtime on both tables
ALTER PUBLICATION supabase_realtime ADD TABLE gozo_live_positions;
ALTER PUBLICATION supabase_realtime ADD TABLE gozo_cheers;

-- RLS: allow anonymous inserts and reads (race day simplicity)
ALTER TABLE gozo_live_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE gozo_cheers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read positions" ON gozo_live_positions FOR SELECT USING (true);
CREATE POLICY "Anyone can insert positions" ON gozo_live_positions FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can read cheers" ON gozo_cheers FOR SELECT USING (true);
CREATE POLICY "Anyone can insert cheers" ON gozo_cheers FOR INSERT WITH CHECK (true);

-- Index for fast lookups by race code
CREATE INDEX IF NOT EXISTS idx_positions_race_code ON gozo_live_positions(race_code, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cheers_race_code ON gozo_cheers(race_code, created_at DESC);

-- Auto-cleanup: positions older than 24h (optional cron)
-- SELECT cron.schedule('cleanup-gozo-positions', '0 * * * *', $$DELETE FROM gozo_live_positions WHERE created_at < now() - interval '24 hours'$$);
