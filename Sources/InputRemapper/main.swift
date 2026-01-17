import Foundation
import AppKit

// Disable stdout buffering for immediate output
setbuf(stdout, nil)
setbuf(stderr, nil)

// MARK: - Command Line Argument Parsing

func printUsage() {
    print("""
    InputRemapper - Lightweight input remapping for Logitech devices

    Usage: input-remapper [options]

    Options:
      --debug     Print all intercepted events (for finding key codes)
      --help, -h  Show this help message

    The remapper runs as a daemon and intercepts mouse/keyboard events,
    transforming them according to the hardcoded mappings in Config.swift.

    For customization, see README.md.
    """)
}

func parseArguments() {
    let args = CommandLine.arguments

    for arg in args.dropFirst() {
        switch arg {
        case "--debug":
            debugMode = true
        case "--help", "-h":
            printUsage()
            exit(0)
        default:
            print("Unknown option: \(arg)")
            printUsage()
            exit(1)
        }
    }
}

// MARK: - Signal Handling

var remapper: InputRemapper?

func setupSignalHandlers() {
    // Handle Ctrl+C (SIGINT) and SIGTERM for graceful shutdown
    signal(SIGINT) { _ in
        print("\nReceived interrupt signal...")
        remapper?.stop()
        exit(0)
    }

    signal(SIGTERM) { _ in
        print("\nReceived termination signal...")
        remapper?.stop()
        exit(0)
    }
}

// MARK: - Main Entry Point

parseArguments()
setupSignalHandlers()

// We need AppKit's run loop for NSWorkspace
// Initialize the shared application (headless, no dock icon)
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)  // No dock icon, no menu bar

// Create and start the remapper
remapper = InputRemapper()
remapper?.start()
