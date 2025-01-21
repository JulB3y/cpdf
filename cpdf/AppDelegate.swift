import AppKit
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var settingsWindow: NSWindow?
    @Published var isSettingsPresented = false
    
    private var aboutPanelOptions: [NSApplication.AboutPanelOptionKey: Any]?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Registriere für Benachrichtigungen
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("❌ Fehler bei der Benachrichtigungserlaubnis: \(error)")
            }
        }
        
        // Setze das Dock-Icon
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
        
        // Bereite About-Panel Optionen vor
        let credits = """
        © 2024 Julius Beyer
        """
        
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        
        // Speichere die Optionen für späteren Gebrauch
        aboutPanelOptions = [
            .credits: NSAttributedString(
                string: credits,
                attributes: [
                    .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
                ]
            ),
            .version: version,
            .applicationVersion: build
        ]
    }
    
    @objc func openSettings() {
        if isSettingsPresented {
            settingsWindow?.makeKeyAndOrderFront(nil)
            return
        }
        
        let settingsView = SettingsView(onDismiss: { [weak self] in
            self?.isSettingsPresented = false
            self?.settingsWindow?.close()
        })
        
        let hostingController = NSHostingController(rootView: settingsView)
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow?.title = String(localized: "Einstellungen")
        settingsWindow?.backgroundColor = .windowBackgroundColor
        settingsWindow?.center()
        settingsWindow?.contentViewController = hostingController
        settingsWindow?.isReleasedWhenClosed = false
        
        // Zeige das Fenster als Sheet
        if let mainWindow = NSApplication.shared.mainWindow {
            mainWindow.beginSheet(settingsWindow!) { _ in
                self.isSettingsPresented = false
            }
        }
        
        isSettingsPresented = true
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func showAboutPanel() {
        if let options = aboutPanelOptions {
            NSApplication.shared.orderFrontStandardAboutPanel(options: options)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
} 