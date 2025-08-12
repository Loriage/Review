import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "tv.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Aucune activité")
                .font(.title2.bold())
            Text("Rien n'est en cours de lecture sur le serveur sélectionné.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
