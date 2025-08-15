import Foundation

enum TopStatsSortOption: String, CaseIterable, Identifiable {
    case byPlays
    case byDuration

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .byPlays:
            return "\(String(localized: "sort.option.by.plays"))"
        case .byDuration:
            return "\(String(localized: "sort.option.by.duration"))"
        }
    }
}
