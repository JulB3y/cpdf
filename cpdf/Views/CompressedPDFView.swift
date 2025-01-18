import SwiftUI
import PDFKit
import QuickLook

struct CompressedPDFView: View {
    @EnvironmentObject private var pdfCompressor: PDFCompressor
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow
    
    let originalSize: Int64
    let compressedSize: Int64
    let originalName: String
    @State private var originalPreview: NSImage?
    @State private var compressedPreview: NSImage?
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(LocalizedStringKey("PDF Komprimierung"))
                    .font(.title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Einstellungen-Button
                Button {
                    appDelegate.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 40) {
                // Original PDF
                VStack {
                    if let preview = originalPreview {
                        Image(nsImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray)
                            )
                    } else {
                        Image(systemName: "doc.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    Text(ByteCountFormatter.string(fromByteCount: originalSize, countStyle: .file))
                        .font(.headline)
                }
                
                // Pfeil und Komprimierungsrate
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 2) {
                        Text(LocalizedStringKey("reduziert um"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f%%", savings))
                            .font(.headline)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                
                // Komprimierte PDF
                VStack {
                    if let preview = compressedPreview {
                        Image(nsImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray)
                            )
                    } else {
                        Image(systemName: "doc.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    Text(ByteCountFormatter.string(fromByteCount: compressedSize, countStyle: .file))
                        .font(.headline)
                }
            }
            .padding()
            
            Button(LocalizedStringKey("Neue PDF komprimieren")) {
                pdfCompressor.compressionResult = nil
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 500, height: 400)
        .task {
            // Lade Vorschauen
            if let originalURL = pdfCompressor.lastOriginalURL {
                originalPreview = await generatePDFThumbnail(for: originalURL)
            }
            if let compressedURL = pdfCompressor.lastCompressedURL {
                compressedPreview = await generatePDFThumbnail(for: compressedURL)
            }
        }
    }
    
    // Berechnung der Einsparung in Prozent
    private var savings: Double {
        Double(originalSize - compressedSize) / Double(originalSize) * 100
    }
    
    private func generatePDFThumbnail(for url: URL) async -> NSImage {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Erstelle ein Fallback-Bild für den Fehlerfall
                let fallbackImage = NSImage(size: NSSize(width: 100, height: 100))
                fallbackImage.lockFocus()
                NSColor.systemRed.set()
                NSBezierPath(rect: NSRect(origin: .zero, size: fallbackImage.size)).fill()
                fallbackImage.unlockFocus()
                
                // Versuche die PDF zu laden
                guard let pdfDocument = PDFDocument(url: url),
                      let pdfPage = pdfDocument.page(at: 0) else {
                    continuation.resume(returning: fallbackImage)
                    return
                }
                
                let pageRect = pdfPage.bounds(for: .mediaBox)
                
                // Berechne das Seitenverhältnis und die Thumbnail-Größe
                let aspectRatio = pageRect.width / pageRect.height
                let thumbnailHeight: CGFloat = 100
                let thumbnailWidth = thumbnailHeight * aspectRatio
                let thumbnailSize = NSSize(width: thumbnailWidth, height: thumbnailHeight)
                
                // Erstelle das Thumbnail
                let thumbnail = NSImage(size: thumbnailSize)
                thumbnail.lockFocus()
                
                if let context = NSGraphicsContext.current {
                    // Setze Qualitätseinstellungen
                    context.imageInterpolation = .high
                    context.shouldAntialias = true
                    
                    // Weißer Hintergrund
                    NSColor.white.setFill()
                    NSRect(origin: .zero, size: thumbnailSize).fill()
                    
                    // Berechne die Skalierung
                    let scale = thumbnailHeight / pageRect.height
                    context.cgContext.scaleBy(x: scale, y: scale)
                    
                    // Zeichne die PDF-Seite
                    pdfPage.draw(with: .mediaBox, to: context.cgContext)
                }
                
                thumbnail.unlockFocus()
                continuation.resume(returning: thumbnail)
            }
        }
    }
}

#Preview {
    CompressedPDFView(
        originalSize: 10_000_000,
        compressedSize: 1_000_000,
        originalName: "Dokument.pdf"
    )
} 