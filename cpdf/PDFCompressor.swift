import Foundation
import SwiftUI
import Quartz
import UniformTypeIdentifiers
import UserNotifications
import CoreGraphics
import AppKit
import PDFKit

@MainActor
class PDFCompressor: ObservableObject {
    @Published var isCompressing = false
    @Published var compressionResult: (originalSize: Int64, compressedSize: Int64, fileName: String)?
    
    // Neue Properties für die URLs
    var lastOriginalURL: URL?
    var lastCompressedURL: URL?
    
    func compressPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.message = "Wählen Sie eine PDF zum Komprimieren"
        panel.prompt = "PDF auswählen"
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsOtherFileTypes = false
        panel.treatsFilePackagesAsDirectories = false
        panel.showsHiddenFiles = false
        
        // Erlaubt Zugriff auf iCloud Drive und andere Ordner
        panel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    await self.compress(pdfAt: url)
                }
            }
        }
    }
    
    func compress(pdfAt url: URL) async {
        guard let pdfDocument = PDFDocument(url: url) else {
            print("❌ Fehler: Konnte PDF nicht laden")
            return
        }
        
        print("📄 Originale PDF geladen: \(url.lastPathComponent)")
        
        let parentDirectory = url.deletingLastPathComponent()
        
        // Frage nach Zugriffsberechtigung
        if BookmarkManager.shared.requestFolderAccess(for: parentDirectory) {
            self.isCompressing = true
            
            do {
                try await processCompression(pdfDocument: pdfDocument, originalURL: url, parentDirectory: parentDirectory)
            } catch {
                print("❌ Fehler bei der Komprimierung: \(error)")
                self.showNotification("Fehler beim Komprimieren: \(error.localizedDescription)")
            }
        } else {
            print("❌ Keine Schreibberechtigung erhalten für: \(parentDirectory.path)")
            self.showNotification("Keine Schreibberechtigung für den Ordner erhalten")
        }
    }
    
    private func processCompression(pdfDocument: PDFDocument, originalURL: URL, parentDirectory: URL) async throws {
        let originalFileName = originalURL.lastPathComponent
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_\(originalFileName)")
        
        print("🔄 Starte Komprimierung...")
        
        defer {
            self.isCompressing = false
            // Lösche temporäre Datei falls vorhanden
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        
        do {
            // Erstelle ein neues PDF-Dokument für die Ausgabe
            let outputPDFDocument = PDFDocument()
            
            // Setze PDF-Metadaten
            let metadata: [AnyHashable: Any] = [
                kCGPDFContextCreator: "PDF Kompressor",
                kCGPDFContextAuthor: NSUserName(),
                kCGPDFContextTitle: originalFileName
            ]
            
            // Hole die Qualitätseinstellung aus UserDefaults
            let compressionQuality = UserDefaults.standard.double(forKey: "compressionQuality")
            
            // Komprimiere jede Seite einzeln
            for pageIndex in 0..<pdfDocument.pageCount {
                autoreleasepool {
                    guard let page = pdfDocument.page(at: pageIndex) else { return }
                    
                    // Erstelle ein Bild aus der PDF-Seite
                    let pageRect = page.bounds(for: .mediaBox)
                    
                    // Berechne die Auflösung basierend auf der Qualitätseinstellung
                    let resolutionScale = 1.0 + (compressionQuality * 1.0) // Skala von 1.0 bis 2.0
                    
                    // Erstelle einen Bitmap-Kontext mit optimierten Einstellungen
                    guard let bitmapRep = NSBitmapImageRep(
                        bitmapDataPlanes: nil,
                        pixelsWide: Int(pageRect.width * resolutionScale),
                        pixelsHigh: Int(pageRect.height * resolutionScale),
                        bitsPerSample: 8,
                        samplesPerPixel: 1,
                        hasAlpha: false,
                        isPlanar: false,
                        colorSpaceName: .calibratedWhite,
                        bitmapFormat: NSBitmapImageRep.Format(),
                        bytesPerRow: 0,
                        bitsPerPixel: 8
                    ) else { return }
                    
                    NSGraphicsContext.saveGraphicsState()
                    if let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapRep) {
                        graphicsContext.shouldAntialias = true
                        graphicsContext.imageInterpolation = .high
                        NSGraphicsContext.current = graphicsContext
                        
                        // Skaliere den Kontext entsprechend der Auflösung
                        graphicsContext.cgContext.scaleBy(x: resolutionScale, y: resolutionScale)
                        
                        // Weiß als Hintergrund
                        NSColor.white.setFill()
                        NSRect(origin: .zero, size: pageRect.size).fill()
                        
                        // Zeichne die PDF-Seite
                        page.draw(with: .mediaBox, to: graphicsContext.cgContext)
                    }
                    NSGraphicsContext.restoreGraphicsState()
                    
                    // Erstelle eine neue PDF-Seite aus dem komprimierten Bild
                    if let compressedData = bitmapRep.representation(
                        using: .jpeg,
                        properties: [
                            .compressionFactor: compressionQuality,
                            .progressive: true
                        ]
                    ),
                    let compressedImage = NSImage(data: compressedData) {
                        // Wichtig: Setze die Größe auf die originale Seitengröße
                        compressedImage.size = pageRect.size
                        if let newPage = PDFPage(image: compressedImage) {
                            // Setze die MediaBox auf die originale Größe
                            newPage.setBounds(pageRect, for: .mediaBox)
                            outputPDFDocument.insert(newPage, at: pageIndex)
                        }
                    }
                }
            }
            
            // Speichere die komprimierte PDF mit Metadaten
            let pdfData = NSMutableData()
            if let consumer = CGDataConsumer(data: pdfData),
               let context = CGContext(consumer: consumer, mediaBox: nil, metadata as CFDictionary) {
                
                for pageIndex in 0..<outputPDFDocument.pageCount {
                    if let page = outputPDFDocument.page(at: pageIndex) {
                        let pageRect = page.bounds(for: .mediaBox)
                        var mediaBoxRect = CGRect(x: pageRect.origin.x,
                                                y: pageRect.origin.y,
                                                width: pageRect.width,
                                                height: pageRect.height)
                        context.beginPage(mediaBox: &mediaBoxRect)
                        page.draw(with: .mediaBox, to: context)
                        context.endPage()
                    }
                }
                context.closePDF()
                
                // Speichere zunächst in temporäre Datei
                try (pdfData as Data).write(to: tempFileURL)
            } else {
                throw NSError(domain: "PDFCompressor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Konnte PDF nicht speichern"])
            }
            
            // Überprüfe die Größen
            let originalSize = try FileManager.default.attributesOfItem(atPath: originalURL.path)[.size] as? Int64 ?? 0
            let compressedSize = try FileManager.default.attributesOfItem(atPath: tempFileURL.path)[.size] as? Int64 ?? 0
            let savings = Double(originalSize - compressedSize) / Double(originalSize) * 100
            
            if savings > 0 {
                do {
                    // Verschiebe Original in den Papierkorb
                    try FileManager.default.trashItem(at: originalURL, resultingItemURL: nil)
                    print("🗑️ Original in den Papierkorb verschoben")
                    
                    // Verschiebe komprimierte Version an den ursprünglichen Speicherort
                    try FileManager.default.moveItem(at: tempFileURL, to: originalURL)
                    
                    self.showNotification("PDF wurde komprimiert (Einsparung: \(String(format: "%.1f", savings))%)")
                    self.compressionResult = (originalSize, compressedSize, originalFileName)
                    self.lastOriginalURL = originalURL
                    self.lastCompressedURL = originalURL
                } catch {
                    // Wenn etwas schief geht, versuche das Original wiederherzustellen
                    print("❌ Fehler beim Ersetzen der Datei: \(error)")
                    throw error
                }
            } else {
                throw NSError(domain: "PDFCompressor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Keine Größenreduzierung möglich"])
            }
            
        } catch {
            throw error
        }
    }
    
    private func showNotification(_ message: String) {
        let content = UNMutableNotificationContent()
        content.title = "PDF Kompressor"
        content.body = message
        
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                          content: content,
                                          trigger: nil)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// Hilfserweiterung für URL
extension URL {
    func accessSecurityScopedResource(completion: @escaping (Bool) -> Void) {
        // Starte Security-Scoped Access
        let accessGranted = self.startAccessingSecurityScopedResource()
        
        if !accessGranted {
            // Wenn kein Zugriff, frage nach Berechtigung über NSOpenPanel
            let openPanel = NSOpenPanel()
            openPanel.message = "Bitte wählen Sie den Ordner erneut aus, um Schreibzugriff zu gewähren"
            openPanel.prompt = "Ordner auswählen"
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.directoryURL = self.deletingLastPathComponent()
            
            openPanel.begin { response in
                if response == .OK, let selectedURL = openPanel.url {
                    // Erstelle ein Bookmark für zukünftigen Zugriff
                    do {
                        let bookmarkData = try selectedURL.bookmarkData(
                            options: .withSecurityScope,
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        // Speichere das Bookmark für späteren Zugriff
                        UserDefaults.standard.set(bookmarkData, forKey: "PDFDirectoryBookmark")
                        
                        completion(true)
                    } catch {
                        print("❌ Fehler beim Erstellen des Bookmarks: \(error)")
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        } else {
            completion(true)
        }
    }
} 
