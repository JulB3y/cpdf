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
    @Published var noReductionFile: String?
    @Published var currentFileName: String?
    
    var lastOriginalURL: URL?
    var lastCompressedURL: URL?
    
    private var pendingCompression: (url: URL, size: Int)?
    
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
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                Task {
                    do {
                        try await self?.compress(pdfAt: url)
                    } catch {
                        print("❌ Fehler beim Komprimieren: \(error)")
                    }
                }
            }
        }
    }
    
    func compress(pdfAt url: URL) async throws {
        self.lastOriginalURL = url
        self.currentFileName = url.lastPathComponent
        let parentDirectory = url.deletingLastPathComponent()
        
        if BookmarkManager.shared.requestFolderAccess(for: parentDirectory) {
            await MainActor.run {
                self.isCompressing = true
                self.compressionResult = nil
                self.noReductionFile = nil
            }
            
            if let originalSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                pendingCompression = (url: url, size: originalSize)
            }
        }
    }
    
    func finishCompression() async throws {
        guard let pending = pendingCompression else { return }
        
        do {
            // 1. Technische Optimierung durch PDFOptimizer
            let optimizedURL: URL
            do {
                optimizedURL = try await PDFOptimizer.shared.optimizePDF(at: pending.url)
            } catch let optimizerError as NSError where optimizerError.domain == "PDFOptimizer" && optimizerError.code == 2 {
                // Wenn keine Größenreduzierung möglich war, nutze Original für visuelle Komprimierung
                print("ℹ️ PDFOptimizer: Keine Größenreduzierung möglich, fahre mit visueller Komprimierung fort")
                optimizedURL = pending.url
            } catch {
                // Bei anderen Fehlern auch mit Original fortfahren
                print("⚠️ PDFOptimizer fehlgeschlagen, fahre mit visueller Komprimierung fort: \(error)")
                optimizedURL = pending.url
            }
            
            // 2. Visuelle Komprimierung basierend auf Qualitätseinstellung
            let qualityMode = UserDefaults.standard.compressionQuality
            let finalURL = try await applyVisualCompression(to: optimizedURL, quality: qualityMode)
            
            // Größenvergleich mit Original
            let originalSize = pending.size
            let finalSize = try finalURL.resourceValues(forKeys: [URLResourceKey.fileSizeKey]).fileSize ?? 0
            
            if finalSize < originalSize {
                // Ersetze Original mit komprimierter Version
                try moveToTrash(pending.url)
                try FileManager.default.moveItem(at: finalURL, to: pending.url)
                
                // Cleanup der Zwischenversion nur wenn sie nicht das Original war
                if optimizedURL != pending.url {
                    try? FileManager.default.removeItem(at: optimizedURL)
                }
                
                await MainActor.run {
                    self.compressionResult = (
                        originalSize: Int64(originalSize),
                        compressedSize: Int64(finalSize),
                        fileName: pending.url.lastPathComponent
                    )
                    self.noReductionFile = nil
                    self.isCompressing = false
                    self.currentFileName = nil
                }
            } else {
                // Cleanup der temporären Dateien
                try? FileManager.default.removeItem(at: finalURL)
                if optimizedURL != pending.url {
                    try? FileManager.default.removeItem(at: optimizedURL)
                }
                
                await MainActor.run {
                    self.compressionResult = nil
                    self.noReductionFile = pending.url.lastPathComponent
                    self.isCompressing = false
                    self.currentFileName = nil
                }
                
                throw NSError(
                    domain: "PDFCompressor",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Keine Größenreduzierung möglich"]
                )
            }
        } catch {
            // Cleanup bei Fehlern
            print("❌ Fehler bei der Komprimierung: \(error)")
            self.compressionResult = nil
            self.noReductionFile = nil
            self.isCompressing = false
            self.currentFileName = nil
            self.showNotification("Fehler beim Komprimieren: \(error.localizedDescription)")
            throw error
        }
        
        self.pendingCompression = nil
    }
    
    private func applyVisualCompression(to url: URL, quality: CompressionQuality) async throws -> URL {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw NSError(domain: "PDFCompressor", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "PDF konnte nicht geladen werden"])
        }
        
        let tempURL = url.deletingLastPathComponent()
            .appendingPathComponent("visual_" + url.lastPathComponent)
        
        let outputPDFDocument = PDFDocument()
        let colorMode = UserDefaults.standard.colorMode
        
        // Verarbeite jede Seite einzeln und gib der UI Zeit zum Atmen
        for pageIndex in 0..<pdfDocument.pageCount {
            // Gib dem Hauptthread Zeit zum Aktualisieren
            if pageIndex % 2 == 0 {  // Nach jeder zweiten Seite
                try await Task.sleep(nanoseconds: 1_000_000)  // 1ms Pause
            }
            
            try await withCheckedThrowingContinuation { continuation in
                autoreleasepool {
                    do {
                        guard let page = pdfDocument.page(at: pageIndex) else {
                            continuation.resume()
                            return
                        }
                        
                        let mediaBox = page.bounds(for: .mediaBox)
                        let cropBox = page.bounds(for: .cropBox)
                        let effectiveBox = cropBox.isEmpty ? mediaBox : cropBox
                        
                        // Berechne die Skalierung
                        let scale: CGFloat
                        if quality == .high {
                            scale = 1.0
                        } else {
                            let isPortrait = effectiveBox.height > effectiveBox.width
                            let targetDimension = CGFloat(quality.resolution)
                            
                            if isPortrait {
                                scale = targetDimension / effectiveBox.height
                            } else {
                                scale = targetDimension / effectiveBox.width
                            }
                        }
                        
                        let padding: CGFloat = 2.0
                        let finalWidth = Int(ceil(effectiveBox.width * scale + 2 * padding))
                        let finalHeight = Int(ceil(effectiveBox.height * scale + 2 * padding))
                        
                        guard let bitmapRep = NSBitmapImageRep(
                            bitmapDataPlanes: nil,
                            pixelsWide: finalWidth,
                            pixelsHigh: finalHeight,
                            bitsPerSample: 8,
                            samplesPerPixel: colorMode == .fullColor ? 4 : 1,
                            hasAlpha: colorMode == .fullColor,
                            isPlanar: false,
                            colorSpaceName: colorMode == .fullColor ? .deviceRGB : .calibratedWhite,
                            bitmapFormat: colorMode == .fullColor ? .alphaFirst : [],
                            bytesPerRow: 0,
                            bitsPerPixel: colorMode == .fullColor ? 32 : 8
                        ) else {
                            continuation.resume()
                            return
                        }
                        
                        Task { @MainActor in
                            NSGraphicsContext.saveGraphicsState()
                            if let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapRep) {
                                graphicsContext.shouldAntialias = true
                                graphicsContext.imageInterpolation = .high
                                NSGraphicsContext.current = graphicsContext
                                
                                let cgContext = graphicsContext.cgContext
                                
                                // Weißer Hintergrund
                                NSColor.white.setFill()
                                NSRect(x: 0, y: 0, width: finalWidth, height: finalHeight).fill()
                                
                                // Korrekte Transformation
                                cgContext.translateBy(x: padding, y: padding)
                                cgContext.scaleBy(x: scale, y: scale)
                                cgContext.translateBy(x: -effectiveBox.origin.x, y: -effectiveBox.origin.y)
                                
                                // Zeichne die PDF-Seite
                                page.draw(with: .cropBox, to: cgContext)
                            }
                            NSGraphicsContext.restoreGraphicsState()
                            
                            // Komprimiere und füge die Seite hinzu
                            if let compressedData = bitmapRep.representation(
                                using: .jpeg,
                                properties: [
                                    .compressionFactor: quality.compressionFactor,
                                    .progressive: true
                                ]
                            ),
                            let compressedImage = NSImage(data: compressedData) {
                                compressedImage.size = effectiveBox.size
                                
                                if let newPage = PDFPage(image: compressedImage) {
                                    newPage.setBounds(mediaBox, for: .mediaBox)
                                    if !cropBox.isEmpty {
                                        newPage.setBounds(cropBox, for: .cropBox)
                                    }
                                    outputPDFDocument.insert(newPage, at: pageIndex)
                                }
                            }
                            
                            continuation.resume()
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        outputPDFDocument.write(to: tempURL)
        return tempURL
    }
    
    func reset() {
        compressionResult = nil
        noReductionFile = nil
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
    
    private func moveToTrash(_ url: URL) throws {
        var resultingItemUrl: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingItemUrl)
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
