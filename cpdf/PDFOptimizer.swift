import Foundation
import PDFKit
import CoreGraphics
import AppKit  // Für die PDF-Konstanten
import Quartz
import QuartzCore

class PDFOptimizer {
    // Singleton für gemeinsame Nutzung
    static let shared = PDFOptimizer()
    
    private init() {}
    
    func optimizePDF(at url: URL) async throws -> URL {
        // Temporäre URL für die optimierte Version
        let optimizedURL = url.deletingLastPathComponent()
            .appendingPathComponent("optimized_" + url.lastPathComponent)
        
        do {
            // 1. PDF laden und analysieren
            guard let document = CGPDFDocument(url as CFURL) else {
                throw NSError(domain: "PDFOptimizer", code: 1, 
                    userInfo: [NSLocalizedDescriptionKey: "PDF konnte nicht geladen werden"])
            }
            
            // 2. Maximale verlustfreie Komprimierung
            let compressionSettings: [String: Any] = [
                "AllowsPrinting": true,
                "AllowsCopying": true,
                "CompressPages": true,
                "ImageCompression": "lossless",  // Nur verlustfreie Komprimierung
                "PreserveMetadata": false // Entferne unnötige Metadaten
            ]
            
            // 3. Neues PDF-Dokument erstellen
            guard let context = CGContext(optimizedURL as CFURL,
                                        mediaBox: nil,
                                        compressionSettings as CFDictionary) else {
                throw NSError(domain: "PDFOptimizer", code: 3,
                            userInfo: [NSLocalizedDescriptionKey: "Konnte PDF-Kontext nicht erstellen"])
            }
            
            // 4. Seiten optimieren und kopieren
            for i in 1...document.numberOfPages {
                guard let page = document.page(at: i) else { continue }
                
                // Seitenbox und Transformation
                var mediaBox = page.getBoxRect(.mediaBox)
                context.beginPage(mediaBox: &mediaBox)
                
                // Bilder optimieren
                try optimizeImages(on: page)
                
                // Seite zeichnen
                context.drawPDFPage(page)
                context.endPage()
            }
            
            // 5. Dokument finalisieren
            context.closePDF()
            
            // 6. Größenvergleich
            let originalSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            let optimizedSize = try optimizedURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            
            // Wenn die optimierte Version nicht kleiner ist, Original behalten
            if optimizedSize >= originalSize {
                try? FileManager.default.removeItem(at: optimizedURL)
                throw NSError(domain: "PDFOptimizer", code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Keine Größenreduzierung möglich"])
            }
            
            return optimizedURL
            
        } catch {
            // Cleanup bei Fehler
            try? FileManager.default.removeItem(at: optimizedURL)
            throw error
        }
    }
    
    private func optimizeImages(on page: CGPDFPage) throws {
        // TODO: Implementiere verlustfreie Bildoptimierung:
        // - JBIG2 für Schwarzweiß-Bilder
        // - Verlustfreie PNG-Optimierung
        // - Entfernung redundanter Bilddaten
        // - Keine Auflösungsreduzierung
    }
    
    public func moveToTrash(_ url: URL) throws {
        var resultingItemUrl: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingItemUrl)
    }
} 