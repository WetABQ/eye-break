# EyeBreak

A lightweight macOS menu bar app that reminds you to take regular breaks to protect your eyes.

EyeBreak monitors your keyboard and mouse activity, tracks continuous screen time, and displays a full-screen overlay when it's time to rest — following the 20-20-20 rule (every 20 minutes, look at something 20 feet away for 20 seconds).

## Download

[**EyeBreak v1.0.0** — macOS (Apple Silicon)](https://github.com/WetABQ/eye-break/releases/download/v1.0.0/EyeBreak-v1.0-macos-arm64.zip)

## Features

- **Menu bar app** — lives in your menu bar with a live countdown timer, no Dock icon
- **Activity detection** — monitors mouse and keyboard events to track actual screen usage
- **Smart idle detection** — automatically resets the timer when you step away (configurable threshold)
- **Full-screen overlay** — covers all connected displays with a break reminder and countdown
- **Multi-monitor support** — overlay appears on every screen, handles hot-plug
- **Sleep/wake aware** — pauses on sleep, resets on wake
- **Configurable** — adjust work duration, break duration, and idle threshold
- **Preview mode** — test the break overlay from Settings without waiting

## Screenshots

When it's time for a break, a full-screen overlay appears:

> "Time to Rest Your Eyes — Look at something 20 feet away"

## Requirements

- macOS 14.0 (Sonoma) or later
- Accessibility permission (required for global keyboard/mouse monitoring)

## Build

```bash
git clone https://github.com/WetABQ/eye-break.git
cd eye-break
./build.sh
```

This compiles the project with Swift Package Manager and creates `EyeBreak.app`.

## Run

```bash
open EyeBreak.app
```

On first launch, you'll need to grant Accessibility permission. Click "Grant Permission" in the menu bar popover, then enable EyeBreak in System Settings > Privacy & Security > Accessibility.

## Default Settings

| Setting | Default |
|---------|---------|
| Work Duration | 20 minutes |
| Break Duration | 20 seconds |
| Idle Threshold | 30 seconds |

## Architecture

```
Sources/EyeBreak/
├── App/
│   ├── EyeBreakApp.swift           # @main entry point
│   └── AppDelegate.swift           # Menu bar, panel, global coordination
├── Models/
│   ├── AppState.swift              # @Observable state (phase/elapsed/remaining)
│   └── AppSettings.swift           # UserDefaults-backed settings
├── Services/
│   ├── ActivityMonitor.swift       # Global mouse/keyboard event monitoring
│   ├── WorkTimerService.swift      # 1s tick, idle detection, state machine
│   ├── BreakManager.swift          # Break lifecycle management
│   ├── OverlayWindowManager.swift  # Full-screen overlay windows
│   └── PermissionManager.swift     # Accessibility permission handling
├── Views/
│   ├── MenuBarPopoverView.swift    # Menu bar popover UI
│   ├── BreakOverlayView.swift      # Full-screen break countdown
│   └── SettingsView.swift          # Settings panel
└── Utilities/
    ├── Constants.swift             # Default values
    └── VisualEffectBackground.swift # NSVisualEffectView wrapper
```

### State Machine

```
idle → working (activity detected) → onBreak (time's up) → idle (break finished)
  ↑                                       |
  └── idle (user went idle > threshold) ←─┘
```

## License

MIT
