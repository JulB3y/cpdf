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
    
    @State private var thumbnail: NSImage?
    
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
            
            // Compression Info
            VStack(spacing: 12) {
                Text(LocalizedStringKey("PDF Komprimierung"))
                    .font(.headline)
                
                HStack(spacing: 16) {
                    Text("\(formatFileSize(originalSize))")
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    Text("\(formatFileSize(compressedSize))")
                        .foregroundColor(.green)
                }
                
                Text(LocalizedStringKey("reduziert um \(calculateReduction())%"))
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Button(LocalizedStringKey("Neue PDF komprimieren")) {
                pdfCompressor.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        Task {
            if let url = pdfCompressor.lastOriginalURL {
                thumbnail = try? await createThumbnail(from: url)
            }
        }
    }
    
    private func createThumbnail(from url: URL) async throws -> NSImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Erstelle ein Fallback-Bild
                let fallbackImage = NSImage(size: NSSize(width: 200, height: 280))
                fallbackImage.lockFocus()
                NSColor.windowBackgroundColor.setFill()
                NSBezierPath(rect: NSRect(origin: .zero, size: fallbackImage.size)).fill()
                NSColor.systemRed.setFill()
                NSBezierPath(ovalIn: NSRect(x: 50, y: 90, width: 100, height: 100)).fill()
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
                let maxHeight: CGFloat = 280
                let maxWidth: CGFloat = 200
                
                let thumbnailSize: NSSize
                if aspectRatio > 1 {
                    // Breites Dokument
                    thumbnailSize = NSSize(width: maxWidth, height: maxWidth / aspectRatio)
                } else {
                    // Hohes Dokument
                    thumbnailSize = NSSize(width: maxHeight * aspectRatio, height: maxHeight)
                }
                
                // Erstelle das Thumbnail
                let thumbnail = NSImage(size: thumbnailSize)
                thumbnail.lockFocus()
                
                if let context = NSGraphicsContext.current {
                    // Weißer Hintergrund
                    NSColor.white.setFill()
                    NSBezierPath(rect: NSRect(origin: .zero, size: thumbnailSize)).fill()
                    
                    // Qualitätseinstellungen
                    context.imageInterpolation = .high
                    context.shouldAntialias = true
                    
                    // Zeichne die PDF-Seite
                    let scale = min(thumbnailSize.width / pageRect.width,
                                  thumbnailSize.height / pageRect.height)
                    
                    context.cgContext.scaleBy(x: scale, y: scale)
                    pdfPage.draw(with: .mediaBox, to: context.cgContext)
                }
                
                thumbnail.unlockFocus()
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    private func calculateReduction() -> Int {
        guard originalSize > 0 else { return 0 }
        let reduction = Double(originalSize - compressedSize) / Double(originalSize) * 100
        return Int(reduction)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

#Preview {
    CompressedPDFView(
        originalSize: 1_000_000,
        compressedSize: 500_000,
        originalName: "test.pdf"
    )
    .environmentObject(PDFCompressor())
    .environmentObject(AppDelegate())
} 