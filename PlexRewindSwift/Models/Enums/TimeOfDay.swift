import Foundation
import SwiftUI

enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning, afternoon, evening, night
    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .morning: String(localized:"time.of.day.morning")
        case .afternoon: String(localized:"time.of.day.afternoon")
        case .evening: String(localized:"time.of.day.evening")
        case .night: String(localized:"time.of.day.night")
        }
    }
}
