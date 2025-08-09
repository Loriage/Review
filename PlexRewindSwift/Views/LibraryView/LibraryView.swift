import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var serverViewModel: ServerViewModel
    
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
                                NavigationLink(destination: LibraryDetailView(library: displayLibrary, serverViewModel: serverViewModel, authManager: authManager)) {
                                    LibraryCardView(displayLibrary: displayLibrary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Bibliothèques")
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

struct LibraryCardView: View {
    let displayLibrary: DisplayLibrary
    @State private var dominantColor: Color = .clear

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !displayLibrary.recentItemURLs.isEmpty {
                HStack(spacing: -35) {
                    ForEach(Array(displayLibrary.recentItemURLs.prefix(5).enumerated()), id: \.element) { index, url in
                        AsyncImageView(url: url, onColorExtracted: { color in
                            if index == 0 {
                                self.dominantColor = color
                            }
                        })
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .zIndex(Double(-index))
                    }
                }
            }
            HStack(alignment: .top, spacing: 15) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(displayLibrary.library.title)
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: 5) {
                        Label {
                            HStack {
                                Text("Fichiers :")
                                    .fontWeight(.semibold)
                                Spacer()
                                if let count = displayLibrary.fileCount {
                                    Text("\(count)")
                                        .fontWeight(.semibold)
                                } else {
                                    ProgressView().scaleEffect(0.7)
                                }
                            }
                        } icon: {
                            Image(systemName: "number")
                                .fontWeight(.semibold)
                                .frame(width: 20)
                        }
                        
                        Label {
                            HStack {
                                Text("Taille :")
                                    .fontWeight(.semibold)
                                Spacer()
                                if let size = displayLibrary.size {
                                    Text(formatBytes(size))
                                        .fontWeight(.semibold)
                                } else {
                                    ProgressView().scaleEffect(0.7)
                                }
                            }
                        } icon: {
                            Image(systemName: "externaldrive.fill")
                                .frame(width: 20)
                        }

                        Label {
                            Text("Créée le :")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatDate(displayLibrary.library.createdAt))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "calendar.badge.plus")
                                .frame(width: 20)
                        }

                        Label {
                            Text("Dernier scan :")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatDate(displayLibrary.library.scannedAt))
                                .fontWeight(.semibold)
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                                .fontWeight(.semibold)
                                .frame(width: 20)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .background(
            MeshGradient(
                width: 3, height: 3,
                points: [ [0, 0], [0.5, 0], [1, 0], [0, 0.5], [0.5, 0.5], [1, 0.5], [0, 1], [0.5, 1], [1, 1] ],
                colors: [ .clear, dominantColor.opacity(0.3), .clear, Color.accentColor.opacity(0.2), dominantColor.opacity(0.3), Color.accentColor.opacity(0.2), .clear, .clear, dominantColor.opacity(0.2) ]
            )
        )
        .cornerRadius(20)
        .animation(.spring(), value: dominantColor)
    }

    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useTB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}
