#!/bin/bash

echo "🔍 Starting NimbleEdgeAssistant app monitoring..."
echo "📱 App should be visible in the simulator now."
echo "👆 Click the 'Initialize AI Assistant' button and watch for debug output below:"
echo "----------------------------------------"

# Monitor logs in real-time for the app
xcrun simctl spawn 0A6913C4-12DB-4112-AA76-B9E0753ED305 log stream --predicate 'process == "NimbleEdgeAssistant"' --level debug | while read line; do
    # Filter for relevant debug information
    if [[ "$line" == *"SDK"* ]] || [[ "$line" == *"initialization"* ]] || [[ "$line" == *"error"* ]] || [[ "$line" == *"crash"* ]] || [[ "$line" == *"Assets"* ]] || [[ "$line" == *"DeliteAI"* ]] || [[ "$line" == *"🚀"* ]] || [[ "$line" == *"✅"* ]] || [[ "$line" == *"❌"* ]] || [[ "$line" == *"⚠️"* ]] || [[ "$line" == *"💥"* ]] || [[ "$line" == *"🔍"* ]]; then
        echo "$(date '+%H:%M:%S') | $line"
    fi
done
