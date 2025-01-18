import SwiftUI
import Foundation

enum ColorMode: String, CaseIterable, Identifiable {
    case fullColor = "full"
    case grayscale = "gray"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .fullColor: return String(localized: "Voller Farbraum")
        case .grayscale: return String(localized: "Graustufen")
        }
    }
}

struct SettingsView: View {
    @AppStorage("compressionQuality") private var compressionQuality = 0.5
    @AppStorage("appLanguage") private var appLanguage = Language.german.rawValue
    @AppStorage("colorMode") private var colorMode = ColorMode.fullColor.rawValue
    @State private var showingRestartAlert = false
    @State private var selectedLanguage: Language = .german
    @State private var selectedColorMode: ColorMode = .fullColor
    
    var body: some View {
        Form {
            Section {
                Picker(LocalizedStringKey("Sprache"), selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: selectedLanguage) { oldValue, newValue in
                    if appLanguage != newValue.rawValue {
                        appLanguage = newValue.rawValue
                        showingRestartAlert = true
                    }
                }
            } header: {
                Text(LocalizedStringKey("Sprache / Language"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
            }
            
            Section {
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
                    
                    Picker(LocalizedStringKey("Farbmodus"), selection: $selectedColorMode) {
                        ForEach(ColorMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .onChange(of: selectedColorMode) { oldValue, newValue in
                        colorMode = newValue.rawValue
                    }
                }
            } header: {
                Text(LocalizedStringKey("PDF Komprimierung"))
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
        .onAppear {
            selectedLanguage = Language(rawValue: appLanguage) ?? .german
            selectedColorMode = ColorMode(rawValue: colorMode) ?? .fullColor
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