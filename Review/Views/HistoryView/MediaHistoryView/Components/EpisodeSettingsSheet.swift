import SwiftUI

struct EpisodeSettingsSheet: View {
    @ObservedObject var actionsViewModel: MediaActionsViewModel

    @Binding var showingSettings: Bool
    @Binding var showMediaDetails: Bool
    @Binding var showImageSelector: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: { handleAction { self.showMediaDetails = true } }) {
                Label("activity.settings.media.details", systemImage: "info.circle")
            }
            
            Button(action: { handleAction { self.showImageSelector = true } }) {
                Label("image.selector.change.poster.episode", systemImage: "photo")
            }
            
            Button(action: { handleActionAsync { await self.actionsViewModel.refreshMetadata() } }) {
                Label("activity.settings.refresh.metadata.episode", systemImage: "arrow.trianglehead.counterclockwise")
            }
            
            Button(action: { handleActionAsync { await self.actionsViewModel.analyzeMedia() } }) {
                Label("activity.settings.analyze.episode", systemImage: "wand.and.rays")
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
