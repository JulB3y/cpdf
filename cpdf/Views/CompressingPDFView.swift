import SwiftUI
import PDFKit

struct CompressingPDFView: View {
    @EnvironmentObject private var pdfCompressor: PDFCompressor
    let fileName: String
    @State private var thumbnail: NSImage?
    @State private var progress: Double = 0
    @State private var compressionFinished = false
    
    var body: some View {
        VStack(spacing: 20) {
            // PDF Preview
            Group {
                if let thumbnail = thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 400)
                        .shadow(radius: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.windowBackgroundColor))
                                .shadow(radius: 2)
                        )
                        .padding()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .frame(width: 200, height: 280)
                            .shadow(radius: 2)
                        
                        ProgressView()
                    }
                    .padding()
                }
            }
            .frame(height: 300)
            
            // Komprimierungsstatus
            VStack(spacing: 12) {
                Text(LocalizedStringKey("PDF wird komprimiert"))
                    .font(.headline)
                
                Text(fileName)
                    .foregroundColor(.secondary)
                
                // Fortschrittsbalken mit animiertem Progress
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadThumbnail()
            startCompression()
        }
    }
    
    private func startCompression() {
        Task { @MainActor in
            do {
                // Starte die Animation
                withAnimation(.easeIn(duration: 0.3)) {
                    progress = 0.3
                }
                
                // Führe die Komprimierung durch
                try await pdfCompressor.finishCompression()
                
                // Wenn wir hier ankommen, war die Komprimierung erfolgreich
                // Zeige schnell den Rest des Fortschritts an
                withAnimation(.easeOut(duration: 0.2)) {
                    progress = 1.0
                }
                
            } catch {
                print("❌ Fehler bei der Komprimierung: \(error)")
                // Stelle sicher, dass der Status korrekt gesetzt wird
                await MainActor.run {
                    pdfCompressor.isCompressing = false
                    if error.localizedDescription.contains("Keine Größenreduzierung möglich") {
                        pdfCompressor.noReductionFile = fileName
                    }
                }
            }
        }
    }
    
    private func loadThumbnail() {
        guard let url = pdfCompressor.lastOriginalURL else { return }
        
        Task { @MainActor in
            // Lade das Dokument
            guard let document = PDFDocument(url: url),
                  let pdfPage = document.page(at: 0) else { return }
            
            // Erstelle das Thumbnail direkt auf dem MainActor
            self.thumbnail = await createThumbnail(from: pdfPage)
        }
    }
    
    @MainActor
    private func createThumbnail(from pdfPage: PDFPage) async -> NSImage? {
        let pageRect = pdfPage.bounds(for: .mediaBox)
        
        // Berechne das Seitenverhältnis und die Thumbnail-Größe
        let aspectRatio = pageRect.width / pageRect.height
        let maxHeight: CGFloat = 280
        let maxWidth: CGFloat = 200
        
        let thumbnailSize: NSSize
        if aspectRatio > 1 {
            thumbnailSize = NSSize(width: maxWidth, height: maxWidth / aspectRatio)
        } else {
            thumbnailSize = NSSize(width: maxHeight * aspectRatio, height: maxHeight)
        }
        
        // Erstelle das Thumbnail direkt auf dem MainActor
        return autoreleasepool { () -> NSImage? in
            let thumbnail = NSImage(size: thumbnailSize)
            
            thumbnail.lockFocus()
            defer { thumbnail.unlockFocus() }
            
            guard let context = NSGraphicsContext.current else { return nil }
            
            // Weißer Hintergrund
            NSColor.white.setFill()
            NSBezierPath(rect: NSRect(origin: .zero, size: thumbnailSize)).fill()
            
            // Qualitätseinstellungen
            context.imageInterpolation = .high
            context.shouldAntialias = true
            
            // Sichere PDF-Zeichnung
            let scale = min(thumbnailSize.width / pageRect.width,
                          thumbnailSize.height / pageRect.height)
            
            context.saveGraphicsState()
            context.cgContext.scaleBy(x: scale, y: scale)
            
            // Verwende drawPage statt draw für bessere Kompatibilität
            if let page = pdfPage.pageRef {
                context.cgContext.drawPDFPage(page)
            }
            
            context.restoreGraphicsState()
            
            return thumbnail
        }
    }
}

#Preview {
    CompressingPDFView(fileName: "test.pdf")
        .environmentObject(PDFCompressor())
} 