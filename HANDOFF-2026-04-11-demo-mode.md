# Session Handoff - GozoRun Demo Mode & Testing

## Current Task Status
**Task**: Demo Mode for Fiona + remaining device testing
**Status**: IN PROGRESS - Demo Mode built, not yet launched for real demo

## Problem Summary
Building an iOS companion app for the Gozo Half Marathon (April 26, 2026).
User wants Demo Mode auto-running on TV via AirPlay to surprise Fiona.

## Machines Setup

| Machine | User | Path | Notes |
|---|---|---|---|
| MacBook Air | matt | /Users/matt/Documents/projects/mc-thebetabase (main Cursor IDE) | Main dev machine |
| Workshop (Ubuntu) | matt | ~/projects/mc-gozo-run | Has GitHub push access |
| Mac Mini | mattcarp | /Users/mattcarp/projects/mc-gozo-run | Xcode 26.4, iPhone 17 simulator, NO GitHub push |

### Mac Mini SSH Access
- Host: Matts-Mac-mini.local (or 192.168.68.142)
- User: mattcarp
- Password: fortuna
- sudo works with: ssh -t mattcarp@Matts-Mac-mini.local 'echo fortuna | sudo -S <command>'

### Mac Mini After Reboot
- Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
- Recreate /tmp/make_app_bundle.sh (creates .app bundle from SPM executable)

## What Was Done

### Features Built This Session
1. **LookAheadView.swift** - Apple Look Around street view showing 500m ahead
   - Expandable overlay on ContentView (top-left)
   - Uses MKLookAroundSceneRequest + LookAroundPreview
   - Dynamic updates as runner moves

2. **DemoModeView.swift** - Full auto-run demonstration
   - Auto-advances through all 664 route waypoints
   - HUD shows live distance, time, pace, KM progress
   - British-accented voice announces KM splits
   - Look Around scenes cycle every 15 points
   - Accessible from Settings > Demo section
   - Launched as fullScreenCover

3. **simulate-race.gpx** - 664-point timestamped GPX for Xcode location sim

### Build & Install Process
The app uses SPM executableTarget, which builds a raw binary NOT a .app bundle.
A custom script creates the bundle:

```bash
#!/bin/bash
APP_DIR="build/Build/Products/Debug-iphonesimulator/GozoRun.app"
rm -rf ""
mkdir -p ""
cp build/Build/Products/Debug-iphonesimulator/GozoRun "/GozoRun"
cp Sources/GozoRun/Info.plist "/Info.plist"
codesign --force --sign - ""
echo "Bundle ready at "
```

Then install: xcrun simctl install 1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1 <path>
Then launch: xcrun simctl launch 1303FE06-2A9B-4EEE-A131-C6C2FBDAADF1 com.mattcarp.GozoRun

### UI Automation (CoreGraphics clicks for simulator)
Python script for precise simulator clicks:
```python
import ctypes, time
cg = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
def click(x, y):
    for t in [1, 2]:  # 1=mouseDown, 2=mouseUp
        e = cg.CGEventCreateMouseEvent(None, t, ctypes.c_double(x), ctypes.c_double(y), 0)
        cg.CGEventPost(0, e)
        cg.CFRelease(e)
        time.sleep(0.05)
```
Key coords: Start button (553,687), Settings tab (767,755)

## Supabase Config
- Project: mc-run (West EU Ireland)
- URL: https://cnmzahjpvxtnsvhnguqe.supabase.co
- Publishable key: sb_publishable_IIYa7pcz7LXsIdke9RxQiw_DIzMA1-4
- DB password: W9itg3xLgAxPZ78cZIvZp6LQkzfC
- Tables: gozo_live_positions (GPS), gozo_cheers (cheers)
- Hardcoded as defaults in LiveTrackingService.swift and SettingsView.swift

## Next Steps to Try

### Option 1: Launch Demo Mode for Fiona
1. SSH to Mac Mini, rebuild if needed
2. Launch app on simulator
3. Navigate to Settings > Demo > Launch Demo Mode
4. AirPlay/screencast simulator to TV

### Option 2: Test Remaining Features
- Race completion: Run full 21.1km GPX simulation
- Spectator flow: Boot second simulator, enter GOZO2026 code

### Option 3: Physical Device Testing
- Connect iPhone 16/15 to Mac Mini
- Build for device: change destination to device UUID
- Test real GPS in backyard/walk

## Key Files
| File | Purpose |
|---|---|
| Sources/GozoRun/DemoModeView.swift | Auto-run demo for TV |
| Sources/GozoRun/LookAheadView.swift | Street view preview |
| Sources/GozoRun/ContentView.swift | Main runner view |
| Sources/GozoRun/SettingsView.swift | Settings + demo launch |
| Sources/GozoRun/LiveTrackingService.swift | Supabase integration |
| Package.swift | SPM manifest (executableTarget) |
| supabase/migration.sql | DB schema |
| simulate-race.gpx | Timestamped GPX for sim |

---
*Last updated: 2026-04-11 ~13:00 UTC*
