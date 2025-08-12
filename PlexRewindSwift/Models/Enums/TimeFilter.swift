import Foundation

enum TimeFilter: String, CaseIterable, Identifiable {
    case week, month, year, allTime
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .week: "Cette semaine"
        case .month: "Ce mois"
        case .year: "Cette année"
        case .allTime: "Tout le temps"
        }
    }
}
