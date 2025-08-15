import SwiftUI

struct ActivityHeaderView: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    let session: PlexActivitySession
    @Binding var dominantColor: Color
    
    @State private var isShowingSheet = false
    @State private var isShowingStopAlert = false
    @State private var navigateToMediaHistory = false
    @State private var navigateToUserHistory = false
    @State private var stopReason = ""

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            NavigationLink(destination: MediaHistoryView(
                ratingKey: session.grandparentRatingKey ?? session.ratingKey,
                mediaType: session.type == "movie" ? "movie" : "show",
                grandparentRatingKey: session.grandparentRatingKey,
                serverViewModel: serverViewModel,
                authManager: authManager,
                statsViewModel: statsViewModel
            )) {
                HStack(spacing: 15) {
                    AsyncImageView(url: session.posterURL, contentMode: .fill) { color in
                        self.dominantColor = color
                    }
                    .frame(width: 60, height: 90)
                    .cornerRadius(8)
                    .overlay(PosterOverlay(session: session))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.showTitle)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if session.type == "episode", let season = session.parentIndex, let episode = session.index {
                            Text(session.title)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Text("S\(season) - E\(episode)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if session.type == "movie", let year = session.year {
                            Text(String(year))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(TimeFormatter.formatRemainingSeconds(session.remainingTimeInSeconds))
                            .font(.subheadline.monospacedDigit())
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: {
                isShowingSheet.toggle()
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                    .font(.title2.weight(.medium))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .sheet(isPresented: $isShowingSheet) {
            ActivitySettingsSheet(
                session: session,
                isPresented: $isShowingSheet,
                showStopAlert: $isShowingStopAlert,
                navigateToMediaHistory: $navigateToMediaHistory,
                navigateToUserHistory: $navigateToUserHistory
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .alert("activity.settings.interrupt.alert.title", isPresented: $isShowingStopAlert) {
            TextField("optional.message.alert", text: $stopReason)
            Button("common.cancel", role: .cancel) { }
            Button("activity.settings.interrupt", role: .destructive) {
                Task {
                    await activityViewModel.stopPlayback(for: session, reason: stopReason)
                }
            }
        } message: {
            Text("activity.settings.interrupt.alert.message")
        }
        .navigationDestination(isPresented: $navigateToMediaHistory) {
            MediaHistoryView(
                ratingKey: session.grandparentRatingKey ?? session.ratingKey,
                mediaType: session.type == "movie" ? "movie" : "show",
                grandparentRatingKey: session.grandparentRatingKey,
                serverViewModel: serverViewModel,
                authManager: authManager,
                statsViewModel: statsViewModel
            )
        }
        .navigationDestination(isPresented: $navigateToUserHistory) {
            if let userId = Int(session.user.id) {
                UserHistoryView(
                    userID: userId,
                    userName: session.user.title,
                    statsViewModel: statsViewModel,
                    serverViewModel: serverViewModel,
                    authManager: authManager
                )
            }
        }
    }
}
