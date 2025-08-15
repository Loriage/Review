import SwiftUI

struct PosterOverlay: View {
    let session: PlexActivitySession

    var body: some View {
        ZStack {
            if session.player.state == "paused" {
                Rectangle()
                    .fill(.black.opacity(0.5))
                Image(systemName: "pause.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
            }
        }
        .cornerRadius(8)
        .allowsHitTesting(false)
    }
}
