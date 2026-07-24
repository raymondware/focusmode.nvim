#!/usr/bin/env python3
"""Run focusmode.nvim headless tests and fail on stderr assertion text.

Neovim can exit 0 for some headless Lua assertion failures when qa! is used.
This runner treats assertion/error text on stderr/stdout as a failing test so local
and CI launch-evidence gates match the real test semantics.
"""
from __future__ import annotations

import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
TEST_DIR = REPO / "tests"
MINIMAL_INIT = TEST_DIR / "minimal-init.lua"
FAILURE_MARKERS = (
    "Error detected",
    "Assertion failed",
    "stack traceback:",
    "should return",
    "should expose",
    "should exist",
)


def run_test(test_path: pathlib.Path) -> tuple[bool, str]:
    cmd = [
        "nvim",
        "--headless",
        "-u",
        str(MINIMAL_INIT),
        "-c",
        f"luafile {test_path}",
        "-c",
        "qa!",
    ]
    proc = subprocess.run(
        cmd,
        cwd=REPO,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    combined = (proc.stdout or "") + (proc.stderr or "")
    failed_by_marker = any(marker in combined for marker in FAILURE_MARKERS)
    passed = proc.returncode == 0 and not failed_by_marker
    detail = combined.strip()
    if not detail:
        detail = f"exit={proc.returncode}"
    return passed, detail


def main() -> int:
    if not MINIMAL_INIT.exists():
        print(f"missing minimal init: {MINIMAL_INIT}", file=sys.stderr)
        return 2

    failures: list[tuple[str, str]] = []
    for test_path in sorted(TEST_DIR.glob("F*_test.lua")):
        passed, detail = run_test(test_path)
        status = "PASS" if passed else "FAIL"
        print(f"{status}: {test_path.name}")
        if detail:
            for line in detail.splitlines():
                print(f"  {line}")
        if not passed:
            failures.append((test_path.name, detail[-1600:]))

    if failures:
        print("\nHeadless test failures:", file=sys.stderr)
        for name, detail in failures:
            print(f"- {name}: {detail}", file=sys.stderr)
        return 1

    print("all focusmode headless tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
