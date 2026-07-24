# Focusmode.nvim release evidence

This document records the launch-evidence gates added before any release, tag, branch-protection change, demo asset, marketplace entry, or public launch action.

## Current evidence gates

Run these from the repository root:

```bash
./init-test.sh
python3 scripts/run-headless-tests.py
git diff --check
```

The headless runner executes every `tests/F*_test.lua` file with `tests/minimal-init.lua`. It fails on either a non-zero Neovim exit code or assertion/error text in captured output. That matters because headless Neovim with `qa!` can return exit code 0 even when stderr contains Lua assertion failures.

## Expected passing surface

The full sweep should pass these contract tests:

- `F001_test.lua` plugin skeleton and load guard
- `F002_test.lua` configuration defaults and overrides
- `F003_test.lua` timer state machine
- `F004_test.lua` session lifecycle
- `F005_test.lua` persistence and stats
- `F006_test.lua` setup commands and lualine component table contract
- `F007_test.lua` focus lock behavior
- `F008_test.lua` keybind blocking
- `F009_test.lua` do-not-disturb integration
- `F010_test.lua` dashboard rendering
- `F011_test.lua` mode picker integration
- `F012_test.lua` toast notifications
- `F013_test.lua` achievement tracker no-op behavior and lualine component table contract
- `F014_test.lua` auto-pause behavior
- `F015_test.lua` sound and bell integration

## Lualine public contract

`require("focusmode").lualine()` and `require("focusmode.integrations").lualine_component()` return a lualine component table. The callable renderer is stored at index `[1]`, with `color` and `cond` callbacks on the table. This matches the README usage:

```lua
require("lualine").setup({
  sections = {
    lualine_x = { require("focusmode").lualine() },
  },
})
```

## CI coverage

`.github/workflows/ci.yml` runs the smoke check, the full headless sweep, and whitespace validation on pull requests and pushes to `main`.

## Not done by this PR

- No release or tag was created.
- No GitHub release notes were published.
- No branch protection or repository setting was changed.
- No demo GIF, marketplace listing, external post, or outreach was created.
- No package manager publication or paid action was performed.

## Next launch evidence after this PR

After this PR lands, the next launch-readiness step is a release/tag decision plus an install-smoke transcript from a clean Neovim config. That should happen only after Ray explicitly approves release/publication work.
