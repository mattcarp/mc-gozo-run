#!/bin/bash
# Switch xcode-select to Xcode.app and open the project
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
echo "---"
# Generate xcodeproj if xcodegen is available, otherwise open Package.swift
if command -v xcodegen &>/dev/null; then
    cd /Users/mattcarp/projects/mc-gozo-run
    xcodegen generate
    open GozoRun.xcodeproj
else
    open /Users/mattcarp/projects/mc-gozo-run/Package.swift
fi
