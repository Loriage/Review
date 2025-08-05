import Foundation

struct RankedMedia: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let posterURL: URL?
}

struct UserStats {
    let totalWatchTimeMinutes: Int
    let totalMovies: Int
    let totalEpisodes: Int

    let rankedMovies: [RankedMedia]
    let rankedShows: [RankedMedia]

    var formattedTotalWatchTime: String {
        let hours = totalWatchTimeMinutes / 60
        let minutes = totalWatchTimeMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}
