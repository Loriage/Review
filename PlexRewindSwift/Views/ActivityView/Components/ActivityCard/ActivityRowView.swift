import SwiftUI

struct ActivityRowView: View {
    let session: PlexActivitySession
    
    @StateObject private var actionsViewModel: ActivityActionsViewModel
    @State private var dominantColor: Color = Color(.systemGray4)
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager

    init(session: PlexActivitySession) {
        self.session = session
        _actionsViewModel = StateObject(wrappedValue: ActivityActionsViewModel(
            session: session,
            serverViewModel: ServerViewModel(authManager: PlexAuthManager()),
            authManager: PlexAuthManager()
        ))
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                ActivityHeaderView(session: session, dominantColor: $dominantColor, actionsViewModel: actionsViewModel)
                
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

            if let hudMessage = actionsViewModel.hudMessage {
                HUDView(hudMessage: hudMessage)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: actionsViewModel.hudMessage)
            }
        }
    }
}
