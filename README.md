# InputRemapper

A lightweight, privacy-respecting input remapper for macOS. Replaces Logitech Options+ for button/key remapping without telemetry or bloatware.

## Why?

Logitech Options+ is over 200MB, phones home constantly, and requires creating an account. This tool is:

- **~115KB** compiled binary
- **Zero network access** - completely offline
- **Open source** - audit the code yourself
- **Simple** - just edit `Config.swift` and rebuild

## Supported Devices

Tested with:
- **Logitech MX Master 3** (Bluetooth) - mouse buttons
- **Logitech MX Mechanical** (Bluetooth) - brightness keys

Should work with other mice/keyboards - use `make run-debug` to find your button codes.

## Current Mappings

| Input | Action |
|-------|--------|
| MX Master 3 thumb button | Mission Control |
| MX Master 3 back button | Browser back (Cmd+[) |
| MX Master 3 forward button | Browser forward (Cmd+]) |
| MX Mechanical F1 | Brightness down |
| MX Mechanical F2 | Brightness up |

## Installation

### Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools: `xcode-select --install`

### Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/InputRemapper.git
cd InputRemapper
make install
```

### Grant Accessibility Permission (Required!)

**This is the crucial step.** The app needs Accessibility permission to intercept input events.

1. Open **System Settings > Privacy & Security > Accessibility**
2. Click the **+** button
3. Navigate to **/Applications/InputRemapper.app**
4. Toggle it **ON**

Without this permission, nothing will work.

### Verify It's Running

```bash
make status
```

## Customization

### Finding Your Button/Key Codes

Every mouse and keyboard sends different codes. To find yours:

```bash
make run-debug
```

Then press the buttons/keys you want to remap. You'll see output like:

```
[Mouse] Button 5 DOWN
[Mouse] Button 5 UP
[System] Media key 3 DOWN
[Keyboard] Key 122 DOWN (flags: ...)
```

Note these numbers - you'll need them for configuration.

### Editing Mappings

Open `Sources/InputRemapper/Config.swift`:

```swift
// Mouse button mappings
let mouseButtonMappings: [Int64: Action] = [
    5: .missionControl,                    // Thumb button
    3: .keyCombo(KeyCombo(keyCode: 33, modifiers: .maskCommand)),  // Back
    4: .keyCombo(KeyCombo(keyCode: 30, modifiers: .maskCommand)),  // Forward
]
```

### Available Actions

| Action | Description | Example |
|--------|-------------|---------|
| `.keyCombo(KeyCombo(...))` | Send keyboard shortcut | `KeyCombo(keyCode: 33, modifiers: .maskCommand)` for Cmd+[ |
| `.missionControl` | Open Mission Control | - |
| `.brightnessDown` | Decrease brightness | - |
| `.brightnessUp` | Increase brightness | - |
| `.toggleApp(bundleIdentifier:)` | Toggle app open/closed | `.toggleApp(bundleIdentifier: "com.apple.calculator")` |
| `.passthrough` | Disable mapping | - |

### Common Key Codes

```swift
// Function keys
f1 = 122, f2 = 120, f3 = 99, f4 = 118, f5 = 96, f6 = 97

// Arrow keys
upArrow = 126, downArrow = 125, leftArrow = 123, rightArrow = 124

// Common keys
tab = 48, space = 49, return = 36, escape = 53, delete = 51
leftBracket = 33, rightBracket = 30
```

Full reference: https://gist.github.com/eegrok/949034

### Modifier Flags

```swift
.maskCommand   // Cmd
.maskShift     // Shift
.maskAlternate // Option
.maskControl   // Control
```

Combine with: `[.maskCommand, .maskShift]`

### Finding App Bundle Identifiers

```bash
osascript -e 'id of app "Calculator"'
# Output: com.apple.calculator
```

### Apply Changes

After editing `Config.swift`:

```bash
make reload
```

## Commands

| Command | Description |
|---------|-------------|
| `make build` | Build the app |
| `make install` | Install to /Applications and set up auto-start |
| `make uninstall` | Remove completely |
| `make reload` | Rebuild and restart (for development) |
| `make run` | Run locally in foreground |
| `make run-debug` | Run with debug output (shows all events) |
| `make status` | Check if running |
| `make logs` | View recent logs |
| `make clean` | Remove build artifacts |

## Troubleshooting

### Nothing works

1. Did you add the app to Accessibility? (System Settings > Privacy & Security > Accessibility)
2. Is it toggled ON?
3. Try removing and re-adding it

### Mappings don't fire

1. Run `make run-debug`
2. Press the button - does it show in output?
3. If not shown, the button code might be different - note the actual code and update Config.swift

### Changes don't take effect

```bash
make reload
```

### Brightness keys don't work

The MX Mechanical sends F1/F2 as media keys (not regular F-keys). If your keyboard is different, check the `[System] Media key X` output in debug mode and update `MediaKey.brightnessDown/Up` in Config.swift.

## Technical Details

- Uses `CGEventTap` to intercept input events at the session level
- Uses `DisplayServices` private framework for brightness control (the only way that works on Apple Silicon)
- Runs as a LaunchAgent - starts at login, restarts if crashed
- No kernel extensions, no root access needed

## Known Limitations

- **Consumer HID keys** (like Calculator key on MX Mechanical) use Logitech's proprietary HID++ protocol and cannot be intercepted without reverse-engineering their protocol
- Only works for the logged-in user session
- Some apps may override these mappings

## Project Structure

```
InputRemapper/
├── Package.swift                    # Swift package manifest
├── Makefile                         # Build/install commands
├── com.user.InputRemapper.plist     # LaunchAgent config
├── Sources/InputRemapper/
│   ├── main.swift                   # Entry point
│   ├── Config.swift                 # YOUR MAPPINGS GO HERE
│   ├── InputRemapper.swift          # CGEventTap setup
│   ├── EventHandler.swift           # Event routing
│   └── SystemActions.swift          # Brightness, Mission Control, etc.
└── README.md
```

## License

MIT License - do whatever you want with it.

## Acknowledgments

- Inspired by [SensibleSideButtons](https://sensible-side-buttons.archagon.net/)
- Brightness control approach from [brightness CLI](https://github.com/nriley/brightness)
