import Foundation
import CoreGraphics
import AppKit

/// Handles incoming events and applies remappings
class EventHandler {

    // Track key states to only act on key-down, not key-up
    private var activeKeys: Set<CGKeyCode> = []

    /// Processes an event and returns the modified event (or nil to swallow it)
    func handleEvent(_ event: CGEvent, type: CGEventType) -> CGEvent? {
        switch type {
        case .otherMouseDown:
            return handleMouseDown(event)

        case .otherMouseUp:
            return handleMouseUp(event)

        case .keyDown:
            return handleKeyDown(event)

        case .keyUp:
            return handleKeyUp(event)

        default:
            // Handle system-defined events (media keys like brightness)
            if type.rawValue == 14 {  // NX_SYSDEFINED
                return handleSystemDefined(event)
            }
            return event
        }
    }

    // MARK: - System-Defined Event Handling (Media Keys)

    private func handleSystemDefined(_ event: CGEvent) -> CGEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return event
        }

        // Only handle AUX control button events (subtype 8)
        guard nsEvent.subtype.rawValue == 8 else {
            return event
        }

        let data1 = nsEvent.data1
        let keyCode = (data1 & 0xFFFF0000) >> 16
        let keyState = (data1 & 0x0000FF00) >> 8
        let isKeyDown = keyState == 0x0A

        if debugMode {
            print("[System] Media key \(keyCode) \(isKeyDown ? "DOWN" : "UP")")
        }

        // Handle brightness keys
        // Media key 3 = Brightness Down (F1 on MX Mechanical)
        // Media key 2 = Brightness Up (F2 on MX Mechanical)
        if isKeyDown {
            switch keyCode {
            case MediaKey.brightnessDown:
                if debugMode {
                    print("  -> Brightness DOWN")
                }
                sendBrightnessKey(increase: false)
                return nil
            case MediaKey.brightnessUp:
                if debugMode {
                    print("  -> Brightness UP")
                }
                sendBrightnessKey(increase: true)
                return nil
            default:
                break
            }
        } else {
            // Swallow key-up events for brightness too
            if keyCode == MediaKey.brightnessDown || keyCode == MediaKey.brightnessUp {
                return nil
            }
        }

        return event
    }

    // MARK: - Mouse Event Handling

    private func handleMouseDown(_ event: CGEvent) -> CGEvent? {
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)

        if debugMode {
            print("[Mouse] Button \(buttonNumber) DOWN")
        }

        guard let action = mouseButtonMappings[buttonNumber] else {
            return event
        }

        performAction(action)
        return nil  // Swallow the original event
    }

    private func handleMouseUp(_ event: CGEvent) -> CGEvent? {
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)

        if debugMode {
            print("[Mouse] Button \(buttonNumber) UP")
        }

        // If this button is mapped, swallow the up event too
        if mouseButtonMappings[buttonNumber] != nil {
            return nil
        }

        return event
    }

    // MARK: - Keyboard Event Handling

    private func handleKeyDown(_ event: CGEvent) -> CGEvent? {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        if debugMode {
            print("[Keyboard] Key \(keyCode) DOWN (flags: \(event.flags))")
        }

        // Check keyboard mappings
        guard let action = keyboardMappings[keyCode] else {
            return event
        }

        // Only trigger on initial key-down, not repeats
        if activeKeys.contains(keyCode) {
            return nil
        }

        activeKeys.insert(keyCode)
        performAction(action)
        return nil
    }

    private func handleKeyUp(_ event: CGEvent) -> CGEvent? {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        if debugMode {
            print("[Keyboard] Key \(keyCode) UP")
        }

        // If this key is mapped, swallow the up event and clear state
        if keyboardMappings[keyCode] != nil {
            activeKeys.remove(keyCode)
            return nil
        }

        return event
    }

    // MARK: - Action Execution

    private func performAction(_ action: Action) {
        switch action {
        case .keyCombo(let combo):
            if debugMode {
                print("  -> Sending key combo: \(combo.keyCode) with modifiers \(combo.modifiers)")
            }
            sendKeyCombo(combo)

        case .missionControl:
            if debugMode {
                print("  -> Mission Control")
            }
            triggerMissionControl()

        case .brightnessDown:
            if debugMode {
                print("  -> Brightness DOWN")
            }
            sendBrightnessKey(increase: false)

        case .brightnessUp:
            if debugMode {
                print("  -> Brightness UP")
            }
            sendBrightnessKey(increase: true)

        case .toggleApp(let bundleID):
            if debugMode {
                print("  -> Toggle app: \(bundleID)")
            }
            toggleApplication(bundleIdentifier: bundleID)

        case .passthrough:
            break
        }
    }
}
