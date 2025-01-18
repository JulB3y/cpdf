//
//  cpdfApp.swift
//  cpdf
//
//  Created by Julius Beyer on 14.01.25.
//

import SwiftUI

@main
struct cpdfApp: App {
    @StateObject private var pdfCompressor = PDFCompressor()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        if let languageCode = UserDefaults.standard.string(forKey: "appLanguage") {
            print("🌍 Ausgewählte Sprache: \(languageCode)")
            
            // Setze die Sprache für die gesamte App
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            UserDefaults.standard.set(languageCode, forKey: "AppleLocale")
            UserDefaults.standard.synchronize()
            
            // Debug-Ausgaben
            print("📦 Verfügbare Lokalisierungen: \(Bundle.main.localizations)")
            print("🔍 Aktuelle Locale: \(Locale.current.identifier)")
            
            // Versuche das Bundle zu laden
            if let bundlePath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
               let bundle = Bundle(path: bundlePath) {
                print("✅ Sprachbundle gefunden und geladen: \(bundlePath)")
                bundle.load()
            } else {
                print("❌ Sprachbundle nicht gefunden für: \(languageCode)")
                print("📂 Suchpfad: \(Bundle.main.bundlePath)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pdfCompressor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
} 