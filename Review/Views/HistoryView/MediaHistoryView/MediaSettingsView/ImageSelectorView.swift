import SwiftUI

struct ImageSelectorView: View {
    @StateObject var viewModel: ImageSelectorViewModel
    @Environment(\.dismiss) var dismiss

    init(ratingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: ImageSelectorViewModel(
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
                    ProgressView()
                } else {
                    ScrollView {
                        artworkSection(title: "image.selector.posters", artworks: viewModel.posters)
                    }
                }
                
                if let hudMessage = viewModel.hudMessage {
                    HUDView(hudMessage: hudMessage)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(), value: viewModel.hudMessage)
            .navigationTitle("image.selector.change.image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
            .task {
                await viewModel.loadImages()
            }
        }
    }
    
    @ViewBuilder
    private func artworkSection(title: LocalizedStringKey, artworks: [PlexArtwork]) -> some View {
        if !artworks.isEmpty {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2.bold())
                    .padding([.horizontal, .top])
                
                let columns = [GridItem(.adaptive(minimum: 150))]
                
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(artworks) { artwork in
                        AsyncImageView(url: viewModel.artworkURL(for: artwork), contentMode: .fit)
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
                            .onTapGesture {
                                Task { await viewModel.selectImage(artwork) }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
}
