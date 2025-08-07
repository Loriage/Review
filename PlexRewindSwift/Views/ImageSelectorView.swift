import SwiftUI

struct ImageSelectorView: View {
    @StateObject var viewModel: ImageSelectorViewModel
    @Environment(\.dismiss) var dismiss

    init(session: PlexActivitySession, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: ImageSelectorViewModel(
            session: session,
            plexService: PlexAPIService(),
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        artworkSection(title: "Affiches", artworks: viewModel.posters)
                    }
                }
                
                if let hudMessage = viewModel.hudMessage {
                    HUDView(hudMessage: hudMessage)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(), value: viewModel.hudMessage)
            .navigationTitle("Changer d'image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                await viewModel.loadImages()
            }
        }
    }
    
    @ViewBuilder
    private func artworkSection(title: String, artworks: [PlexArtwork]) -> some View {
        if !artworks.isEmpty {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2.bold())
                    .padding([.horizontal, .top])
                
                let columns = [GridItem(.adaptive(minimum: 150))]
                
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(artworks) { artwork in
                        Button(action: {
                            Task { await viewModel.selectImage(artwork) }
                        }) {
                            AsyncImageView(url: viewModel.artworkURL(for: artwork))
                                .aspectRatio(2/3, contentMode: .fill)
                                .overlay(
                                    artwork.selected == true ?
                                    ZStack {
                                        Color.black.opacity(0.5)
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                    } : nil
                                )
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
}
