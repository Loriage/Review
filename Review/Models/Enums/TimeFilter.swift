import Foundation
import SwiftUI

enum TimeFilter: String, CaseIterable, Identifiable {
    case week, month, year, allTime

    var id: String { self.rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .week: "filter.time.week"
        case .month: "filter.time.month"
        case .year: "filter.time.year"
        case .allTime: "filter.time.allTime"
        }
    }
}
