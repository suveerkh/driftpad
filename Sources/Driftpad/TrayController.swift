import AppKit

final class TrayController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var notes: [NotePanel] = []
    private let settings = SettingsWindowController()

    override init() {
        super.init()
        guard let button = statusItem.button else { return }
        if let icon = Bundle.main.image(forResource: "TrayIconTemplate")
                   ?? Bundle.module.image(forResource: "TrayIconTemplate") {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = true      // macOS draws it black or white to match the menu bar
            button.image = icon
        } else {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Driftpad")
        }
        button.target = self
        button.action = #selector(trayClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func trayClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            newNote()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        let newItem = NSMenuItem(title: "New Note", action: #selector(newNote), keyEquivalent: "n")
        newItem.target = self
        menu.addItem(newItem)
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let aboutItem = NSMenuItem(title: "About Driftpad", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(NSMenuItem(title: "Quit Driftpad",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func showAbout() {
        let credits = NSAttributedString(
            string: "Made by Phantom",
            attributes: [.font: NSFont.systemFont(ofSize: 12),
                         .foregroundColor: NSColor.secondaryLabelColor])
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }

    @objc private func openSettings() {
        settings.show()
    }

    @objc func newNote() {
        let width = AppSettings.noteWidth
        let anchor = statusItem.button?.window?.frame ?? .zero
        let step = CGFloat(notes.count % 6) * 24   // cascade so notes don't stack exactly

        var topLeft = NSPoint(x: anchor.midX - width / 2 + step,
                              y: anchor.minY - 8 - step)

        if let visible = (statusItem.button?.window?.screen ?? NSScreen.main)?.visibleFrame {
            topLeft.x = min(max(topLeft.x, visible.minX + 8), visible.maxX - width - 8)
            topLeft.y = min(topLeft.y, visible.maxY - 8)
        }

        let panel = NotePanel(topLeft: topLeft)
        panel.onClose = { [weak self, weak panel] in
            self?.notes.removeAll { $0 === panel }
        }
        notes.append(panel)
        panel.makeKeyAndOrderFront(nil)
    }
}