import SwiftUI
import Foundation

struct SettingsView: View {
    let onDismiss: () -> Void
    
    // MARK: - Properties
    @AppStorage("appLanguage") private var appLanguage = Language.german.rawValue
    @AppStorage("colorMode") private var colorMode = ColorMode.fullColor.rawValue
    @AppStorage("compressionQuality") private var compressionQuality = CompressionQuality.medium.rawValue
    
    @State private var showingRestartAlert = false
    @State private var selectedTab = "General"
    
    // MARK: - State Properties
    @State private var selectedLanguage: Language
    @State private var selectedColorMode: ColorMode
    @State private var selectedQuality: CompressionQuality
    
    // MARK: - Initialization
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        
        // Initialisiere State Properties
        let defaults = UserDefaults.standard
        let languageValue = defaults.string(forKey: "appLanguage") ?? Language.german.rawValue
        let colorValue = defaults.string(forKey: "colorMode") ?? ColorMode.fullColor.rawValue
        let qualityValue = defaults.string(forKey: "compressionQuality") ?? CompressionQuality.medium.rawValue
        
        _selectedLanguage = State(initialValue: Language(rawValue: languageValue) ?? .german)
        _selectedColorMode = State(initialValue: ColorMode(rawValue: colorValue) ?? .fullColor)
        _selectedQuality = State(initialValue: CompressionQuality(rawValue: qualityValue) ?? .medium)
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            titleBar
            tabBar
            Divider()
            contentView
        }
        .overlay(doneButton, alignment: .bottomTrailing)
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .setupSettingsHandlers(
            colorMode: $colorMode,
            selectedColorMode: $selectedColorMode,
            compressionQuality: $compressionQuality,
            selectedQuality: $selectedQuality
        )
        .alert(isPresented: $showingRestartAlert) {
            restartAlert
        }
    }
}

// MARK: - View Components
private extension SettingsView {
    var titleBar: some View {
        Text("Settings")
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
    }
    
    var tabBar: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "General",
                icon: "gearshape.fill",
                isSelected: selectedTab == "General"
            ) {
                selectedTab = "General"
            }
            
            TabButton(
                title: "Info",
                icon: "info.circle.fill",
                isSelected: selectedTab == "Info"
            ) {
                selectedTab = "Info"
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }
    
    var contentView: some View {
        Group {
            if selectedTab == "General" {
                GeneralSettingsView(
                    selectedLanguage: $selectedLanguage,
                    selectedColorMode: $selectedColorMode,
                    selectedQuality: $selectedQuality,
                    showingRestartAlert: $showingRestartAlert,
                    appLanguage: $appLanguage
                )
            } else {
                InfoSettingsView()
            }
        }
    }
    
    @ViewBuilder
    func tabContent(_ tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            GeneralSettingsView(
                selectedLanguage: $selectedLanguage,
                selectedColorMode: $selectedColorMode,
                selectedQuality: $selectedQuality,
                showingRestartAlert: $showingRestartAlert,
                appLanguage: $appLanguage
            )
        case .info:
            InfoSettingsView()
        }
    }
    
    var doneButton: some View {
        Button(LocalizedStringKey("Done")) {
            onDismiss()
        }
        .keyboardShortcut(.escape, modifiers: [])
        .buttonStyle(.borderedProminent)
        .padding(16)
    }
    
    var restartAlert: Alert {
        Alert(
            title: Text("Neustart erforderlich"),
            message: Text(LocalizedStringKey("Bitte starten Sie die App neu, damit die Sprachänderungen wirksam werden.")),
            primaryButton: .default(Text("Später")),
            secondaryButton: .default(Text("Jetzt neustarten")) {
                handleRestart()
            }
        )
    }
}

// MARK: - Helper Methods
private extension SettingsView {
    func handleRestart() {
        onDismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let url = Bundle.main.bundleURL
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: url,
                                             configuration: configuration) { _, _ in
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

// MARK: - Setup Handlers
extension View {
    func setupSettingsHandlers(
        colorMode: Binding<String>,
        selectedColorMode: Binding<ColorMode>,
        compressionQuality: Binding<String>,
        selectedQuality: Binding<CompressionQuality>
    ) -> some View {
        self.onChange(of: selectedColorMode.wrappedValue) { oldValue, newValue in
            if colorMode.wrappedValue != newValue.rawValue {
                colorMode.wrappedValue = newValue.rawValue
            }
        }
        .onChange(of: selectedQuality.wrappedValue) { oldValue, newValue in
            if compressionQuality.wrappedValue != newValue.rawValue {
                compressionQuality.wrappedValue = newValue.rawValue
            }
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