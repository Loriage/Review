import SwiftUI

struct HUDMessage: Equatable {
    let iconName: String
    let text: LocalizedStringKey
    let maxWidth: CGFloat?

    init(iconName: String, text: LocalizedStringKey, maxWidth: CGFloat? = 240) {
        self.iconName = iconName
        self.text = text
        self.maxWidth = maxWidth
    }
}
