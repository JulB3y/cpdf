import Foundation

public enum ColorMode: String, CaseIterable, Identifiable {
    case fullColor = "full"
    case grayscale = "gray"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .fullColor: return String(localized: "Voller Farbraum")
        case .grayscale: return String(localized: "Graustufen")
        }
    }
}
