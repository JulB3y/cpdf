import Foundation

extension UserDefaults {
    var compressionQuality: CompressionQuality {
        get {
            if let value = string(forKey: "compressionQuality") {
                return CompressionQuality(rawValue: value) ?? .medium
            }
            return .medium
        }
        set {
            set(newValue.rawValue, forKey: "compressionQuality")
        }
    }
    
    var colorMode: ColorMode {
        get {
            if let value = string(forKey: "colorMode") {
                return ColorMode(rawValue: value) ?? .fullColor
            }
            return .fullColor
        }
        set {
            set(newValue.rawValue, forKey: "colorMode")
        }
    }
} 