import Foundation
import CoreGraphics

// =============================================================================
// CONFIGURATION - Edit these values to customize your mappings
// =============================================================================
//
// HOW TO CUSTOMIZE:
//   1. Run: make run-debug
//   2. Press the button/key you want to map
//   3. Note the button number or keyCode printed
//   4. Add/modify mappings below
//   5. Rebuild: make reload
//
// See README.md for detailed instructions and common key codes.
// =============================================================================

// MARK: - Mouse Button Mappings

/// Mouse button numbers (from CGEvent's buttonNumber field)
/// Use --debug mode to find your device's button numbers
enum MouseButton {
    // Common Logitech MX Master 3 buttons:
    static let thumb: Int64 = 5      // Big button under thumb
    static let back: Int64 = 3       // Rear button below side scroll
    static let forward: Int64 = 4    // Front button below side scroll
}

// MARK: - Keyboard Key Codes

/// macOS virtual key codes
/// Full reference: https://gist.github.com/eegrok/949034
enum KeyCode {
    // Function keys
    static let f1: CGKeyCode = 122
    static let f2: CGKeyCode = 120
    static let f3: CGKeyCode = 99
    static let f4: CGKeyCode = 118
    static let f5: CGKeyCode = 96
    static let f6: CGKeyCode = 97

    // Arrow keys
    static let upArrow: CGKeyCode = 126
    static let downArrow: CGKeyCode = 125
    static let leftArrow: CGKeyCode = 123
    static let rightArrow: CGKeyCode = 124

    // Common keys
    static let leftBracket: CGKeyCode = 33   // [
    static let rightBracket: CGKeyCode = 30  // ]
    static let tab: CGKeyCode = 48
    static let space: CGKeyCode = 49
    static let returnKey: CGKeyCode = 36
    static let escape: CGKeyCode = 53
    static let delete: CGKeyCode = 51
}

// MARK: - Action Definitions

/// Represents a keyboard shortcut with optional modifiers
struct KeyCombo {
    let keyCode: CGKeyCode
    let modifiers: CGEventFlags

    init(keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

/// Actions that can be triggered by inputs
enum Action {
    case keyCombo(KeyCombo)          // Send a keyboard shortcut
    case missionControl              // Open Mission Control
    case brightnessDown              // Decrease display brightness
    case brightnessUp                // Increase display brightness
    case toggleApp(bundleIdentifier: String)  // Toggle app open/closed
    case passthrough                 // Don't modify (useful for disabling)
}

// =============================================================================
// YOUR MAPPINGS - Customize these for your devices
// =============================================================================

/// Mouse button mappings
/// Key: button number (use --debug to find), Value: action to perform
let mouseButtonMappings: [Int64: Action] = [
    // Logitech MX Master 3 defaults:
    MouseButton.thumb: .missionControl,
    MouseButton.back: .keyCombo(KeyCombo(keyCode: KeyCode.leftBracket, modifiers: .maskCommand)),
    MouseButton.forward: .keyCombo(KeyCombo(keyCode: KeyCode.rightBracket, modifiers: .maskCommand)),
]

/// Keyboard mappings (for media keys sent as system events)
/// Key: media key code (use --debug to find), Value: action to perform
/// Note: This intercepts F1/F2 when sent as brightness media keys
let keyboardMappings: [CGKeyCode: Action] = [
    KeyCode.f1: .brightnessDown,
    KeyCode.f2: .brightnessUp,
]

// =============================================================================
// ADVANCED - Modify if needed
// =============================================================================

/// Media key codes for brightness (from MX Mechanical F1/F2)
/// These are the codes that appear in [System] Media key events
enum MediaKey {
    static let brightnessDown: Int = 3  // F1 on MX Mechanical
    static let brightnessUp: Int = 2    // F2 on MX Mechanical
}

/// Debug mode - set via --debug flag, prints all intercepted events
var debugMode = false
