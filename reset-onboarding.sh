#!/bin/bash
# Reset Sibra onboarding to show it again

DATA_PATH="$HOME/Library/Application Support/Sibra/data.json"

if [ ! -f "$DATA_PATH" ]; then
    echo "❌ data.json not found at $DATA_PATH"
    exit 1
fi

python3 - << 'EOF'
import json
import sys
import os

path = os.path.expanduser("~/Library/Application Support/Sibra/data.json")

with open(path) as f:
    data = json.load(f)

data["settings"]["hasCompletedOnboarding"] = False

with open(path, "w") as f:
    json.dump(data, f, indent=2)

print(f"✅ Onboarding reset — restart Sibra to see it again")
EOF
