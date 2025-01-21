import SwiftUI

struct NoReductionView: View {
    @EnvironmentObject private var pdfCompressor: PDFCompressor
    let fileName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(LocalizedStringKey("Keine Reduzierung möglich"))
                .font(.headline)
            
            Text(LocalizedStringKey("Die Datei \"\(fileName)\" konnte nicht weiter komprimiert werden."))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(LocalizedStringKey("Neue PDF komprimieren")) {
                pdfCompressor.reset()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

#Preview {
    NoReductionView(fileName: "test.pdf")
        .environmentObject(PDFCompressor())
}
