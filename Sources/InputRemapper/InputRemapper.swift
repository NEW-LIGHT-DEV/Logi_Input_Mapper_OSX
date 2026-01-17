import Foundation
import CoreGraphics
import AppKit

/// Main class that sets up and manages the CGEventTap
class InputRemapper {
    private let eventHandler: EventHandler
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init() {
        self.eventHandler = EventHandler()
    }

    /// Starts the event tap and enters the run loop
    func start() {
        // Check for Accessibility permissions
        guard checkAccessibilityPermissions() else {
            print("Error: Accessibility permissions not granted.")
            print("Please enable in: System Settings > Privacy & Security > Accessibility")
            exit(1)
        }

        // Create the event tap
        guard setupEventTap() else {
            print("Error: Failed to create event tap.")
            exit(1)
        }

        printStartupMessage()

        // Run forever
        CFRunLoopRun()
    }

    /// Stops the event tap
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        CFRunLoopStop(CFRunLoopGetCurrent())

        print("InputRemapper stopped.")
    }

    // MARK: - Private Methods

    private func checkAccessibilityPermissions() -> Bool {
        // Prompt for permissions if not already granted
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func setupEventTap() -> Bool {
        // Events we want to intercept:
        // - Other mouse buttons (not left/right click)
        // - Keyboard events (for F1, F2, Calculator key)
        // - System-defined events (for media keys like brightness)
        let eventMask: CGEventMask = (
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << 14)  // NX_SYSDEFINED - for media/special keys
        )

        // Create a mutable pointer to self for the callback
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        // Create the event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Handle tap disabled event
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let refcon = refcon {
                        let remapper = Unmanaged<InputRemapper>.fromOpaque(refcon).takeUnretainedValue()
                        if let tap = remapper.eventTap {
                            CGEvent.tapEnable(tap: tap, enable: true)
                        }
                    }
                    return Unmanaged.passUnretained(event)
                }

                // Get the InputRemapper instance
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                let remapper = Unmanaged<InputRemapper>.fromOpaque(refcon).takeUnretainedValue()

                // Process the event
                if let result = remapper.eventHandler.handleEvent(event, type: type) {
                    return Unmanaged.passUnretained(result)
                } else {
                    // Return nil to swallow the event
                    return nil
                }
            },
            userInfo: refcon
        ) else {
            return false
        }

        self.eventTap = tap

        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.runLoopSource = runLoopSource

        // Enable the tap
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private func printStartupMessage() {
        print("InputRemapper started successfully!")
        print("")
        print("Active mappings:")
        print("  Mouse:")
        print("    - Thumb button -> Mission Control")
        print("    - Back button -> Cmd+[")
        print("    - Forward button -> Cmd+]")
        print("  Keyboard:")
        print("    - F1 -> Brightness Down")
        print("    - F2 -> Brightness Up")
        print("    - Calculator -> Toggle Calculator.app")
        print("")
        if debugMode {
            print("Debug mode: ON (all events will be logged)")
            print("")
        }
        print("Press Ctrl+C to stop.")
    }
}
