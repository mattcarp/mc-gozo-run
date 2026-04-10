# GozoRun — Master Todo List

**Race day:** Sunday, April 26, 2026 — 16 days away
**Repo:** github.com/mattcarp/mc-gozo-run
**Website:** runfionarun.com

---

## PRIORITY 1 — Must-Have for Race Day

### F007: Personalized Names
Runner = Mattie, spectator = Fiona/Donal/Shelley.
- [x] Code committed (commit 0cfd696, April 10)
- [x] RunTrackerViewModel: spectator locations named Fiona/Donal/Shelley
- [x] MapView: runner annotation says "Mattie"
- [x] SpectatorView: tracked runner shows "Mattie"
- [ ] **Verify on physical device**

### F008: Real-Time Spectator Tracking
Live GPS via Supabase Realtime. Runner publishes every 5s, spectators subscribe.
- [x] LiveTrackingService.swift (REST + WebSocket, zero deps) — commit 48d2c9c
- [x] Migration SQL at supabase/migration.sql
- [x] App silently disables tracking when Supabase URL is empty
- [x] Exponential backoff on 429 rate limits
- [ ] **Provision Supabase project** (critical path blocker)
- [ ] **Run migration SQL**
- [ ] **Copy URL + anon key into Settings screen on device**
- [ ] **End-to-end test: runner publishes, spectator sees dot move**

### F012: Shared Race Code
Spectators join via code (default: GOZO2026).
- [x] JoinRaceView.swift — race code + spectator name input (commit a7e7ba1)
- [x] Stored in @AppStorage, persists across launches
- [ ] **End-to-end test with two devices**

---

## PRIORITY 2 — Important for Race Experience

### F009: Cheer Delivery
Spectator taps cheer button -> Supabase INSERT -> runner receives via WebSocket -> haptic + voice.
- [x] SpectatorView: sends cheer with spectator name
- [x] ContentView: onChange listener for cheerCount triggers haptic + voice
- [x] Voice says "Cheer received! Keep going Mattie!"
- [ ] **Blocked by Supabase provisioning (F008)**
- [ ] **Test haptic on physical device**

### Supabase Provisioning (critical path for F008 + F009 + F012)
Migration SQL exists at supabase/migration.sql. Two tables:
- gozo_live_positions (runner GPS every 5s)
- gozo_cheers (spectator cheers)
Both have RLS policies (fully open for race day simplicity).

Steps:
- [ ] Create Supabase project (free tier is fine)
- [ ] Run migration SQL in SQL Editor
- [ ] Copy project URL + anon key
- [ ] Enter into Settings screen on runner device
- [ ] Enter into Settings screen on spectator device
- [ ] End-to-end smoke test

### Race Completion Trigger
- [x] ContentView: auto-triggers fullScreenCover when distance >= 21.1km
- [x] Stops tracking, disconnects live service
- [ ] **Test with simulated GPS route**

---

## PRIORITY 3 — Nice to Have

### F010: Theme Rename
Old: Dark Cyan / Dark Default / Light Coral / Spectator Dark
New: Limestone / Mediterranean / Sunset / Terracotta
- [x] All enum cases, display names, and switch references updated (commit 0cfd696)
- [x] SettingsView subtitles: Warm limestone, Cool sea, Golden glow, Bold earth
- [x] Zero old references remain (verified via grep)
- [ ] **Verify on device — AppStorage migration if user had old theme stored**

### F011: Post-Race Completion Screen
- [x] RaceCompleteView.swift — finish flag, stats grid, cheer count
- [x] Closing message: "From the house on Triq il-Knisja, with all our love."
- [ ] **Test on device**

### GitHub Issue #7: Theme Switching
- [x] Code exists and works (ThemeManager + @AppStorage)
- [ ] **Verify live switching on device**

---

## SETUP & INFRASTRUCTURE

### Supabase Project
- [ ] Provision new project (or reuse existing)
- [ ] Run supabase/migration.sql
- [ ] Configure anon key in app

### App Distribution
- [ ] No App Store / TestFlight setup — side-load via Xcode only
- [ ] Apple Developer account needed for device deployment
- [ ] Build and install on Mattie iPhone (runner)
- [ ] Build and install on Fiona iPhone (spectator)

### runfionarun.com
- [x] Website deployed and complete
- [ ] Download button has no App Store link (points nowhere)
- [ ] Real photos — website photo strip commented out ("waiting for real photos")

### Device Testing
- [ ] Multiple features code-complete but NEVER tested on physical iPhone
- [ ] Need two iPhones for full spectator flow test
- [ ] Mac Mini (Matts-Mac-mini.local) available for simulator — currently offline

### Simulator Testing
- [ ] Mac Mini on OpenClaw network — needs powering on
- [ ] Clone repo, open in Xcode, run in simulator
- [ ] Test GPS simulation with .gpx file
- [ ] Test all 4 themes
- [ ] Test spectator mode join flow

---

## COMPLETED FEATURES

- [x] **F001:** GPS Tracking + Stats HUD (distance, time, pace, elevation gain)
- [x] **F002:** Race Route Map — 664-point GPX on satellite MapKit
- [x] **F003:** Voice KM Alerts — proximity-triggered via AVSpeechSynthesizer
- [x] **F004:** 4 Switchable Themes (Limestone, Mediterranean, Sunset, Terracotta)
- [x] **F005:** Elevation Profile Chart (Swift Charts with runner progress marker)
- [x] **F006:** Race Countdown Timer (live to April 26 07:30, then "Race is LIVE!")
- [x] **F007:** Personalized Names (code complete, needs device verification)
- [x] **F008:** Real-Time Spectator Tracking (code complete, needs Supabase provisioning)
- [x] **F009:** Cheer Delivery (code complete, needs Supabase provisioning)
- [x] **F010:** Theme Rename (code complete, needs device verification)
- [x] **F011:** Post-Race Completion Screen (code complete, needs device verification)
- [x] **F012:** Shared Race Code (code complete, needs end-to-end test)
- [x] GitHub Issues #1-6: All closed
- [x] POI Layer: toilets, first aid, marshals, parking, music, turn directions
- [x] KM Splits log tab
- [x] Background GPS (works with screen locked)
- [x] Project tracking: CLAUDE.md, features.json, TODO.md

---

## PROJECT FILES

| File | Purpose |
|------|---------|
| README.md | Setup guide (3 install options) |
| CLAUDE.md | Tech stack, architecture, dev rules |
| TODO.md | This file |
| features.json | Machine-readable feature tracking |
| project.yml | XcodeGen config |
| Package.swift | SPM config |
| supabase/migration.sql | DB schema for live tracking |
| Sources/GozoRun/*.swift | All app source (17 files) |
| route.gpx | 664-point official race route |

**Repo:** github.com/mattcarp/mc-gozo-run
**Website repo:** runfionarun-site (on workshop)

---

*Last updated: 2026-04-10 by coding agent session*
*Combined from: previous editor todo list + April 10 session work*
