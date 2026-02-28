#!/bin/bash

# Build the project
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -configuration Debug build

# Check if build succeeded
if [ $? -eq 0 ]; then
    # Run the app
    open "/Users/americo/Library/Developer/Xcode/DerivedData/americo-whisper-avvwimpvamhlkygutqbuuzvflbzn/Build/Products/Debug/americo-whisper.app"
else
    echo "Build failed!"
    exit 1
fi
