# ⚡️ GlobalHaptics

A lightweight, native macOS utility that brings a premium, mechanical trackpad feel to your Mac by triggering customizable haptic feedback during scroll, drag, and move gestures—even on the macOS Lock Screen and Login Window.

Built using Swift and SwiftUI with a modern macOS glassmorphic control panel.

---

## ✨ Features

- **🎯 System-wide Trackpad Haptics:** Recreate a tactile, mechanical-wheel clicking sensation when scrolling, dragging, or moving the mouse.
- **🔒 Lock Screen & Login Window Support:** Utilizing low-level system-wide `CGEventTap` APIs, the haptic engine keeps working seamlessly when macOS is locked or showing the login screen.
- **🔋 Zero-Polling Power Awareness:** Uses `IOKit`'s `IOPowerSources` run loop notification API to detect AC vs. battery connection instantly, allowing haptic behaviors to save energy reactively.
- **⚡ Multiple Haptic Personalities:** Choose between four haptic strengths:
  - **Subtle** (using alignment feedback)
  - **Medium** (using level change feedback)
  - **Strong** (using generic click patterns)
  - **Ultra Mechanical** (a double-pulse sequence with sub-millisecond precision)
- **🚀 Launch at Startup:** Integrated with `SMAppService` for clean autostart on user login.
- **🛸 Menu Bar Helper:** A convenient status bar icon (⚡️) to toggle haptics, test pulses, or open settings on the fly.
- **🧪 Interactive Test Zone:** Real-time haptic test pad and simulated lock-screen testing tools built directly into the UI.

---

## 🛠 Tech Stack

- **Frameworks:** Swift, SwiftUI, AppKit/Cocoa
- **System APIs:** `CGEventTap` (mouse/scroll event capturing), `DistributedNotificationCenter` (macOS sleep/unlock detection), `IOKit` (power source monitoring), `ServiceManagement` (login item agent)
- **UI Design:** Glassmorphic translucent controls powered by `NSVisualEffectView`

---

## 🚀 Getting Started

### Prerequisites
- A Mac with a Force Touch trackpad.
- macOS 13.0 (Ventura) or newer.
- Xcode 14+ (for compilation).

### Quick Build & Install
You can build and install the application automatically using the provided installer script:

```bash
chmod +x install.sh
./install.sh
```

This script will:
1. Compile the project in release mode using `xcodebuild`.
2. Move the built application to your `/Applications` directory.
3. Sign the binary locally using ad-hoc signing.
4. Launch the application in your menu bar.

### Accessibility Permission
Because GlobalHaptics listens to system-wide trackpad events, macOS requires Accessibility authorization:
1. Open the **GlobalHaptics Control Panel**.
2. Click **Grant Permission in System Settings**.
3. Toggle on **GlobalHaptics** under *System Settings ➔ Privacy & Security ➔ Accessibility*.

---

## 👤 Author

Developed with ❤️ by **Shaurya Rathore**.
