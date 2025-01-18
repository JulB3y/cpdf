import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Erstelle das Menü-Item in der Menüleiste
        let appMenu = NSMenu()
        let appName = ProcessInfo.processInfo.processName
        
        // App Menü
        let mainMenuItem = NSMenuItem()
        mainMenuItem.submenu = NSMenu(title: appName)
        
        // Einstellungen
        let settingsItem = NSMenuItem(
            title: String(localized: "Einstellungen"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        mainMenuItem.submenu?.addItem(settingsItem)
        
        // Separator
        mainMenuItem.submenu?.addItem(.separator())
        
        // Beenden
        let quitItem = NSMenuItem(
            title: String(localized: "Beenden"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        mainMenuItem.submenu?.addItem(quitItem)
        
        // Füge das Menü zur Menüleiste hinzu
        appMenu.addItem(mainMenuItem)
        NSApp.mainMenu = appMenu
    }
    
    @objc private func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 250),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = String(localized: "Einstellungen")
            settingsWindow?.center()
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            settingsWindow?.isReleasedWhenClosed = false
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup beim Beenden
        if let statusItem = NSApp.windowsMenu?.items.first as? NSStatusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
} 