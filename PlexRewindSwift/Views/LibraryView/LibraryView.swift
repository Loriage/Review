import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    
    // On injecte les dépendances depuis la vue parente (MainTabView)
    init(serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(
            serverViewModel: serverViewModel,
            authManager: authManager
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
                } else if viewModel.libraries.isEmpty {
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
                            ForEach(viewModel.libraries) { library in
                                LibraryCardView(library: library)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Médiathèque")
            .task {
                await viewModel.loadLibraries()
            }
            .refreshable {
                await viewModel.loadLibraries()
            }
        }
    }
}

// NOUVELLE VUE : La carte pour afficher une seule médiathèque
struct LibraryCardView: View {
    let library: PlexLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon(for: library.type))
                    .font(.title)
                    .frame(width: 40, alignment: .center)
                    .foregroundColor(.accentColor)
                
                Text(library.title)
                    .font(.title2.bold())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Label {
                    Text("Créée le: \(formatDate(library.createdAt))")
                } icon: {
                    Image(systemName: "calendar.badge.plus")
                }
                
                Label {
                    Text("Mise à jour le: \(formatDate(library.updatedAt))")
                } icon: {
                    Image(systemName: "calendar.badge.clock")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.leading, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func icon(for type: String) -> String {
        switch type {
        case "movie":
            return "film.stack.fill"
        case "show":
            return "tv.and.mediabox.fill"
        case "artist", "album":
            return "music.mic"
        default:
            return "folder.fill"
        }
    }

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()

        formatter.dateStyle = .long
        formatter.timeStyle = .none

        return formatter.string(from: date)
    }
}
