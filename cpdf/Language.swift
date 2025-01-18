import Foundation

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