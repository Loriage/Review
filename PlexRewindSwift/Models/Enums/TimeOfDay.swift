import Foundation
import SwiftUI

enum TimeOfDay: String, CaseIterable, Identifiable {
    case morning, afternoon, evening, night
    var id: String { self.rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .morning: "time.of.day.morning"
        case .afternoon: "time.of.day.afternoon"
        case .evening: "time.of.day.evening"
        case .night: "time.of.day.night"
        }
    }
}
