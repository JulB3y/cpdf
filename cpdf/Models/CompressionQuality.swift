import CoreGraphics
import SwiftUI  // Für LocalizedStringKey

enum CompressionQuality: String, CaseIterable {
    case high = "high"
    case superLight = "superLight"
    case light = "light"
    case medium = "medium"
    case low = "low"
    
    var resolution: Int {
        switch self {
        case .high:
            return 2400  // Original-ähnliche Qualität
        case .superLight:
            return 1440  // 1440p
        case .light:
            return 1080  // 1080p
        case .medium:
            return 720   // 720p
        case .low:
            return 480   // 480p
        }
    }
    
    var compressionFactor: Float {
        switch self {
        case .high:
            return 1.0
        case .superLight:
            return 0.9
        case .light:
            return 0.8
        case .medium:
            return 0.6
        case .low:
            return 0.4
        }
    }
    
    var interpolationQuality: CGInterpolationQuality {
        switch self {
        case .high, .superLight, .light:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .high:
            return "Keine Kompression"
        case .superLight:
            return "Minimal (1440p)"
        case .light:
            return "Leicht (1080p)"
        case .medium:
            return "Mittel (720p)"
        case .low:
            return "Stark (480p)"
        }
    }
    
    var imageCompressionFactor: Float {
        switch self {
        case .high:
            return 1.0    // Keine Komprimierung
        case .superLight:
            return 0.90   // Minimale Komprimierung (90% Qualität)
        case .light:
            return 0.85   // Leichte Komprimierung (85% Qualität)
        case .medium:
            return 0.65   // Mittlere Komprimierung (65% Qualität)
        case .low:
            return 0.45   // Starke Komprimierung (45% Qualität)
        }
    }
    
    var pdfOptimizations: [String: Bool] {
        switch self {
        case .high:
            return [:]
        case .superLight:
            return [
                "compress_streams": true,
                "merge_duplicate_streams": true,
                "optimize_images": true
            ]
        case .light:
            return [
                "compress_streams": true,
                "merge_duplicate_streams": true,
                "optimize_images": true,
                "use_pngout": true
            ]
        case .medium, .low:
            return [
                "compress_streams": true,
                "merge_duplicate_streams": true,
                "optimize_images": true,
                "use_pngout": true,
                "use_jbig2": true
            ]
        }
    }
    
    var explanationText: String {
        switch self {
        case .high:
            return String(localized: "Optimiert die PDF ohne sichtbare Qualitätsverluste. Ideal für Dokumente mit hohen Qualitätsanforderungen.")
        case .superLight:
            return String(localized: "Minimale Komprimierung mit kaum wahrnehmbaren Qualitätseinbußen. Perfekt für hochwertige Präsentationen und Dokumente mit vielen Bildern.")
        case .light:
            return String(localized: "Leichte Komprimierung mit minimalen Qualitätseinbußen. Ideal für Präsentationen und Dokumente mit Bildern.")
        case .medium:
            return String(localized: "Ausgewogene Komprimierung mit gutem Verhältnis zwischen Qualität und Dateigröße.")
        case .low:
            return String(localized: "Maximale Komprimierung mit sichtbaren Qualitätseinbußen. Geeignet wenn Dateigröße wichtiger ist als Qualität.")
        }
    }
} 