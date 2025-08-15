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
                Label("library.settings.sheet.library.settings", systemImage: "gearshape.fill")
            }

            Button(action: { handleAction { await self.viewModel.scanLibrary() } }) {
                Label("library.settings.sheet.scan", systemImage: "waveform.path.ecg")
            }
            
            Button(action: { handleAction { self.showingRefreshAlert = true } }) {
                Label("activity.settings.refresh.metadata", systemImage: "arrow.trianglehead.counterclockwise")
            }
            
            Button(action: { handleAction { self.showingAnalyzeAlert = true } }) {
                Label("activity.settings.analyze", systemImage: "wand.and.rays")
            }
            
            Button(action: { handleAction { self.showingEmptyTrashAlert = true } }) {
                Label("library.settings.sheet.empty.trash", systemImage: "trash")
            }
        }
        .font(.body)
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
