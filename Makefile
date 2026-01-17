# InputRemapper Makefile
# Build, install, and manage the input remapping daemon

BINARY_NAME = input-remapper
APP_NAME = InputRemapper.app
BUNDLE_ID = com.user.InputRemapper

# Directories
BUILD_DIR = .build/release
APP_DIR = $(APP_NAME)/Contents/MacOS
INSTALL_DIR = /Applications
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents
PLIST_NAME = $(BUNDLE_ID).plist

.PHONY: all build clean install uninstall reload status logs help

# Default target
all: build

# Build release binary and create .app bundle
build:
	@echo "Building $(BINARY_NAME)..."
	@swift build -c release
	@echo "Creating $(APP_NAME) bundle..."
	@mkdir -p "$(APP_NAME)/Contents/MacOS"
	@cp "$(BUILD_DIR)/$(BINARY_NAME)" "$(APP_DIR)/InputRemapper"
	@cp Info.plist "$(APP_NAME)/Contents/" 2>/dev/null || \
		echo '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n\t<key>CFBundleExecutable</key>\n\t<string>InputRemapper</string>\n\t<key>CFBundleIdentifier</key>\n\t<string>$(BUNDLE_ID)</string>\n\t<key>CFBundleName</key>\n\t<string>InputRemapper</string>\n\t<key>CFBundleVersion</key>\n\t<string>1.0</string>\n\t<key>LSUIElement</key>\n\t<true/>\n</dict>\n</plist>' > "$(APP_NAME)/Contents/Info.plist"
	@echo "Build complete: $(APP_NAME)"

# Build debug version (faster compilation)
debug:
	@echo "Building $(BINARY_NAME) (debug)..."
	@swift build
	@mkdir -p "$(APP_NAME)/Contents/MacOS"
	@cp ".build/debug/$(BINARY_NAME)" "$(APP_DIR)/InputRemapper"
	@echo "Debug build complete."

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@swift package clean
	@rm -rf .build
	@rm -rf "$(APP_NAME)"
	@echo "Clean complete."

# Install app and LaunchAgent
install: build
	@echo ""
	@echo "Installing $(APP_NAME)..."
	@cp -R "$(APP_NAME)" "$(INSTALL_DIR)/"
	@echo "App installed to $(INSTALL_DIR)/$(APP_NAME)"
	@echo ""
	@echo "Installing LaunchAgent..."
	@mkdir -p "$(LAUNCH_AGENTS_DIR)"
	@sed 's|__INSTALL_DIR__|$(INSTALL_DIR)|g' "$(PLIST_NAME)" > "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)"
	@echo "LaunchAgent installed."
	@echo ""
	@echo "Loading daemon..."
	@launchctl unload "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)" 2>/dev/null || true
	@launchctl load "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)"
	@echo ""
	@echo "============================================"
	@echo "Installation complete!"
	@echo ""
	@echo "IMPORTANT: Grant Accessibility permission:"
	@echo "  1. Open System Settings > Privacy & Security > Accessibility"
	@echo "  2. Click '+' and add: $(INSTALL_DIR)/$(APP_NAME)"
	@echo "  3. Toggle it ON"
	@echo ""
	@echo "The app MUST be in Accessibility list to intercept input events."
	@echo "============================================"

# Uninstall completely
uninstall:
	@echo "Stopping daemon..."
	@launchctl unload "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)" 2>/dev/null || true
	@echo "Removing LaunchAgent..."
	@rm -f "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)"
	@echo "Removing app..."
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME)"
	@echo ""
	@echo "Uninstall complete."
	@echo "Note: Remove from Accessibility list manually if desired."

# Rebuild and reload (for development)
reload: build
	@echo "Reloading daemon..."
	@launchctl unload "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)" 2>/dev/null || true
	@cp -R "$(APP_NAME)" "$(INSTALL_DIR)/"
	@launchctl load "$(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)"
	@echo "Daemon reloaded."

# Check if daemon is running
status:
	@echo "Daemon status:"
	@launchctl list | grep -E "PID|InputRemapper" || echo "  Not loaded"
	@echo ""
	@echo "Process check:"
	@pgrep -l InputRemapper || echo "  Not running"

# View recent logs
logs:
	@echo "=== stdout (last 20 lines) ==="
	@tail -20 /tmp/input-remapper.log 2>/dev/null || echo "  No log file"
	@echo ""
	@echo "=== stderr (last 20 lines) ==="
	@tail -20 /tmp/input-remapper.err 2>/dev/null || echo "  No error log"

# Follow logs in real-time
logs-follow:
	@tail -f /tmp/input-remapper.log /tmp/input-remapper.err

# Run in foreground for testing (uses local .app, not installed)
run: build
	@echo "Running in foreground (Ctrl+C to stop)..."
	@"./$(APP_DIR)/InputRemapper"

# Run with debug output (shows all intercepted events)
run-debug: build
	@echo "Running in debug mode (Ctrl+C to stop)..."
	@echo "Press buttons/keys to see their codes."
	@echo ""
	@"./$(APP_DIR)/InputRemapper" --debug

# Show help
help:
	@echo "InputRemapper - Lightweight input remapping for Logitech devices"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build       Build release binary and .app bundle"
	@echo "  install     Install to /Applications and set up auto-start"
	@echo "  uninstall   Remove app and LaunchAgent"
	@echo "  reload      Rebuild and restart daemon (for development)"
	@echo ""
	@echo "  run         Run locally in foreground"
	@echo "  run-debug   Run with debug output (shows button/key codes)"
	@echo ""
	@echo "  status      Check if daemon is running"
	@echo "  logs        View recent log output"
	@echo "  logs-follow Follow logs in real-time"
	@echo ""
	@echo "  clean       Remove build artifacts"
	@echo "  help        Show this message"
	@echo ""
	@echo "First time setup:"
	@echo "  1. make install"
	@echo "  2. Add app to Accessibility in System Settings"
	@echo "  3. Done! Runs automatically at login."
