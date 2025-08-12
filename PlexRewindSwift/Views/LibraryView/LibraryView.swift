import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(
            serverViewModel: serverViewModel,
            authManager: authManager,
            libraryService: PlexLibraryService()
        ))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.displayLibraries.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Aucune médiathèque")
                            .font(.title2.bold())
                        Text("Aucune médiathèque n'a été trouvée sur ce serveur.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(viewModel.displayLibraries) { displayLibrary in
                                NavigationLink(destination: LibraryDetailView(
                                    library: displayLibrary,
                                    serverViewModel: serverViewModel,
                                    authManager: authManager,
                                    statsViewModel: statsViewModel
                                )){
                                    LibraryCardView(displayLibrary: displayLibrary)
                                        .task {
                                            viewModel.startFetchingDetailsFor(libraryID: displayLibrary.id)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bibliothèques")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if !viewModel.isLoading {
                    await viewModel.loadLibrariesIfNeeded()
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
        }
    }
}
