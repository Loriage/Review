import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    
    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        switch activityViewModel.state {
                        case .content(let sessions):
                            VStack(spacing: 15) {
                                ForEach(sessions) { session in
                                    ActivityRowView(session: session)
                                }
                            }
                            .padding()
                            Spacer()
                        case .loading:
                            ProgressView()
                            
                        case .forbidden:
                            PermissionDeniedView()
                            
                        case .noServerSelected:
                            NoServerView()
                            
                        case .empty:
                            EmptyStateView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await activityViewModel.refreshActivity()
                }
            }
            .navigationTitle("Activité en cours")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if serverViewModel.availableServers.isEmpty && !serverViewModel.isLoading {
                    Task {
                        await serverViewModel.loadServers()
                    }
                }
            }
            .onReceive(timer) { _ in
                Task {
                    await activityViewModel.refreshActivity()
                }
            }
        }
    }
}

struct ActivityRowView: View {
    let session: PlexActivitySession
    @State private var dominantColor: Color = Color(.systemGray4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActivityHeaderView(session: session, dominantColor: $dominantColor)
            
            ProgressView(value: session.progress)
                .progressViewStyle(
                    CustomLinearProgressViewStyle(
                        trackColor: Color.gray.opacity(0.3),
                        progressColor: Color.accentColor,
                        height: 5
                    )
                )

            ActivityFooterView(session: session)
        }
        .background(.thinMaterial)
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [ [0, 0], [0.5, 0], [1, 0], [0, 0.5], [0.5, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1] ],
                colors: [ .clear, dominantColor.opacity(0.3), .clear, Color.accentColor.opacity(0.2), dominantColor.opacity(0.3), Color.accentColor.opacity(0.2), .clear, .clear, dominantColor.opacity(0.2) ]
            )
        )
        .cornerRadius(20)
    }
}

private struct ActivityHeaderView: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    let session: PlexActivitySession
    @Binding var dominantColor: Color

    var body: some View {
        NavigationLink(destination: MediaHistoryView(
            ratingKey: session.ratingKey,
            mediaType: session.type,
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
                Spacer(minLength: 0)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

private struct PosterOverlay: View {
    let session: PlexActivitySession

    var body: some View {
        ZStack {
            if session.player.state == "paused" {
                Rectangle()
                    .fill(.black.opacity(0.5))
                Image(systemName: "pause.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }
        }
        .cornerRadius(8)
        .allowsHitTesting(false)
    }
}

private struct ActivityFooterView: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    let session: PlexActivitySession

    private var streamDescription: String {
        let serverName = serverViewModel.availableServers.first { $0.id == serverViewModel.selectedServerID }?.name ?? "Serveur inconnu"
        return "\(serverName) → \(session.player.product) (\(session.player.platform))"
    }

    private var userThumbURL: URL? {
        guard let thumbPath = session.user.thumb,
              let serverID = serverViewModel.selectedServerID,
              let server = serverViewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = authManager.getPlexAuthToken(),
              var components = URLComponents(string: "\(connection.uri)/photo/:/transcode")
        else { return nil }
        
        components.queryItems = [
            URLQueryItem(name: "url", value: thumbPath),
            URLQueryItem(name: "width", value: "200"),
            URLQueryItem(name: "height", value: "200"),
            URLQueryItem(name: "minSize", value: "1"),
            URLQueryItem(name: "X-Plex-Token", value: token)
        ]
        return components.url
    }

    var body: some View {
        NavigationLink(destination: UserHistoryView(
            userID: Int(session.user.id) ?? 0,
            userName: session.user.title,
            statsViewModel: statsViewModel,
            serverViewModel: serverViewModel,
            authManager: authManager
        )) {
            HStack(spacing: 15) {
                AsyncImageView(url: userThumbURL)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.user.title)
                        .font(.subheadline.bold())
                    
                    Text(streamDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if session.player.local {
                            Text("Local")
                        } else if let location = session.location {
                            Text(location)
                        } else {
                            Text("Distant")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
                
                TranscodingBadgesView(transcodeSession: session.transcodeSession)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

private struct TranscodingBadgesView: View {
    let transcodeSession: PlexActivitySession.TranscodeSession?

    private var isHardwareTranscoding: Bool {
        guard let transcode = transcodeSession, transcode.videoDecision == "transcode" else { return false }
        return transcode.transcodeHwRequested
    }
    
    private var isSoftwareTranscoding: Bool {
        guard let transcode = transcodeSession, transcode.videoDecision == "transcode" else { return false }
        return !transcode.transcodeHwRequested
    }

    private var isAudioTranscoding: Bool {
        guard let transcode = transcodeSession else { return false }
        return transcode.audioDecision == "transcode"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if isAudioTranscoding { BadgeView(text: "AUDIO") }
            if isSoftwareTranscoding { BadgeView(text: "SW") }
            if isHardwareTranscoding { BadgeView(text: "HW") }
        }
    }
}
