import SwiftUI
import AppKit

/// App-wide settings and constants
enum AppSettings {
    static let disappearMinutesKey = "disappearMinutes"
    static let tintHexKey = "noteTintHex"
    static let tintStrengthKey = "noteTintStrength"

    static let defaultMinutes = 2
    static let defaultTintHex = "#8B5CF6"      
    static let defaultTintStrength = 0.15

    static let dimDelay: TimeInterval = 2      
    static let dimmedAlpha: CGFloat = 0.3     
    static let typingPause: TimeInterval = 2  
    static let noteWidth: CGFloat = 280
    static let maxNoteLines = 14               

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            disappearMinutesKey: defaultMinutes,
            tintHexKey: defaultTintHex,
            tintStrengthKey: defaultTintStrength,
        ])
    }

    static var disappearSeconds: TimeInterval {
        let minutes = max(1, UserDefaults.standard.integer(forKey: disappearMinutesKey))
        return TimeInterval(minutes * 60)
    }
}

struct TintPreset: Identifiable {
    let name: String
    let hex: String
    var id: String { hex }

    static let all: [TintPreset] = [
        TintPreset(name: "Purple", hex: "#8B5CF6"),
        TintPreset(name: "Blue", hex: "#3B82F6"),
        TintPreset(name: "Teal", hex: "#14B8A6"),
        TintPreset(name: "Green", hex: "#22C55E"),
        TintPreset(name: "Amber", hex: "#F59E0B"),
        TintPreset(name: "Pink", hex: "#EC4899"),
        TintPreset(name: "Graphite", hex: "#6B7280"),
    ]
}

extension Color {
    init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else {
            self = Color(red: 0.545, green: 0.361, blue: 0.965)
            return
        }
        self = Color(red: Double((value >> 16) & 0xFF) / 255,
                     green: Double((value >> 8) & 0xFF) / 255,
                     blue: Double(value & 0xFF) / 255)
    }

    var hexString: String {
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .systemPurple
        return String(format: "#%02X%02X%02X",
                      Int((c.redComponent * 255).rounded()),
                      Int((c.greenComponent * 255).rounded()),
                      Int((c.blueComponent * 255).rounded()))
    }
}