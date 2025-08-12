import SwiftUI

struct HUDView: View {
    let hudMessage: HUDMessage

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hudMessage.iconName)
                .font(.largeTitle)
                .imageScale(.large)
            
            Text(hudMessage.text)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding(EdgeInsets(top: 25, leading: 35, bottom: 25, trailing: 35))
        .frame(maxWidth: hudMessage.maxWidth)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
