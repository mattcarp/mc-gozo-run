# GozoRun — Master Todo List

**Race day:** Saturday, April 26, 2026 — 15 days away
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
- [x] LiveTrackingService.swift (REST + WebSocket, zero deps)
- [x] Migration SQL at supabase/migration.sql
- [x] App silently disables tracking when Supabase URL is empty
- [x] Exponential backoff on 429 rate limits
- [x] **Supabase project provisioned** (cnmzahjpvxtnsvhnguqe.supabase.co)
- [x] **Migration SQL run, tables exist** (verified April 10 session)
- [x] **Credentials hardcoded as defaults** in LiveTrackingService
- [ ] **End-to-end test: runner publishes, spectator sees dot move** (needs 2 devices)

### F012: Shared Race Code
Spectators join via code (default: GOZO2026).
- [x] JoinRaceView.swift — race code + spectator name input
- [x] Stored in @AppStorage, persists across launches
- [ ] **End-to-end test with two devices**

---

## PRIORITY 2 — Important for Race Experience

### F003+: Voice Coaching (UPGRADED April 11)
- [x] **Premium voice selection** with fallback chain (GB/AU enhanced > Siri > compact)
- [x] **AVAudioSession ducking** — plays over music/podcasts seamlessly
- [x] **Natural conversational announcements** with randomized variety
- [x] **Milestone celebrations** at 5K, 10K, halfway, 15K, 18K, 19K, 20K, 21K
- [x] **Water station proximity alerts** (250m radius)
- [x] **Cheer-received voice announcements**
- [x] **Natural pace formatting**: "five thirty per K" not "5 minutes 30 seconds per kilometre"
- [x] **Race start and completion announcements**
- [x] Audio background mode in Info.plist
- [ ] **Download enhanced voices on physical device** (Settings > Accessibility > Spoken Content)

### F009: Cheer Delivery
- [x] SpectatorView: sends cheer with spectator name
- [x] ContentView: onChange listener for cheerCount triggers haptic + voice
- [x] Voice uses VoiceAlertManager for consistent quality
- [ ] **Test haptic on physical device**

### Demo Mode (UPGRADED April 11)
- [x] DemoModeView.swift — full race auto-run with Look Around street view
- [x] Uses VoiceAlertManager for natural voice coaching throughout
- [x] Auto-triggers RaceCompleteView with confetti at 21.1km
- [x] --demo launch argument for direct Demo Mode entry (great for TV screencast)
- [x] Particle confetti animation (60 colored pieces) on race completion

### Race Completion Trigger
- [x] ContentView: auto-triggers fullScreenCover when distance >= 21.1km
- [x] Stops tracking, disconnects live service
- [x] Voice announcement: "You did it! Twenty-one point one kilometres..."
- [x] 3-second delay then full-screen celebration view
- [ ] **Test with simulated GPS on device**

---

## PRIORITY 3 — Nice to Have

### F010: Theme Rename
Old: Dark Cyan / Dark Default / Light Coral / Spectator Dark
New: Limestone / Mediterranean / Sunset / Terracotta
- [x] All enum cases, display names, and switch references updated
- [x] SettingsView subtitles: Warm limestone, Cool sea, Golden glow, Bold earth
- [ ] **Verify on device**

### F011: Post-Race Completion Screen
- [x] RaceCompleteView.swift — finish flag, stats grid, cheer count
- [x] Closing message: "From the house on Triq il-Knisja, with all our love."
- [x] Particle confetti animation added (April 11)
- [ ] **Test on device**

---

## SETUP & INFRASTRUCTURE

### Supabase Project
- [x] Project provisioned (cnmzahjpvxtnsvhnguqe.supabase.co)
- [x] Migration SQL run, tables verified
- [x] Credentials hardcoded as defaults in LiveTrackingService

### App Distribution
- [ ] No App Store / TestFlight — side-load via Xcode only
- [ ] Apple Developer account needed for device deployment
- [ ] Build and install on Mattie iPhone 16 (runner)
- [ ] Build and install on another iPhone (spectator)

### runfionarun.com
- [x] Website deployed and complete
- [x] Download button shows toast: "Available race day — April 26th!"
- [x] Look Ahead feature card added (April 10)
- [ ] Real photos — website photo strip commented out ("waiting for real photos")

### Device Testing
- [ ] Multiple features code-complete but NEVER tested on physical iPhone
- [ ] Need two iPhones for full spectator flow test
- [ ] Mac Mini (100.114.183.100 via Tailscale) available for simulator

### Mac Mini Access
- **Tailscale IP:** 100.114.183.100
- **User:** mattcarp
- **Simulator:** iPhone 17 (1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1)
- **NOTE:** "workshop" SSH alias points to NUC (Linux), NOT the Mac Mini
- [ ] Mac Mini SSH key not registered with GitHub (commits are local only)

---

## COMPLETED FEATURES

- [x] **F001:** GPS Tracking + Stats HUD (distance, time, pace, elevation gain)
- [x] **F002:** Race Route Map — 664-point GPX on satellite MapKit
- [x] **F003:** Voice KM Alerts — natural coach with premium voice selection (April 11 upgrade)
- [x] **F004:** 4 Switchable Themes (Limestone, Mediterranean, Sunset, Terracotta)
- [x] **F005:** Elevation Profile Chart (Swift Charts with runner progress marker)
- [x] **F006:** Race Countdown Timer (live to April 26 07:30, then "Race is LIVE!")
- [x] **F007:** Personalized Names (code complete)
- [x] **F008:** Real-Time Spectator Tracking (code complete, Supabase provisioned)
- [x] **F009:** Cheer Delivery (code complete, uses VoiceAlertManager)
- [x] **F010:** Theme Rename (code complete)
- [x] **F011:** Post-Race Completion Screen with confetti
- [x] **F012:** Shared Race Code (code complete)
- [x] POI Layer: toilets, first aid, marshals, parking, music, turn directions
- [x] KM Splits log tab
- [x] Background GPS (works with screen locked)
- [x] Look Ahead street view (MKLookAroundScene)
- [x] Demo Mode with voice coaching + auto-completion
- [x] Water station proximity voice alerts

---

## PROJECT FILES

| File | Purpose |
|------|---------|
| README.md | Setup guide (3 install options) |
| CLAUDE.md | Tech stack, architecture, dev rules |
| TODO.md | This file |
| features.json | Machine-readable feature tracking |
| Package.swift | SPM config |
| supabase/migration.sql | DB schema for live tracking |
| Sources/GozoRun/*.swift | All app source (18 files) |
| route.gpx | 664-point official race route |
| claude-progress.txt | Session-by-session progress log |

**Repo:** github.com/mattcarp/mc-gozo-run
**Website repo:** runfionarun-site (on NUC/workshop)

---

*Last updated: 2026-04-11 by coding agent session*
*Voice coaching upgrade, Demo Mode polish, confetti animation*
