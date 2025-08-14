import SwiftUI

struct MediaSettingsSheet: View {
    @ObservedObject var viewModel: MediaHistoryViewModel
    @ObservedObject var actionsViewModel: MediaActionsViewModel

    @Binding var showingSettings: Bool
    @Binding var showMediaDetails: Bool
    @Binding var showImageSelector: Bool
    @Binding var showFixMatchView: Bool
    @Binding var showingAnalysisAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if viewModel.mediaType == "movie" {
                Button(action: { handleAction { self.showMediaDetails = true } }) {
                    Label("Détails du média", systemImage: "info.circle")
                }
            }
            
            Button(action: { handleAction { self.showImageSelector = true } }) {
                Label("Modifier l'image", systemImage: "photo")
            }
            
            Button(action: { handleActionAsync { await self.actionsViewModel.refreshMetadata() } }) {
                Label("Actualiser les métadonnées", systemImage: "arrow.trianglehead.counterclockwise")
            }
            
            Button(action: { handleAction { self.showingAnalysisAlert = true } }) {
                Label("Analyser", systemImage: "wand.and.rays")
            }
            
            Button(action: { handleAction { self.showFixMatchView = true } }) {
                Label("Corriger l'association...", systemImage: "pencil")
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
