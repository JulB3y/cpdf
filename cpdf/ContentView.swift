//
//  ContentView.swift
//  cpdf
//
//  Created by JulB3y on 14.01.25.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ContentView: View {
    @EnvironmentObject private var pdfCompressor: PDFCompressor
    @State private var isDropTargeted = false
    @State private var draggedFiles: [URL] = []
    
    var body: some View {
        ZStack {
            // Hintergrund-Layer, der die gesamte Fläche abdeckt
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .animation(.easeInOut, value: isDropTargeted)
                .ignoresSafeArea()  // Erweitert den Hintergrund bis zum Fensterrand
            
            if let result = pdfCompressor.compressionResult {
                CompressedPDFView(
                    originalSize: result.originalSize,
                    compressedSize: result.compressedSize,
                    originalName: result.fileName
                )
            } else if pdfCompressor.isCompressing, let fileName = pdfCompressor.currentFileName {
                CompressingPDFView(fileName: fileName)
            } else if let fileName = pdfCompressor.noReductionFile {
                NoReductionView(fileName: fileName)
            } else {
                // Content-Layer
                VStack(spacing: 16) {
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 48))
                        .foregroundColor(isDropTargeted ? .blue : .gray)
                    
                    Text(LocalizedStringKey("PDF hier reinziehen"))
                        .font(.headline)
                    
                    Text(LocalizedStringKey("oder"))
                    
                    Button(LocalizedStringKey("PDF auswählen")) {
                        selectPDF()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if !draggedFiles.isEmpty {
                        Text(LocalizedStringKey("\(draggedFiles.count) PDF(s) in Bearbeitung"))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func selectPDF() {
        let dialog = NSOpenPanel()
        dialog.title = "Bitte wählen Sie den Ordner aus, um Schreibzugriff zu gewähren"
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.canChooseFiles = true
        dialog.allowedContentTypes = [.pdf]
        dialog.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        dialog.prompt = "Zugriff gewähren"
        
        if dialog.runModal() == .OK {
            if let url = dialog.url {
                // Sichern Sie die Berechtigung für den übergeordneten Ordner
                let parentDirectory = url.deletingLastPathComponent()
                let scope = parentDirectory.startAccessingSecurityScopedResource()
                defer {
                    if scope {
                        parentDirectory.stopAccessingSecurityScopedResource()
                    }
                }
                
                Task {
                    do {
                        try await pdfCompressor.compress(pdfAt: url)
                    } catch {
                        print("❌ Fehler beim Komprimieren: \(error)")
                    }
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard error == nil,
                      let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "pdf" else {
                    return
                }
                
                Task { @MainActor in
                    do {
                        try await pdfCompressor.compress(pdfAt: url)
                    } catch {
                        print("❌ Fehler beim Drop-Komprimieren: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PDFCompressor())
}
