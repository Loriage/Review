import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: Int = 0 {
        didSet {
            applyTheme()
        }
    }
    
    init() {
        applyTheme()
    }

    func applyTheme() {
        guard let theme = Theme(rawValue: selectedTheme) else { return }
        
        let scenes = UIApplication.shared.connectedScenes
        if let windowScene = scenes.first as? UIWindowScene {
            switch theme {
            case .automatic:
                windowScene.windows.forEach { $0.overrideUserInterfaceStyle = .unspecified }
            case .light:
                windowScene.windows.forEach { $0.overrideUserInterfaceStyle = .light }
            case .dark:
                windowScene.windows.forEach { $0.overrideUserInterfaceStyle = .dark }
            }
        }
    }
}
