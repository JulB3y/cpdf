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