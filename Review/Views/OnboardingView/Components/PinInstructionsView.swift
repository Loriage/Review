import SwiftUI

struct PinInstructionsView: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("pin.instructions.title")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("pin.instructions.link.text")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Link("https://plex.tv/link", destination: URL(string: "https://plex.tv/link")!)
                .font(.headline)
                .foregroundColor(.orange)
        }
    }
}
