import SwiftUI

struct LoginPinView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    
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

            if let pinCode = authManager.pin?.code {
                Text(pinCode)
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .textSelection(.enabled)
            } else {
                ProgressView()
            }
            
            ProgressView("En attente de validation...")
                .padding(.top)
        }
        .padding(30)
    }
}
