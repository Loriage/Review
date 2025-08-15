import Foundation

enum TimeFilter: String, CaseIterable, Identifiable {
    case week, month, year, allTime
    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .week: String(localized:"filter.time.week")
        case .month: String(localized:"filter.time.month")
        case .year: String(localized:"filter.time.year")
        case .allTime: String(localized:"filter.time.allTime")
        }
    }
}
