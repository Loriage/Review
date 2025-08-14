import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel

    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geometry in
                    ScrollView {
                        VStack {
                            switch activityViewModel.state {
                            case .content(let sessions):
                                VStack(spacing: 15) {
                                    ForEach(sessions) { session in
                                        ActivityRowView(session: session)
                                    }
                                }
                                .padding()
                                Spacer()
                            case .loading:
                                ProgressView()
                                
                            case .forbidden:
                                PermissionDeniedView()
                                
                            case .noServerSelected:
                                NoServerView()
                                
                            case .empty:
                                EmptyStateView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geometry.size.height)
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        await activityViewModel.refreshActivity()
                    }
                }
                if let hudMessage = activityViewModel.hudMessage {
                    HUDView(hudMessage: hudMessage)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: activityViewModel.hudMessage)
                }
            }
            .navigationTitle("Activité en cours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink(destination: InfoView()) {
                        Label("infos", systemImage: "info.circle")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Réglages", systemImage: "gearshape.fill")
                    }
                }
            }
            .onAppear {
                if serverViewModel.availableServers.isEmpty && !serverViewModel.isLoading {
                    Task {
                        await serverViewModel.loadServers()
                    }
                }
            }
            .onReceive(timer) { _ in
                Task {
                    await activityViewModel.refreshActivity()
                }
            }
        }
    }
}
