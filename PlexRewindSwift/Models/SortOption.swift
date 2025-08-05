import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case byPlays = "Lectures"
    case byDuration = "Durée"

    var id: String { self.rawValue }
}
