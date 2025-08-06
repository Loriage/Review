import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Accès non autorisé")
                .font(.title2.bold())
            Text("Votre compte Plex ne dispose pas des permissions nécessaires pour voir l'activité du serveur.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
