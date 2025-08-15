import SwiftUI

struct ActivityFooterView: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    let session: PlexActivitySession

    private var streamDescription: String {
        let serverName = serverViewModel.availableServers.first { $0.id == serverViewModel.selectedServerID }?.name ?? NSLocalizedString("unknown.server", comment: "")
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
                            Text("location.local")
                        } else if let location = session.location {
                            Text(location)
                        } else {
                            Text("location.remote")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
                
                TranscodingBadgesView(transcodeSession: session.transcodeSession)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
