import SwiftUI
import Foundation

// Language-Enumeration direkt in der Datei
enum Language: String, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        }
    }
}

struct SettingsView: View {
    @AppStorage("compressionQuality") private var compressionQuality = 0.5
    @AppStorage("appLanguage") private var appLanguage = Language.german.rawValue
    @State private var showingRestartAlert = false
    @State private var selectedLanguage: Language = .german
    
    var body: some View {
        Form {
            Section(LocalizedStringKey("Sprache / Language")) {
                Picker(LocalizedStringKey("Sprache"), selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: selectedLanguage) { newValue in
                    if appLanguage != newValue.rawValue {
                        appLanguage = newValue.rawValue
                        showingRestartAlert = true
                    }
                }
            }
            
            Section(LocalizedStringKey("PDF Komprimierung")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(LocalizedStringKey("Qualität: \(Int(compressionQuality * 100))%"))
                        Spacer()
                    }
                    
                    Slider(value: $compressionQuality, in: 0.1...1.0) { 
                        Text(LocalizedStringKey("Qualität"))
                    }
                    
                    Text(LocalizedStringKey("Niedrigere Qualität = kleinere Dateien"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .onAppear {
            selectedLanguage = Language(rawValue: appLanguage) ?? .german
        }
        .alert(LocalizedStringKey("Neustart erforderlich"), isPresented: $showingRestartAlert) {
            Button(LocalizedStringKey("Später")) { }
            Button(LocalizedStringKey("Jetzt neustarten")) {
                restartApp()
            }
        } message: {
            Text(LocalizedStringKey("Bitte starten Sie die App neu, damit die Sprachänderungen wirksam werden."))
        }
    }
    
    private func restartApp() {
        let url = Bundle.main.bundleURL
        let path = "/usr/bin/open"
        Process.launchedProcess(launchPath: path, arguments: [url.path])
        NSApp.terminate(nil)
    }
} 