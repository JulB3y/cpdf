import SwiftUI

struct AppIcon: View {
    var body: some View {
        ZStack {
            // Hintergrund
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // PDF Symbol
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .frame(width: 60, height: 70)
                    .overlay(
                        VStack(spacing: 4) {
                            Text("PDF")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                    )
            }
        }
    }
} 