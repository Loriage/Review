import Foundation

enum TopStatsSortOption: String, CaseIterable, Identifiable {
    case byPlays
    case byDuration

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .byPlays:
            return "Lectures"
        case .byDuration:
            return "Durée"
        }
    }
}
