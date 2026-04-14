#!/bin/bash
# Environment validation for focusmode.nvim development
set -e

echo "=== focusmode.nvim Environment Check ==="

# Neovim version
echo -n "Neovim: "
nvim --version | head -1

# Plugin path
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Plugin dir: $PLUGIN_DIR"

# Check minimal-init exists
if [ -f "$PLUGIN_DIR/tests/minimal-init.lua" ]; then
  echo "minimal-init.lua: OK"
else
  echo "minimal-init.lua: MISSING"
  exit 1
fi

# Check plugin loads without error
echo -n "Plugin loads: "
OUTPUT=$(nvim --headless -u "$PLUGIN_DIR/tests/minimal-init.lua" \
  -c "lua require('focusmode')" -c "qa!" 2>&1)
if [ $? -eq 0 ]; then
  echo "OK"
else
  echo "FAIL"
  echo "$OUTPUT"
  exit 1
fi

# Check clean exit (no timer leaks)
echo -n "Clean exit: "
timeout 5 nvim --headless -u "$PLUGIN_DIR/tests/minimal-init.lua" \
  -c "lua require('focusmode').setup({})" -c "qa!" 2>&1
if [ $? -eq 0 ]; then
  echo "OK"
else
  echo "FAIL (timeout or error)"
  exit 1
fi

echo "=== All checks passed ==="
