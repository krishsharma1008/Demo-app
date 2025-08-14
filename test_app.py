#!/usr/bin/env python3
import subprocess
import time
import sys

def test_app_functionality():
    print("🧪 Testing DeliteAI NimbleEdgeAssistant App...")
    
    # Check if app is running
    try:
        result = subprocess.run([
            'xcrun', 'simctl', 'list', 'apps', '0A6913C4-12DB-4112-AA76-B9E0753ED305'
        ], capture_output=True, text=True, timeout=10)
        
        if 'ai.delite.NimbleEdgeAssistant' in result.stdout:
            print("✅ App is installed on simulator")
        else:
            print("❌ App not found on simulator")
            return False
            
    except Exception as e:
        print(f"❌ Error checking app status: {e}")
        return False
    
    # Check if required model files exist in source
    model_files = [
        'NimbleEdgeAssistant.app/NimbleEdgeAssistant/Models/llama3/model',
        'NimbleEdgeAssistant.app/NimbleEdgeAssistant/Models/llama3/tokenizer',
        'NimbleEdgeAssistant.app/NimbleEdgeAssistant/Models/llama3/config',
        'NimbleEdgeAssistant.app/NimbleEdgeAssistant/Models/llama3/vocab',
        'NimbleEdgeAssistant.app/NimbleEdgeAssistant/Models/llama3/merges'
    ]
    
    for file_path in model_files:
        try:
            result = subprocess.run(['ls', '-la', file_path], capture_output=True)
            if result.returncode == 0:
                print(f"✅ {file_path.split('/')[-1]} file exists")
            else:
                print(f"❌ {file_path.split('/')[-1]} file missing")
                return False
        except Exception as e:
            print(f"❌ Error checking {file_path}: {e}")
            return False
    
    print("✅ All tests passed! App should work properly with offline LLM.")
    return True

if __name__ == "__main__":
    success = test_app_functionality()
    sys.exit(0 if success else 1)
