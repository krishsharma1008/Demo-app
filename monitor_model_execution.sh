#!/bin/bash

# Monitor NimbleEdgeAssistant model execution
echo "🔍 Starting detailed monitoring of NimbleEdgeAssistant..."
echo "📱 App Process ID: $(xcrun simctl spawn 0A6913C4-12DB-4112-AA76-B9E0753ED305 pgrep NimbleEdgeAssistant)"
echo "⏰ Started at: $(date)"
echo "=" >> monitor_output.log
echo "Monitor started at: $(date)" >> monitor_output.log
echo "=" >> monitor_output.log

# Capture logs with focus on our app and model execution
xcrun simctl spawn 0A6913C4-12DB-4112-AA76-B9E0753ED305 log stream \
  --predicate 'process == "NimbleEdgeAssistant"' \
  --style syslog \
  --color none \
  | while read line; do
    echo "$line" | tee -a monitor_output.log
    # Highlight important lines
    if echo "$line" | grep -q "🤖\|📊\|❌\|✅\|⚠️\|🚨"; then
      echo "*** IMPORTANT: $line"
    fi
  done
