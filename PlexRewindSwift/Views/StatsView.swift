import SwiftUI

struct StatsView: View {
    @EnvironmentObject var viewModel: StatsViewModel
    
    var body: some View {
        NavigationStack {
            VStack {
                if let stats = viewModel.userStats {
                    StatsDisplayView(stats: stats)
                } else if viewModel.isLoading {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                        Text(viewModel.loadingStatusMessage)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "gear.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Prêt à commencer ?")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Allez dans l'onglet \"Réglages\" pour sélectionner un serveur, une année, et générer votre Rewind.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Plex Rewind")
        }
    }
}
