# Claude Usage Bar

macOS menu bar app that shows your Claude Pro/Team usage limits in real time.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10-orange)

## Features

- **Menu bar indicator** — circular progress ring with usage percentage, always visible
- **Session & weekly limits** — tracks 5-hour session, 7-day, and per-model (Sonnet/Opus) utilization
- **Extra usage tracking** — monitors paid overage spending with currency support
- **Claude status** — shows current API operational status
- **Auto-refresh** — configurable interval (1 min to 1 hour)
- **Launch at login** — optional auto-start via macOS Service Management
- **Multi-language** — English and Polish

## Installation

Download the latest `.dmg` from [Releases](https://github.com/radeckid/claude-code-usage-toolbar/releases), open it, and drag **Claude Usage Bar** to Applications.

## How it works

The app reads your Claude OAuth token from the macOS Keychain (stored by Claude Code / claude.ai) and calls the Anthropic usage API to fetch current rate limit data.

## Requirements

- macOS 14 (Sonoma) or later
- Active Claude Pro or Team subscription
- Logged in to Claude (token must be present in Keychain)

## Building from source

```bash
# Clone
git clone git@github.com:radeckid/claude-code-usage-toolbar.git
cd claude-code-usage-toolbar

# Build and create DMG
./build_dmg.sh 1.0.0

# Build and publish GitHub Release
./build_dmg.sh 1.0.0 --release
```

Requires Xcode 15+ and the `gh` CLI for releases.

## Author

Damian Radecki
