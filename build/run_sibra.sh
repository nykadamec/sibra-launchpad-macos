#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$DIR/Sibra.log"
exec > "$LOG" 2>&1
echo "=== Sibra started at $(date) ==="
open "$DIR/Sibra.app"
