# GozoRun 🏃‍♂️

**Gozo Half Marathon tracker** — live GPS, spectator mode, voice KM alerts.

Race: **26 April 2026, 07:30** · Xagħra Square, Gozo · 21.1km

## Features
- Real 664-point race route from official GPX on satellite map
- 20 KM markers with proximity-triggered voice alerts
- Background GPS tracking (works with screen locked)
- Spectator mode: track the runner live with cheer button
- Elevation profile chart (6m–144m)
- Race countdown timer (days/hours/minutes/seconds)
- 4 themes: Dark Cyan, Dark Default, Light Coral, Spectator Dark
- Stats HUD: distance, time, pace, elevation gain

## Quick Start (macOS + Xcode 16+)

### Option A: XcodeGen (recommended)
```bash
brew install xcodegen   # if not installed
git clone https://github.com/mattcarp/mc-gozo-run.git
cd mc-gozo-run
xcodegen generate
open GozoRun.xcodeproj
```
Select your iPhone → Run (⌘R).

### Option B: Manual Xcode project
1. Open Xcode → **File → New → Project → iOS App**
2. Name: `GozoRun`, Bundle ID: `com.mattcarp.gozorun`, Interface: SwiftUI, Language: Swift
3. Delete the auto-generated `ContentView.swift` and `GozoRunApp.swift` files
4. Drag the entire `Sources/GozoRun/` folder into the project navigator
5. Make sure `route.gpx` is included in **Target → Build Phases → Copy Bundle Resources**
6. Set **Deployment Target → iOS 17.0**
7. In **Signing & Capabilities → Background Modes** → check "Location updates"
8. Run on your iPhone

### Option C: Open Package.swift directly
```bash
git clone https://github.com/mattcarp/mc-gozo-run.git
cd mc-gozo-run
open Package.swift
```
Xcode opens the package. Go to **Product → Scheme → New Scheme** → select "GozoRun". 
Note: This runs as a library target — for a device build, Option A or B is better.

## For Fiona (spectator)
1. Open the app
2. Tap **Spectate** tab
3. See Mattie's position on the race map in real time
4. Tap the **Cheer** button to send encouragement! 👏

## Route Data
- Source: [plotaroute.com/route/820516](https://www.plotaroute.com/route/820516?units=km)
- 664 track points with elevation
- 20 KM marker waypoints
- 7 water stations, marshals, toilets, parking
- Start/Finish: Xagħra Square (36.050042, 14.264673)

## Requirements
- iOS 17.0+
- Xcode 16+ (macOS Sequoia recommended)
- iPhone with GPS
- Apple Developer account (free is fine for personal device)

## Tech
- SwiftUI + MapKit + CoreLocation + AVFoundation + Swift Charts
- Zero external dependencies
- `route.gpx` parsed at launch via XMLParser
