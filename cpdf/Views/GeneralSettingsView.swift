import SwiftUI

struct GeneralSettingsView: View {
    @Binding var selectedLanguage: Language
    @Binding var selectedColorMode: ColorMode
    @Binding var selectedQuality: CompressionQuality
    @Binding var showingRestartAlert: Bool
    @Binding var appLanguage: String
    
    var body: some View {
        Form {
            Section("Sprache") {
                Picker("Sprache", selection: $selectedLanguage) {
                    ForEach(Language.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: selectedLanguage) { _, _ in
                    showingRestartAlert = true
                }
            }
            
            Section("Darstellung") {
                Picker("Farbmodus", selection: $selectedColorMode) {
                    ForEach(ColorMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
            
            Section("PDF Komprimierung") {
                Picker("Qualität", selection: $selectedQuality) {
                    ForEach(CompressionQuality.allCases, id: \.rawValue) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
            }
            
            Text(explanationText)
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding()
    }
    
    private var explanationText: String {
        selectedQuality.explanationText
    }
} 