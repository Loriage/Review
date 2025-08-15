import Foundation

enum Theme: Int, CaseIterable, Identifiable {
    case automatic = 0
    case light = 1
    case dark = 2
    
    var id: Int { self.rawValue }
    
    var title: String {
        switch self {
        case .automatic:
            return String(localized:"theme.auto")
        case .light:
            return String(localized:"theme.light")
        case .dark:
            return String(localized:"theme.dark")
        }
    }
}
