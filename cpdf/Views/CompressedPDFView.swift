import SwiftUI
import PDFKit
import QuickLook

struct CompressedPDFView: View {
    @EnvironmentObject private var pdfCompressor: PDFCompressor
    let originalSize: Int64
    let compressedSize: Int64
    let originalName: String
    @State private var originalPreview: NSImage?
    @State private var compressedPreview: NSImage?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("PDF Komprimierung")
                .font(.title)
                .foregroundColor(.primary)
            
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
                        Text("reduziert um")
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
            
            Button("Neue PDF komprimieren") {
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
                let thumbnail = NSImage(size: pageRect.size)
                
                thumbnail.lockFocus()
                
                if let context = NSGraphicsContext.current {
                    // Weißer Hintergrund
                    NSColor.white.set()
                    NSBezierPath(rect: NSRect(origin: .zero, size: pageRect.size)).fill()
                    
                    // PDF-Seite zeichnen mit dem CGContext
                    pdfPage.draw(with: .mediaBox, to: context.cgContext)
                    thumbnail.unlockFocus()
                    
                    // Skaliere das Thumbnail auf eine vernünftige Größe
                    let scaledThumbnail = NSImage(size: NSSize(width: 200, height: 200))
                    scaledThumbnail.lockFocus()
                    thumbnail.draw(in: NSRect(origin: .zero, size: scaledThumbnail.size),
                                 from: NSRect(origin: .zero, size: thumbnail.size),
                                 operation: .copy,
                                 fraction: 1.0)
                    scaledThumbnail.unlockFocus()
                    
                    continuation.resume(returning: scaledThumbnail)
                } else {
                    thumbnail.unlockFocus()
                    continuation.resume(returning: fallbackImage)
                }
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