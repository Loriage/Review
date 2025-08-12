import SwiftUI

struct ActivityHeaderView: View {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
