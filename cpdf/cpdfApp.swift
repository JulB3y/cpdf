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
            
            // Erzwinge einen Neustart der App-Sprache
            Bundle.main.localizations
            
            if let languageBundle = Bundle.main.path(forResource: languageCode, ofType: "lproj") {
                print("📂 Gefundener Sprachpfad: \(languageBundle)")
                if let bundle = Bundle(path: languageBundle) {
                    bundle.load()
                    print("✅ Sprachbundle geladen")
                }
            } else {
                print("❌ Sprachbundle nicht gefunden für: \(languageCode)")
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