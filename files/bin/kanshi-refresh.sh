#!/usr/bin/env bash
set -euo pipefail

killall -q kanshi || echo "Kanshi not running"
kanshi
