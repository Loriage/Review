import SwiftUI

struct BadgeView: View {
    let text: LocalizedStringKey
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 4)
            )
            .background(Color.black.opacity(0.6))
            .cornerRadius(4)
    }
}
