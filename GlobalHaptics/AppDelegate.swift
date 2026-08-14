import Cocoa
import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var mainWindow: NSWindow?
    let hapticEngine = HapticEngine()
    let powerMonitor = PowerMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply Custom App Icon to NSApplication
        if let iconImage = loadAppIconImage() {
            NSApplication.shared.applicationIconImage = iconImage
        }

        // Create NSStatusItem in status bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.isVisible = true
        
        if let button = statusItem?.button {
            if let symbolImage = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "GlobalHaptics") {
                symbolImage.isTemplate = true
                button.image = symbolImage
            }
            button.title = " ⚡️ Haptics"
            button.imagePosition = .imageLeft
            button.toolTip = "GlobalHaptics - Trackpad Haptics"
        }
        
        updateMenu()
        
        let isGranted = hapticEngine.checkAccessibility()
        if !isGranted {
            hapticEngine.requestAccessibilityPermission()
        } else {
            hapticEngine.startMonitoring()
        }
        
        powerMonitor.startMonitoring()

        // Open main control window on launch
        openControlPanel()
    }

    func updateMenu() {
        let menu = NSMenu()
        menu.delegate = self
        
        let isGranted = hapticEngine.checkAccessibility()
        let statusTitle: String
        if !hapticEngine.isEnabled {
            statusTitle = "GlobalHaptics: Disabled ⏸"
        } else if isGranted {
            statusTitle = "GlobalHaptics: Active at Login & Desktop ⚡️"
        } else {
            statusTitle = "GlobalHaptics: Needs Accessibility ⚠️"
        }
        
        let statusMenuItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let openPanelItem = NSMenuItem(title: "Open Control Panel...", action: #selector(openControlPanel), keyEquivalent: "o")
        openPanelItem.target = self
        menu.addItem(openPanelItem)

        // Toggle Enabled/Disabled
        let toggleTitle = hapticEngine.isEnabled ? "Disable Haptics" : "Enable Haptics"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleHaptics), keyEquivalent: "e")
        toggleItem.target = self
        menu.addItem(toggleItem)

        // Accessibility Permission
        if !isGranted {
            let grantItem = NSMenuItem(title: "Grant Accessibility Permission...", action: #selector(openAccessibilitySettings), keyEquivalent: "")
            grantItem.target = self
            menu.addItem(grantItem)
        } else {
            let grantedItem = NSMenuItem(title: "Accessibility Permission: Granted ✓", action: nil, keyEquivalent: "")
            grantedItem.isEnabled = false
            menu.addItem(grantedItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Preview Haptic Pulse
        let testItem = NSMenuItem(title: "Test Haptic Pulse", action: #selector(testHaptic), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login
        if #available(macOS 13.0, *) {
            let isAutoLaunch = SMAppService.mainApp.status == .enabled
            let launchAtLoginItem = NSMenuItem(
                title: isAutoLaunch ? "Launch at Login: Enabled ✓" : "Enable Launch at Login",
                action: #selector(toggleLaunchAtLogin),
                keyEquivalent: ""
            )
            launchAtLoginItem.target = self
            menu.addItem(launchAtLoginItem)
        }

        menu.addItem(NSMenuItem.separator())

        let sendFeedbackItem = NSMenuItem(title: "Send Email Feedback...", action: #selector(openFeedbackEmail), keyEquivalent: "")
        sendFeedbackItem.target = self
        menu.addItem(sendFeedbackItem)

        let openGitHubItem = NSMenuItem(title: "Visit GitHub Profile...", action: #selector(openGitHubProfile), keyEquivalent: "")
        openGitHubItem.target = self
        menu.addItem(openGitHubItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit GlobalHaptics", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }

    @objc func openControlPanel() {
        if mainWindow == nil {
            let contentView = ContentView(hapticEngine: hapticEngine, powerMonitor: powerMonitor)
            let hostingController = NSHostingController(rootView: contentView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.title = "Global Haptics Control Panel"
            window.titlebarAppearsTransparent = true
            window.contentViewController = hostingController
            window.isMovableByWindowBackground = true
            window.setFrameAutosaveName("GlobalHapticsMainWindow")
            
            self.mainWindow = window
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc func toggleHaptics() {
        hapticEngine.setEnabled(!hapticEngine.isEnabled)
        updateMenu()
    }

    @objc func openAccessibilitySettings() {
        hapticEngine.requestAccessibilityPermission()
    }

    @objc func testHaptic() {
        hapticEngine.previewHaptic()
    }

    @objc func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                NSLog("[GlobalHaptics] Failed to toggle launch at login: \(error)")
            }
            updateMenu()
        }
    }

    @objc func openFeedbackEmail() {
        let email = "shaurya.rathore.789@gmail.com"
        let subject = "GlobalHaptics Feedback / Support"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openGitHubProfile() {
        if let url = URL(string: "https://github.com/rathoreshaurya") {
            NSWorkspace.shared.open(url)
        }
    }

    private func loadAppIconImage() -> NSImage? {
        if let headerImg = NSImage(named: "AppIconHeader") {
            return headerImg
        }
        return NSImage(contentsOfFile: "/Users/shauryarathore/Desktop/Applications/GlobalHaptics/GlobalHaptics/AppIconHeader.png")
    }
}

