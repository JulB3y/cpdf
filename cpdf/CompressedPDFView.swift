var body: some View {
    VStack(spacing: 30) {
        Text(LocalizedStringKey("PDF Komprimierung"))
            .font(.title)
            .foregroundColor(.primary)
        
        HStack(spacing: 40) {
            // Original PDF
            VStack {
                // ... Preview Code ...
                
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
            
            // ... Rest des Views
            
            Button(LocalizedStringKey("Neue PDF komprimieren")) {
                pdfCompressor.compressionResult = nil
            }
            .buttonStyle(.borderedProminent)
        }
    }
} 