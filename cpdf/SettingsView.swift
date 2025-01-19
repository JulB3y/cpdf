import SwiftUI
import Foundation

struct SettingsView: View {
    let onDismiss: () -> Void
    @AppStorage("appLanguage") private var appLanguage = Language.german.rawValue
    @AppStorage("colorMode") private var colorMode = ColorMode.fullColor.rawValue
    @AppStorage("compressionQuality") private var compressionQuality = CompressionQuality.medium.rawValue
    @State private var showingRestartAlert = false
    @State private var selectedLanguage: Language
    @State private var selectedColorMode: ColorMode
    @State private var selectedQuality: CompressionQuality
    @State private var selectedTab = "General"
    
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        // Initialisiere alle Einstellungen mit den gespeicherten Werten
        let currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? Language.german.rawValue
        let currentColorMode = UserDefaults.standard.string(forKey: "colorMode") ?? ColorMode.fullColor.rawValue
        let currentQuality = UserDefaults.standard.string(forKey: "compressionQuality") ?? CompressionQuality.medium.rawValue
        
        _selectedLanguage = State(initialValue: Language(rawValue: currentLanguage) ?? .german)
        _selectedColorMode = State(initialValue: ColorMode(rawValue: currentColorMode) ?? .fullColor)
        _selectedQuality = State(initialValue: CompressionQuality(rawValue: currentQuality) ?? .medium)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Titelleiste
            Text("Settings")
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(NSColor.windowBackgroundColor))
            
            // Tabs
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gearshape.fill", isSelected: selectedTab == "General") {
                    selectedTab = "General"
                }
                
                TabButton(title: "Info", icon: "info.circle.fill", isSelected: selectedTab == "Info") {
                    selectedTab = "Info"
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
            
            Divider()
            
            // Content
            if selectedTab == "General" {
                ScrollView {
                    VStack(spacing: 20) {
                        // Sprache
                        GroupBox {
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
                        } label: {
                            Text(LocalizedStringKey("Sprache / Language"))
                                .font(.headline)
                        }
                        .background(Color(NSColor.windowBackgroundColor))
                        
                        // PDF Komprimierung
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Picker(LocalizedStringKey("Kompressionsgrad"), selection: $selectedQuality) {
                                    ForEach(CompressionQuality.allCases) { quality in
                                        Text(quality.displayName).tag(quality)
                                    }
                                }
                                
                                Text(LocalizedStringKey("Niedrigere Auflösung = kleinere Dateien"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker(LocalizedStringKey("Farbmodus"), selection: $selectedColorMode) {
                                    ForEach(ColorMode.allCases) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                            }
                        } label: {
                            Text(LocalizedStringKey("PDF Komprimierung"))
                                .font(.headline)
                        }
                        .background(Color(NSColor.windowBackgroundColor))
                    }
                    .padding()
                }
                .background(Color(NSColor.windowBackgroundColor))
            } else {
                // Info Tab
                ScrollView {
                    VStack(spacing: 20) {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                InfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                InfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            }
                        } label: {
                            Text("App Information")
                                .font(.headline)
                        }
                    }
                    .padding()
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .overlay(
            Button(LocalizedStringKey("Done")) {
                onDismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            .buttonStyle(.borderedProminent)
            .padding(16),
            alignment: .bottomTrailing
        )
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: selectedColorMode) { oldValue, newValue in
            if colorMode != newValue.rawValue {
                colorMode = newValue.rawValue
            }
        }
        .onChange(of: selectedQuality) { oldValue, newValue in
            if compressionQuality != newValue.rawValue {
                compressionQuality = newValue.rawValue
            }
        }
        .alert("Neustart erforderlich", isPresented: $showingRestartAlert) {
            Button("Später") {
                // Der Benutzer möchte später neustarten
            }
            Button("Jetzt neustarten") {
                // Erst Settings schließen
                onDismiss()
                
                // Kurze Verzögerung für sauberes Schließen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Starte die App neu
                    let url = Bundle.main.bundleURL
                    let configuration = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.openApplication(at: url,
                                                     configuration: configuration) { _, _ in
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        } message: {
            Text(LocalizedStringKey("Bitte starten Sie die App neu, damit die Sprachänderungen wirksam werden."))
        }
    }
}

// Verbesserte TabButton-Struktur
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {  // Vertikales Layout
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.system(size: 20))  // Größeres Icon
                Text(title)
                    .font(.caption)  // Kleinerer Text
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(width: 70, height: 50)  // Feste Größe für konsistentes Layout
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
} 