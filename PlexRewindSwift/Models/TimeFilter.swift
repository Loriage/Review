import Foundation

enum TimeFilter: String, CaseIterable, Identifiable {
    case week
    case month
    case year
    case allTime

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .week:
            return "Cette semaine"
        case .month:
            return "Ce mois"
        case .year:
            return "Cette année"
        case .allTime:
            return "Tout le temps"
        }
    }
}
