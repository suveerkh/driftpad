import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var tray: TrayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        tray = TrayController()
    }
}