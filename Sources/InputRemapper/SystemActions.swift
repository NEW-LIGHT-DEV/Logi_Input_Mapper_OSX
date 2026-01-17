import Foundation
import AppKit
import CoreGraphics

// MARK: - Brightness Control

/// Brightness adjustment step
private let brightnessStep: Float = 0.0625  // ~6% per step, matches Apple's 16 steps

// Dynamically load DisplayServices framework for brightness control
private let displayServicesHandle: UnsafeMutableRawPointer? = {
    dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_NOW)
}()

private typealias GetBrightnessFunc = @convention(c) (UInt32, UnsafeMutablePointer<Float>) -> Int32
private typealias SetBrightnessFunc = @convention(c) (UInt32, Float) -> Int32

private let getBrightness: GetBrightnessFunc? = {
    guard let handle = displayServicesHandle,
          let sym = dlsym(handle, "DisplayServicesGetBrightness") else { return nil }
    return unsafeBitCast(sym, to: GetBrightnessFunc.self)
}()

private let setBrightness: SetBrightnessFunc? = {
    guard let handle = displayServicesHandle,
          let sym = dlsym(handle, "DisplayServicesSetBrightness") else { return nil }
    return unsafeBitCast(sym, to: SetBrightnessFunc.self)
}()

/// Changes display brightness up or down
func sendBrightnessKey(increase: Bool) {
    guard let getBrightness = getBrightness, let setBrightness = setBrightness else {
        print("Error: DisplayServices framework not available")
        return
    }

    let mainDisplay = CGMainDisplayID()

    var currentBrightness: Float = 0.5
    let getResult = getBrightness(mainDisplay, &currentBrightness)

    if getResult != 0 {
        if debugMode {
            print("  Warning: Could not get brightness (error \(getResult)), using 0.5")
        }
        currentBrightness = 0.5
    }

    var newBrightness: Float
    if increase {
        newBrightness = min(1.0, currentBrightness + brightnessStep)
    } else {
        newBrightness = max(0.0, currentBrightness - brightnessStep)
    }

    let setResult = setBrightness(mainDisplay, newBrightness)

    if debugMode {
        if setResult == 0 {
            print("  Brightness: \(Int(currentBrightness * 100))% -> \(Int(newBrightness * 100))%")
        } else {
            print("  Error setting brightness (error \(setResult))")
        }
    }
}

// MARK: - Mission Control

/// Triggers Mission Control using the system service
func triggerMissionControl() {
    // Use CoreGraphics to post the Mission Control key (F3 with no modifiers sends to Expose)
    // Or use the private API via NSWorkspace
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-a", "Mission Control"]
    try? task.run()
}

// MARK: - Application Control

/// Toggles an application: launches if not running, terminates if running
func toggleApplication(bundleIdentifier: String) {
    let workspace = NSWorkspace.shared
    let runningApps = workspace.runningApplications

    if let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
        // App is running - terminate it
        if debugMode {
            print("Terminating \(bundleIdentifier)")
        }
        app.terminate()
    } else {
        // App not running - launch it
        if debugMode {
            print("Launching \(bundleIdentifier)")
        }

        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            print("Error: Could not find application with bundle ID: \(bundleIdentifier)")
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        workspace.openApplication(at: url, configuration: configuration) { app, error in
            if let error = error {
                print("Error launching \(bundleIdentifier): \(error)")
            }
        }
    }
}

// MARK: - Keyboard Event Synthesis

/// Sends a keyboard shortcut (key code with modifiers)
func sendKeyCombo(_ combo: KeyCombo) {
    let source = CGEventSource(stateID: .combinedSessionState)

    // Key down
    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: combo.keyCode, keyDown: true) {
        keyDown.flags = combo.modifiers
        keyDown.post(tap: .cghidEventTap)
    }

    // Small delay to ensure the key down is registered
    usleep(10000)  // 10ms

    // Key up
    if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: combo.keyCode, keyDown: false) {
        keyUp.flags = combo.modifiers
        keyUp.post(tap: .cghidEventTap)
    }
}
