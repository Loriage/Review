import SwiftUI

struct HUDMessage: Equatable {
    let iconName: String
    let text: String
    let maxWidth: CGFloat?

    init(iconName: String, text: String, maxWidth: CGFloat? = 240) {
        self.iconName = iconName
        self.text = text
        self.maxWidth = maxWidth
    }
}
