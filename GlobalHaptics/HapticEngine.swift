import Cocoa
import Combine
import SwiftUI

// MARK: - Haptic Intensity

enum HapticIntensity: String, CaseIterable, Identifiable {
    case subtle = "Subtle"
    case medium = "Medium"
    case strong = "Strong"
    case ultra = "Ultra Mechanical"

    var id: String { rawValue }

    var pattern: NSHapticFeedbackManager.FeedbackPattern {
        switch self {
        case .subtle: return .alignment
        case .medium: return .levelChange
        case .strong: return .generic
        case .ultra: return .generic
        }
    }
}

// MARK: - Haptic Engine

final class HapticEngine: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var isRunning: Bool = false
    @Published var intensity: HapticIntensity = .ultra
    @Published var isAccessibilityGranted: Bool = false
    @Published var enableAtLoginScreen: Bool = true

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private var pollTimer: Timer?
    private var lastHapticTime: Date = Date.distantPast

    init() {
        checkAccessibility()
        setupLockScreenObservers()
        startAccessibilityPolling()
    }

    @discardableResult
    func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let granted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        DispatchQueue.main.async {
            if self.isAccessibilityGranted != granted {
                self.isAccessibilityGranted = granted
            }
        }
        return granted
    }

    func startAccessibilityPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let granted = self.checkAccessibility()
            if granted && self.isEnabled && !self.isRunning {
                self.startMonitoring()
            }
        }
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let granted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        DispatchQueue.main.async {
            self.isAccessibilityGranted = granted
        }
        if !granted {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        if enabled {
            startMonitoring()
        } else {
            stop()
        }
    }

    func previewHaptic() {
        triggerHapticPulse(pattern: intensity.pattern)
    }

    private func triggerHapticPulse(pattern: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
        if intensity == .ultra {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.015) {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        }
    }

    func startMonitoring() {
        stop()
        guard isEnabled else { return }
        
        guard checkAccessibility() else {
            isRunning = false
            return
        }

        isRunning = true
        startCGEventTap()
        startNSEventMonitorFallback()
    }

    // MARK: - CGEventTap for Login Screen, Lock Screen & System-wide Events

    private func startCGEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.scrollWheel.rawValue) |
                                     (1 << CGEventType.leftMouseDown.rawValue) |
                                     (1 << CGEventType.rightMouseDown.rawValue) |
                                     (1 << CGEventType.otherMouseDown.rawValue) |
                                     (1 << CGEventType.leftMouseDragged.rawValue) |
                                     (1 << CGEventType.rightMouseDragged.rawValue) |
                                     (1 << CGEventType.otherMouseDragged.rawValue) |
                                     (1 << CGEventType.mouseMoved.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<HapticEngine>.fromOpaque(refcon).takeUnretainedValue()
            engine.handleCGEvent(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: selfPointer
        ) else {
            NSLog("[GlobalHaptics] CGEvent.tapCreate failed. Falling back to NSEvent monitor.")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("[GlobalHaptics] CGEventTap initialized for Login & Lock Screen haptics.")
    }

    func handleCGEvent(type: CGEventType, event: CGEvent) {
        guard isEnabled else { return }
        let now = Date()

        let throttleInterval: TimeInterval
        switch intensity {
        case .subtle: throttleInterval = 0.05
        case .medium: throttleInterval = 0.04
        case .strong: throttleInterval = 0.03
        case .ultra: throttleInterval = 0.02
        }

        guard now.timeIntervalSince(lastHapticTime) >= throttleInterval else { return }

        if type == .scrollWheel {
            let deltaY = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis1)
            let deltaX = event.getIntegerValueField(.scrollWheelEventPointDeltaAxis2)
            if abs(deltaY) > 0 || abs(deltaX) > 0 {
                lastHapticTime = now
                triggerHapticPulse(pattern: intensity.pattern)
            }
        } else if type == .mouseMoved || type == .leftMouseDragged || type == .rightMouseDragged || type == .otherMouseDragged {
            lastHapticTime = now
            triggerHapticPulse(pattern: intensity.pattern)
        } else if type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown {
            lastHapticTime = now
            triggerHapticPulse(pattern: .generic)
        }
    }

    // MARK: - NSEvent Fallback

    private func startNSEventMonitorFallback() {
        let eventMask: NSEvent.EventTypeMask = [.scrollWheel, .leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .mouseMoved]
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            guard let self = self, self.isEnabled, self.eventTap == nil else { return }
            
            let now = Date()
            guard now.timeIntervalSince(self.lastHapticTime) > 0.04 else { return }
            
            self.lastHapticTime = now
            self.triggerHapticPulse(pattern: self.intensity.pattern)
        }
    }

    // MARK: - Lock Screen & Login Window Observers

    private func setupLockScreenObservers() {
        let dnc = DistributedNotificationCenter.default()
        
        dnc.addObserver(self, selector: #selector(screenLocked), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenUnlocked), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenLocked), name: Notification.Name("com.apple.sessionDidResignActive"), object: nil)
        dnc.addObserver(self, selector: #selector(screenUnlocked), name: Notification.Name("com.apple.sessionDidBecomeActive"), object: nil)
    }

    @objc private func screenLocked() {
        NSLog("[GlobalHaptics] macOS screen locked / login window active. Ensuring CGEventTap running...")
        if isEnabled && enableAtLoginScreen {
            startCGEventTap()
        }
    }

    @objc private func screenUnlocked() {
        NSLog("[GlobalHaptics] macOS unlocked. Resuming haptics.")
        if isEnabled {
            startMonitoring()
        }
    }

    func lockScreenToTestLoginHaptics() {
        let lib = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/A/login", RTLD_LAZY)
        if let symbol = dlsym(lib, "SACLockScreenImmediate") {
            typealias LockFunc = @convention(c) () -> Void
            let lockFunc = unsafeBitCast(symbol, to: LockFunc.self)
            lockFunc()
        } else {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            task.arguments = ["displaysleepnow"]
            try? task.run()
        }
    }

    func previewLoginHapticRhythm() {
        for i in 0..<6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) { [weak self] in
                self?.triggerHapticPulse(pattern: self?.intensity.pattern ?? .generic)
            }
        }
    }

    func quitApp() {
        stop()
        NSApp.terminate(nil)
    }

    func stop() {
        isRunning = false
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            runLoopSource = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    deinit {
        pollTimer?.invalidate()
        DistributedNotificationCenter.default().removeObserver(self)
        stop()
    }
}


