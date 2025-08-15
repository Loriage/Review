import Foundation
import SwiftUI

enum TopStatsSortOption: String, CaseIterable, Identifiable {
    case byPlays
    case byDuration

    var id: String { self.rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .byPlays:
            return "sort.option.by.plays"
        case .byDuration:
            return "sort.option.by.duration"
        }
    }
}
