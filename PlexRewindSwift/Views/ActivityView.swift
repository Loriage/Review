import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var viewModel: PlexMonitorViewModel
    
    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.activityAccessForbidden {
                    VStack(spacing: 15) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Accès non autorisé")
                            .font(.title2.bold())
                        Text("Votre compte Plex ne dispose pas des permissions nécessaires pour voir l'activité du serveur.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if viewModel.selectedServerID == nil {
                    VStack(spacing: 15) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Aucun serveur sélectionné")
                            .font(.title2.bold())
                        Text("Allez dans l'onglet \"Réglages\" pour choisir un serveur Plex.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.currentSessions.isEmpty {
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
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.currentSessions) { session in
                                ActivityRowView(session: session)
                                    .environmentObject(viewModel)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refreshActivity()
                    }
                }
            }
            .navigationTitle("Activité en cours")
            .onAppear {
                if viewModel.availableServers.isEmpty && !viewModel.isLoading {
                    Task {
                        await viewModel.loadServers(authManager: authManager)
                    }
                }
            }
            .onReceive(timer) { _ in
                Task {
                    await viewModel.refreshActivity()
                }
            }
        }
    }
}

struct ActivityRowView: View {
    @EnvironmentObject var viewModel: PlexMonitorViewModel
    let session: PlexActivitySession

    @State private var dominantColor: Color = Color(.systemGray4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 15) {
                AsyncImageView(url: session.posterURL, contentMode: .fill) { color in
                    self.dominantColor = color
                }
                .frame(width: 60, height: 90)
                .cornerRadius(8)
                .overlay(
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
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.showTitle)
                        .font(.headline)
                        .lineLimit(1)

                    if session.type == "episode", let seasonNumber = session.parentIndex, let episodeNumber = session.index {
                        Text(session.title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Text("S\(seasonNumber) - E\(episodeNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if session.type == "movie", let year = session.year {
                        Text(String(year))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(formattedRemainingTime)
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
            }
            .padding([.top, .leading, .trailing])

            ProgressView(value: session.progress)
                .progressViewStyle(
                    CustomLinearProgressViewStyle(
                        trackColor: Color.gray.opacity(0.3),
                        progressColor: Color.accentColor,
                        height: 5
                    )
                )
            VStack {
                HStack(spacing: 15) {
                    AsyncImageView(url: userThumbURL)
                        .frame(width: 50, height: 50)
                        .padding(.horizontal, 5)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.user.title)
                            .font(.subheadline.bold())
                        
                        Text(streamDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack{
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
                    Spacer()
                }
            }
            .padding([.bottom, .leading, .trailing])
        }
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .background(
            MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        [0, 0], [0.5, 0], [1, 0],
                        [0, 0.5], [0.5, 0.5], [1, 0.5],
                        [0, 1], [0.5, 1], [1, 1]
                    ],
                    colors: [
                        .clear, dominantColor.opacity(0.2), .clear,
                        Color.accentColor.opacity(0.1), dominantColor.opacity(0.2), Color.accentColor.opacity(0.1),
                        .clear, .clear, dominantColor.opacity(0.2)
                    ]
                )
        )
        .cornerRadius(20)
    }
    
    private var serverName: String {
        if let serverID = viewModel.selectedServerID,
           let server = viewModel.availableServers.first(where: { $0.id == serverID }) {
            return server.name
        }
        return "Serveur inconnu"
    }

    private var userThumbURL: URL? {
        guard let thumbPath = session.user.thumb,
              let serverID = viewModel.selectedServerID,
              let server = viewModel.availableServers.first(where: { $0.id == serverID }),
              let connection = server.connections.first(where: { !$0.local }) ?? server.connections.first,
              let token = viewModel.authManager.getPlexAuthToken(),
              var components = URLComponents(string: "\(connection.uri)/photo/:/transcode")
        else { return nil }
        
        components.queryItems = [
            URLQueryItem(name: "url", value: thumbPath),
            URLQueryItem(name: "width", value: "100"),
            URLQueryItem(name: "height", value: "100"),
            URLQueryItem(name: "minSize", value: "1"),
            URLQueryItem(name: "X-Plex-Token", value: token)
        ]
        return components.url
    }
    
    private var streamDescription: String {
        return "\(serverName) → \(session.player.product) (\(session.player.platform))"
    }
    
    private var formattedRemainingTime: String {
        let seconds = session.remainingTimeInSeconds
        if seconds <= 0 {
            return "Terminé"
        }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m restantes"
        } else {
            return "\(minutes)m restantes"
        }
    }
}
