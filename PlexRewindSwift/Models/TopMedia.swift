import Foundation

struct TopMedia: Identifiable {
    let id: String
    let title: String
    let mediaType: String
    let viewCount: Int
    let totalWatchTimeSeconds: Int
    let lastViewedAt: Date?
    let posterURL: URL?

    var formattedWatchTime: String {
        if totalWatchTimeSeconds <= 0 {
            return "0m"
        }
        let hours = totalWatchTimeSeconds / 3600
        let minutes = (totalWatchTimeSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
