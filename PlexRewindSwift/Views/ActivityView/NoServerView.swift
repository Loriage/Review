import SwiftUI

struct NoServerView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Aucun serveur sélectionné")
                .font(.title2.bold())
            Text("Allez dans l'onglet \"Réglages\" pour choisir un serveur Plex.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
