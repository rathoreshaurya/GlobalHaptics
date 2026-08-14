import SwiftUI
import Combine
import ServiceManagement

struct ContentView: View {
    @ObservedObject var hapticEngine: HapticEngine
    @ObservedObject var powerMonitor: PowerMonitor

    @State private var launchAtLogin: Bool = false
    @State private var isTestingHover: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // MARK: - Hero Header Card with Custom App Icon
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 46, height: 46)
                                .blur(radius: 4)

                            if let headerImage = loadHeaderImage() {
                                Image(nsImage: headerImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 42, height: 42)
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                            } else {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("GlobalHaptics")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                // Live Status Badge
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(hapticEngine.isEnabled ? Color.green : Color.gray)
                                        .frame(width: 6, height: 6)
                                    Text(hapticEngine.isEnabled ? "Active ⚡️" : "Paused ⏸")
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(hapticEngine.isEnabled ? .green : .secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(hapticEngine.isEnabled ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                                )
                                .fixedSize(horizontal: true, vertical: false)
                            }

                            Text("Pure Mechanical Trackpad Feel • Login & Lock Screen")
                                .font(.system(size: 10.5, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: true, vertical: false)
                        }

                        Spacer(minLength: 6)

                        // Main Master Switch
                        Toggle("", isOn: Binding(
                            get: { hapticEngine.isEnabled },
                            set: { hapticEngine.setEnabled($0) }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // MARK: - Login Screen & Startup Settings Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.purple)
                            Text("Login & Lock Screen Integration")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            Spacer()
                        }

                        Divider()

                        // Login Screen Haptics Toggle
                        Toggle(isOn: $hapticEngine.enableAtLoginScreen) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Active at Login Screen & Lock Screen")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .lineLimit(1)
                                Text("Keeps trackpad haptics active when macOS is locked or at the login window.")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .purple))

                        if #available(macOS 13.0, *) {
                            Divider()

                            // Launch Automatically at Login
                            Toggle(isOn: $launchAtLogin) {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Launch Automatically at System Startup")
                                        .font(.system(size: 11.5, weight: .medium))
                                        .lineLimit(1)
                                    Text("Starts the background haptic engine automatically when your Mac boots up.")
                                        .font(.system(size: 9.5))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                            .onChange(of: launchAtLogin) { newValue in
                                do {
                                    if newValue {
                                        try SMAppService.mainApp.register()
                                    } else {
                                        try SMAppService.mainApp.unregister()
                                    }
                                } catch {
                                    NSLog("Failed to set launch at login: \(error)")
                                }
                            }
                            .onAppear {
                                launchAtLogin = (SMAppService.mainApp.status == .enabled)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // MARK: - Accessibility Permission Status Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(hapticEngine.isAccessibilityGranted ? .green : .orange)
                            Text("Accessibility Permission")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                            
                            if hapticEngine.isAccessibilityGranted {
                                Text("Granted ✓")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.green.opacity(0.15)))
                            } else {
                                Text("Action Required ⚠️")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.red.opacity(0.15)))
                            }
                        }

                        Text("GlobalHaptics uses macOS Accessibility APIs to listen to trackpad scroll & drag gestures system-wide.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)

                        if !hapticEngine.isAccessibilityGranted {
                            Button(action: {
                                hapticEngine.requestAccessibilityPermission()
                            }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Grant Permission in System Settings")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // MARK: - Haptic Strength Personality Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)
                            Text("Mechanical Haptic Intensity")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                        }

                        HStack(spacing: 6) {
                            ForEach(HapticIntensity.allCases) { item in
                                Button(action: {
                                    hapticEngine.intensity = item
                                    hapticEngine.previewHaptic()
                                }) {
                                    Text(item.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(hapticEngine.intensity == item ? Color.purple : Color.secondary.opacity(0.12))
                                        )
                                        .foregroundColor(hapticEngine.intensity == item ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // MARK: - Tactile & Login Screen Test Area
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.purple)
                            Text("Live Haptic Testing & Login Screen Test")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Button(action: {
                                hapticEngine.previewHaptic()
                            }) {
                                Label("Test Single Pulse", systemImage: "hand.tap.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)

                            Button(action: {
                                hapticEngine.previewLoginHapticRhythm()
                            }) {
                                Label("Test Login Rhythm", systemImage: "waveform.path")
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                        }

                        // Lock Screen & Test Button
                        Button(action: {
                            hapticEngine.lockScreenToTestLoginHaptics()
                        }) {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text("Lock Screen & Test Login Haptics")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        // Interactive Drag Pad
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.purple.opacity(isTestingHover ? 0.2 : 0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                            
                            HStack(spacing: 5) {
                                Image(systemName: "hand.point.up.left.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.purple)
                                Text("Glide finger here to test live trackpad haptics")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 36)
                        .onHover { hovering in
                            isTestingHover = hovering
                            if hovering {
                                hapticEngine.previewHaptic()
                            }
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // MARK: - Support & Feedback Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "envelope.badge.shield.halfopen.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.blue)
                            Text("Support & Developer Links")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                        }

                        HStack(spacing: 8) {
                            Button(action: {
                                let email = "shaurya.rathore.789@gmail.com"
                                let subject = "GlobalHaptics Feedback / Support"
                                if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("Send Email Feedback", systemImage: "envelope.fill")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)

                            Button(action: {
                                if let url = URL(string: "https://github.com/rathoreshaurya") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                Label("GitHub Profile", systemImage: "person.crop.circle.fill")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    )

                    // MARK: - Quit App Section
                    Button(action: {
                        hapticEngine.quitApp()
                    }) {
                        HStack {
                            Image(systemName: "power")
                                .font(.system(size: 12, weight: .bold))
                            Text("Quit GlobalHaptics Entirely")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.red.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }

            // MARK: - Pinned Footer Signature Badge
            HStack(spacing: 5) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Engineered for Apple Silicon")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.secondary)
                Text("•")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.purple.opacity(0.5))
                Text("Built by Shaurya Rathore")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(Color.purple.opacity(0.12))
                    .overlay(
                        Capsule()
                            .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                    )
            )
            .padding(.bottom, 8)
            .padding(.top, 4)
        }
        .frame(width: 440, height: 600)
        .background(VisualEffectView().ignoresSafeArea())
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            hapticEngine.checkAccessibility()
        }
    }

    // Helper to load header icon
    private func loadHeaderImage() -> NSImage? {
        if let img = NSImage(named: "AppIconHeader") {
            return img
        }
        let bundlePath = Bundle.main.path(forResource: "AppIconHeader", ofType: "png")
        if let path = bundlePath, let img = NSImage(contentsOfFile: path) {
            return img
        }
        return NSImage(contentsOfFile: "/Users/shauryarathore/Desktop/Applications/GlobalHaptics/GlobalHaptics/AppIconHeader.png")
    }
}

// MARK: - Glassmorphism Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
