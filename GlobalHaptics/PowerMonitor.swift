// ─────────────────────────────────────────────────────────────────────────────
// PowerMonitor.swift — GlobalHaptics
//
// Uses IOKit IOPowerSources API to detect AC vs battery power in real time.
// Publishes `isPluggedIn` via Combine so AppDelegate can reactively gate haptics.
//
// No polling — uses IOPSNotificationCreateRunLoopSource for instant notifications.
// ─────────────────────────────────────────────────────────────────────────────
import Foundation
import IOKit.ps
import Combine

final class PowerMonitor: ObservableObject {

    /// True when AC power adapter is connected. False when on battery only.
    @Published private(set) var isPluggedIn: Bool = true

    private var runLoopSource: CFRunLoopSource?
    private var retainedSelf:  Unmanaged<PowerMonitor>?

    // MARK: - Public API

    func startMonitoring() {
        // Synchronous initial check before the first notification fires
        isPluggedIn = currentPowerState()
        NSLog("[GlobalHaptics] PowerMonitor: initial state — %@", isPluggedIn ? "AC ⚡" : "Battery 🔋")

        // Retain self so the C callback can reference us safely
        let retained   = Unmanaged.passRetained(self)
        retainedSelf   = retained

        // IOPSNotificationCreateRunLoopSource fires on every power change
        runLoopSource = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context = context else { return }
                let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
                let newState = monitor.currentPowerState()
                DispatchQueue.main.async {
                    if monitor.isPluggedIn != newState {
                        NSLog("[GlobalHaptics] PowerMonitor: changed to %@", newState ? "AC ⚡" : "Battery 🔋")
                        monitor.isPluggedIn = newState
                    }
                }
            },
            retained.toOpaque()
        ).takeRetainedValue()

        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    }

    func stopMonitoring() {
        if let src = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            runLoopSource = nil
        }
        retainedSelf?.release()
        retainedSelf = nil
    }

    // MARK: - Private: IOKit Query

    /// Returns true if at least one power source reports AC power.
    /// Returns true by default on desktop Macs (no battery present).
    private func currentPowerState() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return true   // No info → assume desktop / always plugged in
        }
        guard let sourceList = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sourceList.isEmpty else {
            return true   // No battery → desktop Mac → always on AC
        }
        for source in sourceList {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?
                    .takeUnretainedValue() as? [String: Any] else { continue }
            if let state = desc[kIOPSPowerSourceStateKey] as? String {
                return state == kIOPSACPowerValue
            }
        }
        return true
    }
}
