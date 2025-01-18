import Foundation

enum CompressionQuality: String, CaseIterable, Identifiable {
    case light = "light"     // 1080p - light compression
    case medium = "medium"   // 720p - medium compression
    case strong = "strong"   // 480p - strong compression
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .light: return String(localized: "Light (1080p)")
        case .medium: return String(localized: "Medium (720p)")
        case .strong: return String(localized: "Strong (480p)")
        }
    }
    
    var resolution: Int {
        switch self {
        case .light: return 1080   // 1080p
        case .medium: return 720    // 720p
        case .strong: return 480     // 480p
        }
    }
    
    var compressionFactor: Double {
        switch self {
        case .light: return 0.8
        case .medium: return 0.6
        case .strong: return 0.4
        }
    }
}