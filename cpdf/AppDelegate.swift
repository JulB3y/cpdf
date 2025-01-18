import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var settingsWindow: NSWindow?
    @Published var isSettingsPresented = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Entferne die Menü-Konfiguration hier, da sie jetzt in cpdfApp.swift ist
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
} 