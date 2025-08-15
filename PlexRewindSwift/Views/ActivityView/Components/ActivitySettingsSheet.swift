import SwiftUI

struct ActivitySettingsSheet: View {
    let session: PlexActivitySession
        
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var authManager: PlexAuthManager

    @Binding var isPresented: Bool
    @Binding var showStopAlert: Bool
    @Binding var navigateToMediaHistory: Bool
    @Binding var navigateToUserHistory: Bool

    @State private var showMediaDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigateToMediaHistory = true
                }
            }) {
                Label("activity.settings.media.history", systemImage: "tv")
                    .symbolRenderingMode(.monochrome)
            }
            Button(action: {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    navigateToUserHistory = true
                }
            }) {
                Label("activity.settings.user.history", systemImage: "person.crop.circle")
            }
            Button(action: { showMediaDetails = true }) {
                Label("activity.settings.media.details", systemImage: "info.circle")
            }
            
            Button(action: { handleActionAsync { await activityViewModel.refreshMetadata(for: session) } }) {
                Label("activity.settings.refresh.metadata", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Button(action: { handleActionAsync { await activityViewModel.analyzeMedia(for: session) } }) {
                Label("activity.settings.analyze", systemImage: "wand.and.rays")
            }
            
            Button(action: {
                isPresented = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showStopAlert = true
                }
            }) {
                Label("activity.settings.interrupt", systemImage: "stop.circle.fill")
            }
            .foregroundColor(.red)
        }
        .font(.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 20)
        .foregroundColor(.primary)
        .presentationBackground(.regularMaterial)
        .sheet(isPresented: $showMediaDetails) {
            MediaDetailsView(ratingKey: session.ratingKey, serverViewModel: serverViewModel, authManager: authManager)
        }
    }

    private func handleActionAsync(action: @escaping () async -> Void) {
        isPresented = false
        Task {
            await action()
        }
    }
}
