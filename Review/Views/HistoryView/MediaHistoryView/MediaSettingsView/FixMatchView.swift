import SwiftUI

struct FixMatchView: View {
    @StateObject var viewModel: FixMatchViewModel
    @Environment(\.dismiss) var dismiss

    init(ratingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: FixMatchViewModel(
            ratingKey: ratingKey,
            metadataService: PlexMetadataService(),
            actionsService: PlexActionsService(),
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("fixMatchView.loading.message")
                } else {
                    List(viewModel.matches) { match in
                        Button(action: {
                            Task {
                                await viewModel.selectMatch(match)
                                try? await Task.sleep(nanoseconds: 1_500_000_000)
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 15) {
                                AsyncImageView(url: URL(string: match.thumb ?? ""))
                                    .frame(width: 50, height: 75)
                                    .cornerRadius(4)
                                    .clipped()
                                
                                VStack(alignment: .leading) {
                                    Text(match.name)
                                        .font(.headline)
                                    if let year = match.year {
                                        Text(String(year))
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let hudMessage = viewModel.hudMessage {
                    HUDView(hudMessage: hudMessage)
                }
            }
            .navigationTitle("fixMatchView.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadMatches()
            }
        }
    }
}
