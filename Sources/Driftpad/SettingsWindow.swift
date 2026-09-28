import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
                             styleMask: [.titled, .closable],
                             backing: .buffered,
                             defer: false)
            w.title = "Driftpad Settings"
            w.isReleasedWhenClosed = false
            w.contentView = NSHostingView(rootView: SettingsView())
            w.center()
            window = w
        }
        NSApp.activate()   // tray apps must bring themselves forward to show a window
        window?.makeKeyAndOrderFront(nil)
    }
}

struct SettingsView: View {
    @AppStorage(AppSettings.disappearMinutesKey) private var minutes = AppSettings.defaultMinutes
    @AppStorage(AppSettings.tintHexKey) private var tintHex = AppSettings.defaultTintHex
    @AppStorage(AppSettings.tintStrengthKey) private var tintStrength = AppSettings.defaultTintStrength

    private let durationPresets = [1, 2, 5, 10, 15, 30, 60]

    private var tint: Color { Color(hex: tintHex) }

    /// Presets plus the saved value, in case it was set to something else earlier.
    private var durationOptions: [Int] {
        Array(Set(durationPresets + [minutes])).sorted()
    }

    private var customColor: Binding<Color> {
        Binding(get: { Color(hex: tintHex) },
                set: { tintHex = $0.hexString })
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker("Disappear after", selection: $minutes) {
                        ForEach(durationOptions, id: \.self) { value in
                            Text(label(forMinutes: value)).tag(value)
                        }
                    }
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Unpinned notes fade away after this time. Hovering or typing pauses the countdown; pinned notes stay until you unpin them.")
                        .foregroundStyle(.secondary)
                }

                Section("Appearance") {
                    LabeledContent("Color") {
                        HStack(spacing: 8) {
                            ForEach(TintPreset.all) { preset in
                                swatch(preset)
                            }
                            ColorPicker("Custom color", selection: customColor, supportsOpacity: false)
                                .labelsHidden()
                                .help("Custom color")
                        }
                    }

                    Slider(value: $tintStrength, in: 0.05...0.5) {
                        Text("Tint strength")
                    } minimumValueLabel: {
                        Image(systemName: "circle.lefthalf.filled").foregroundStyle(Color.secondary)
                    } maximumValueLabel: {
                        Image(systemName: "circle.fill").foregroundStyle(tint)
                    }

                    preview
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Text("Driftpad \(appVersion) · Made by Phantom")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Restore Defaults", action: restoreDefaults)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 460, height: 520)
    }

    // MARK: - Pieces

    private func swatch(_ preset: TintPreset) -> some View {
        let isSelected = preset.hex.caseInsensitiveCompare(tintHex) == .orderedSame
        return Button {
            tintHex = preset.hex
        } label: {
            Circle()
                .fill(Color(hex: preset.hex))
                .frame(width: 20, height: 20)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(isSelected ? 0.5 : 0.1), lineWidth: isSelected ? 2 : 1)
                        .padding(-3)
                )
                .padding(3)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(preset.name)
        .accessibilityLabel(preset.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// A sample note showing the current color and strength.
    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                Text("1:42")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "pin.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("Preview of a note")
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 260)
        .noteGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous),
                   tint: tint, strength: tintStrength)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .accessibilityHidden(true)
    }

    // MARK: - Helpers

    private func label(forMinutes value: Int) -> String {
        if value >= 60 && value % 60 == 0 {
            let hours = value / 60
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return value == 1 ? "1 minute" : "\(value) minutes"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func restoreDefaults() {
        minutes = AppSettings.defaultMinutes
        tintHex = AppSettings.defaultTintHex
        tintStrength = AppSettings.defaultTintStrength
    }
}