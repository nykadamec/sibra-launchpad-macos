#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
open "$DIR/Sibra.app"
echo "Log: ~/Library/Application Support/Sibra/logs/Sibra.log"
echo "View log: tail -f ~/Library/Application\ Support/Sibra/logs/Sibra.log"
