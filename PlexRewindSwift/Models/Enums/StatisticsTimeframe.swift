import Foundation

enum StatisticsTimeframe: String, CaseIterable, Identifiable {
    case realtime = "Temps réel"
    case last12Hours = "Les 12 dernières heures"
    case last24Hours = "Les 24 dernières heures"
    case last7Days = "Les 7 derniers jours"
    case last30Days = "Les 30 derniers jours"
    case last90Days = "Les 90 derniers jours"
    case lastYear = "L'année dernière"
    case allTime = "Depuis le début"

    var id: String { self.rawValue }
    var displayName: String { self.rawValue }

    var apiParameters: (timespan: Int, at: Int) {
        let now = Int(Date().timeIntervalSince1970)
        
        switch self {
        case .realtime:
            return (6, now - 300)
        case .last12Hours:
            return (4, now - (12 * 3600))
        case .last24Hours:
            return (4, now - (24 * 3600))
        case .last7Days:
            return (3, now - (7 * 24 * 3600))
        case .last30Days:
            return (2, now - (30 * 24 * 3600))
        case .last90Days:
            return (2, now - (90 * 24 * 3600))
        case .lastYear:
            return (1, now - (365 * 24 * 3600))
        case .allTime:
            return (1, 0)
        }
    }
}
