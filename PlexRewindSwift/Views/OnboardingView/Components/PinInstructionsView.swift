import SwiftUI

struct PinInstructionsView: View {
    var body: some View {
        VStack(spacing: 25) {
            Text("Finalisez la connexion")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Rendez-vous sur le site web suivant et entrez le code ci-dessous :")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Link("https://plex.tv/link", destination: URL(string: "https://plex.tv/link")!)
                .font(.headline)
                .foregroundColor(.orange)
        }
    }
}
