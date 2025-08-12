import SwiftUI

struct ActivityRowView: View {
    let session: PlexActivitySession
    @State private var dominantColor: Color = Color(.systemGray4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ActivityHeaderView(session: session, dominantColor: $dominantColor)
            
            ProgressView(value: session.progress)
                .progressViewStyle(
                    CustomLinearProgressViewStyle(
                        trackColor: Color.gray.opacity(0.3),
                        progressColor: Color.accentColor,
                        height: 5
                    )
                )

            ActivityFooterView(session: session)
        }
        .background(.thinMaterial)
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [ [0, 0], [0.5, 0], [1, 0], [0, 0.5], [0.5, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1] ],
                colors: [ .clear, dominantColor.opacity(0.3), .clear, Color.accentColor.opacity(0.2), dominantColor.opacity(0.3), Color.accentColor.opacity(0.2), .clear, .clear, dominantColor.opacity(0.2) ]
            )
        )
        .cornerRadius(20)
    }
}
