import SwiftUI

struct InfoSettingsView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text(LocalizedStringKey("Version"))
                    Spacer()
                    Text("\(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Link(LocalizedStringKey("GitHub Repository"), destination: URL(string: "https://github.com/JulB3y/cpdf")!)
                Link(LocalizedStringKey("Fehler melden"), destination: URL(string: "https://github.com/JulB3y/cpdf/issues")!)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
} 