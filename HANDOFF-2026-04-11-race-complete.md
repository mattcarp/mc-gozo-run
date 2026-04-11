# Session Handoff - Race Completion + Demo Mode

## Current Task Status
**Task**: Race completion test (F011) + Demo Mode for Fiona TV surprise
**Status**: IN PROGRESS - Need user to tap Start on simulator

## What Was Done This Session

### Website Polish (DONE)
- runfionarun.com updated with: download toast, Look Ahead card, hero texture
- Commit 83ef253 pushed to github.com/mattcarp/runfionarun-site
- Dark mode, carousel, real screenshots already existed on remote

### Spectator Flow (DONE)
- Verified on iPhone 17 Pro simulator (E04B9767)
- Supabase data pipeline confirmed: positions + cheers both working
- Tables: gozo_live_positions (6+ entries), gozo_cheers (3+ entries)

### Race Completion (NEXT)
- GPS simulation was running (68 waypoints at 150m/s)
- App on Track tab showing Start button
- User needs to: tap Start -> watch distance -> completion screen triggers at 21.1km
- May need to restart GPS sim: cat /tmp/waypoints.txt | xcrun simctl location 1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1 start --speed=150 -

### Demo Mode (LAST)
- Navigate to Settings tab > Demo section > "Launch Demo Mode"
- Auto-runs entire race with voice alerts + Look Around street views
- Perfect for screencasting to TV for Fiona

## Machine State

### Mac Mini (mattcarp@Matts-Mac-mini.local, pw: fortuna)
- iPhone 17 simulator: BOOTED (1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1)
- iPhone 17 Pro: SHUTDOWN
- App installed and running on iPhone 17
- Window position: (154, 30) size 345x750 (may change after reboot)
- /tmp/waypoints.txt: 68 extracted GPX waypoints for fast simulation
- /tmp/make_app_bundle.sh: creates .app from SPM binary
- NOTE: /tmp/ files WILL BE LOST on reboot! Must recreate.

### Workshop (ssh workshop)
- Repo: ~/projects/mc-gozo-run (has GitHub push access)
- Website: ~/projects/runfionarun-site

### Supabase
- URL: https://cnmzahjpvxtnsvhnguqe.supabase.co
- Key: sb_publishable_IIYa7pcz7LXsIdke9RxQiw_DIzMA1-4

## Build Steps After Reboot
1. ssh mattcarp@Matts-Mac-mini.local
2. sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
3. cd /Users/mattcarp/projects/mc-gozo-run && git pull origin main
4. xcodebuild -scheme GozoRun -destination "platform=iOS Simulator,id=1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1" -derivedDataPath build build
5. Recreate make_app_bundle.sh:
   ```
   APP_DIR="build/Build/Products/Debug-iphonesimulator/GozoRun.app"
   rm -rf "$APP_DIR" && mkdir -p "$APP_DIR"
   cp build/Build/Products/Debug-iphonesimulator/GozoRun "$APP_DIR/GozoRun"
   cp Sources/GozoRun/Info.plist "$APP_DIR/Info.plist"
   codesign --force --sign - "$APP_DIR"
   ```
6. xcrun simctl install 1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1 build/Build/Products/Debug-iphonesimulator/GozoRun.app
7. xcrun simctl launch 1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1 com.mattcarp.GozoRun

## Remaining TODO
- [ ] F011: Race completion screen (tap Start, let GPS sim run to 21.1km)
- [ ] Demo Mode: Launch from Settings for Fiona TV surprise
- [ ] Physical device: Connect iPhone 16/15 to Mac Mini USB
- [ ] Website: Add real race photos when available

---
*Last updated: 2026-04-11 ~15:30 UTC*
