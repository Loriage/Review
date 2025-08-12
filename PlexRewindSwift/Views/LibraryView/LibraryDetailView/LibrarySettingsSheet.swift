import SwiftUI

struct LibrarySettingsSheet: View {
    @ObservedObject var viewModel: LibraryDetailViewModel
    
    @Binding var showingSettings: Bool
    @Binding var navigateToLibrarySettings: Bool
    @Binding var showingRefreshAlert: Bool
    @Binding var showingAnalyzeAlert: Bool
    @Binding var showingEmptyTrashAlert: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: { handleNavigation { self.navigateToLibrarySettings = true } }) {
                Label("Paramètres de la bibliothèque", systemImage: "gearshape.fill")
            }

            Button(action: { handleAction { await self.viewModel.scanLibrary() } }) {
                Label("Scanner la bibliothèque", systemImage: "waveform.path.ecg")
            }
            
            Button(action: { handleAction { self.showingRefreshAlert = true } }) {
                Label("Actualiser les métadonnées", systemImage: "arrow.trianglehead.counterclockwise")
            }
            
            Button(action: { handleAction { self.showingAnalyzeAlert = true } }) {
                Label("Analyser", systemImage: "wand.and.rays")
            }
            
            Button(action: { handleAction { self.showingEmptyTrashAlert = true } }) {
                Label("Vider la corbeille", systemImage: "trash")
            }
        }
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
        .foregroundColor(.primary)
        .presentationBackground(.regularMaterial)
    }
    
    private func handleAction(action: @escaping () async -> Void) {
        showingSettings = false
        Task {
            await action()
        }
    }

    private func handleNavigation(action: @escaping () -> Void) {
        showingSettings = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            action()
        }
    }
}
