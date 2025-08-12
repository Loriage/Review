import SwiftUI

struct LoadingStateView: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 50))
                .symbolEffect(.bounce.up.byLayer, value: isAnimating)
                .onAppear { isAnimating = true }
                .foregroundColor(.accentColor)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: message)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
