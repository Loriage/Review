import SwiftUI

struct EpisodeSettingsSheet: View {
    @ObservedObject var actionsViewModel: MediaActionsViewModel

    @Binding var showingSettings: Bool
    @Binding var showMediaDetails: Bool
    @Binding var showImageSelector: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: { handleAction { self.showMediaDetails = true } }) {
                Label("Détails du média", systemImage: "info.circle")
            }
            
            Button(action: { handleAction { self.showImageSelector = true } }) {
                Label("Modifier l'affiche de l'épisode", systemImage: "photo")
            }
            
            Button(action: { handleActionAsync { await self.actionsViewModel.refreshMetadata() } }) {
                Label("Actualiser les métadonnées de l'épisode", systemImage: "arrow.trianglehead.counterclockwise")
            }
            
            Button(action: { handleActionAsync { await self.actionsViewModel.analyzeMedia() } }) {
                Label("Analyser l'épisode", systemImage: "wand.and.rays")
            }
        }
        .font(.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
        .foregroundColor(.primary)
        .presentationBackground(.regularMaterial)
    }

    private func handleAction(action: @escaping () -> Void) {
        showingSettings = false
        action()
    }
    
    private func handleActionAsync(action: @escaping () async -> Void) {
        showingSettings = false
        Task {
            await action()
        }
    }
}
