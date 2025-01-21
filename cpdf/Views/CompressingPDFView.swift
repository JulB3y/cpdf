import SwiftUI
import PDFKit

struct CompressingPDFView: View {
    @EnvironmentObject private var pdfCompressor: PDFCompressor
    let fileName: String
    @State private var thumbnail: NSImage?
    @State private var dotCount = 0
    
    // Timer für die Punkteanimation
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
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
                Text("Komprimiere\(String(repeating: ".", count: dotCount))")
                    .font(.headline)
                    .onReceive(timer) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                
                Text(fileName)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadThumbnail()
            startCompression()
        }
        .onDisappear {
            // Stoppe den Timer beim Verlassen der View
            timer.upstream.connect().cancel()
        }
    }
    
    private func startCompression() {
        Task(priority: .userInitiated) {
            do {
                // Führe die Komprimierung im Hintergrund durch
                try await pdfCompressor.finishCompression()
            } catch {
                print("❌ Fehler bei der Komprimierung: \(error)")
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
        
        Task(priority: .userInitiated) {
            guard let document = PDFDocument(url: url),
                  let pdfPage = document.page(at: 0) else { return }
            
            let thumbnail = await createThumbnail(from: pdfPage)
            await MainActor.run {
                self.thumbnail = thumbnail
            }
        }
    }
    
    private func createThumbnail(from pdfPage: PDFPage) async -> NSImage? {
        await MainActor.run {
            let pageRect = pdfPage.bounds(for: .mediaBox)
            
            let aspectRatio = pageRect.width / pageRect.height
            let maxHeight: CGFloat = 280
            let maxWidth: CGFloat = 200
            
            let thumbnailSize: NSSize
            if aspectRatio > 1 {
                thumbnailSize = NSSize(width: maxWidth, height: maxWidth / aspectRatio)
            } else {
                thumbnailSize = NSSize(width: maxHeight * aspectRatio, height: maxHeight)
            }
            
            return autoreleasepool { () -> NSImage? in
                let thumbnail = NSImage(size: thumbnailSize)
                
                thumbnail.lockFocus()
                defer { thumbnail.unlockFocus() }
                
                guard let context = NSGraphicsContext.current else { return nil }
                
                NSColor.white.setFill()
                NSBezierPath(rect: NSRect(origin: .zero, size: thumbnailSize)).fill()
                
                context.imageInterpolation = .high
                context.shouldAntialias = true
                
                let scale = min(thumbnailSize.width / pageRect.width,
                              thumbnailSize.height / pageRect.height)
                
                context.saveGraphicsState()
                context.cgContext.scaleBy(x: scale, y: scale)
                
                if let page = pdfPage.pageRef {
                    context.cgContext.drawPDFPage(page)
                }
                
                context.restoreGraphicsState()
                
                return thumbnail
            }
        }
    }
}

#Preview {
    CompressingPDFView(fileName: "test.pdf")
        .environmentObject(PDFCompressor())
} 