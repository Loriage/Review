import SwiftUI

struct LibraryDetailView: View {
    @StateObject private var viewModel: LibraryDetailViewModel
    @State private var showingSettings = false

    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibraryDetailViewModel(
            library: library,
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Chargement...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        libraryHeader
                        statsSection
                        carouselSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(viewModel.library.library.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            Text("Settings")
        }
        .task {
            await viewModel.loadLibraryContent()
        }
    }

    private var libraryHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Type de bibliothèque : \(viewModel.library.library.type == "movie" ? "Films" : "Séries")")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistiques")
                .font(.title2.bold())

            if viewModel.library.library.type == "movie" {
                if let count = viewModel.library.fileCount {
                    Text("Nombre de films: \(count)")
                }
            } else if viewModel.library.library.type == "show" {
                if let showCount = viewModel.library.fileCount {
                    Text("Nombre de séries: \(showCount)")
                }
                Text("Nombre d'épisodes: \(viewModel.episodesCount)")
            }
        }
    }

    private var carouselSection: some View {
        VStack(alignment: .leading) {
            Text("Contenu")
                .font(.title2.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.allMedia) { media in
                        NavigationLink(destination: MediaHistoryView(
                            ratingKey: media.ratingKey,
                            mediaType: media.type,
                            grandparentRatingKey: media.type == "show" ? media.ratingKey : media.grandparentRatingKey,
                            serverViewModel: serverViewModel,
                            authManager: authManager,
                            statsViewModel: statsViewModel
                        )) {
                            AsyncImageView(url: viewModel.posterURL(for: media))
                                .frame(width: 150, height: 225)
                                .cornerRadius(8)
                                .shadow(radius: 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
