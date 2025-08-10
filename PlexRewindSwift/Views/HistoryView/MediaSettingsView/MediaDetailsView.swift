import SwiftUI

struct MediaDetailsView: View {
    @StateObject var viewModel: MediaDetailsViewModel
    @Environment(\.dismiss) var dismiss
    
    init(ratingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: MediaDetailsViewModel(
            ratingKey: ratingKey,
            plexService: PlexAPIService(),
            serverViewModel: serverViewModel,
            authManager: authManager
        ))
    }

    private var addedAtDateString: String {
        if let addedAt = viewModel.mediaDetails?.addedAt {
            return TimeFormatter.formatTimestamp(addedAt)
        }
        return "N/A"
    }

    private var updatedAtDateString: String {
        if let updatedAt = viewModel.mediaDetails?.updatedAt {
            return TimeFormatter.formatTimestamp(updatedAt)
        }
        return "N/A"
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let info = viewModel.mediaInfo, let part = info.parts.first {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Détails du média")
                                .font(.title2.bold())
                                .padding(.bottom, 10)
                            HStack(spacing: 10) {
                                VStack(alignment: .leading) {
                                    Text("CHEMIN").font(.caption).foregroundColor(.secondary)
                                    HStack {
                                        Text(part.file ?? "Chemin non disponible")
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(12)

                                Button(action: {
                                    UIPasteboard.general.string = part.file
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.title2)
                                }
                            }

                            let columns = [GridItem(.adaptive(minimum: 120))]
                            LazyVGrid(columns: columns, spacing: 12) {
                                InfoPill(title: "DURÉE", value: TimeFormatter.formatFullTime((info.duration ?? 0) / 1000))
                                InfoPill(title: "DÉBIT BINAIRE", value: "\((info.bitrate ?? 0) / 1000) Mbit/s")
                                InfoPill(title: "LARGEUR", value: "\(info.width ?? 0)")
                                InfoPill(title: "HAUTEUR", value: "\(info.height ?? 0)")
                                InfoPill(title: "RATIO D'ASPECT", value: String(format: "%.2f", info.aspectRatio ?? 0))
                                InfoPill(title: "CANAUX AUDIO", value: "\(viewModel.audioStream?.channels ?? 0)")
                                InfoPill(title: "CODEC AUDIO", value: viewModel.mediaInfo?.audioCodec?.uppercased() ?? "N/A")
                                InfoPill(title: "CODEC VIDÉO", value: viewModel.videoStream?.codec?.uppercased() ?? "N/A")
                                InfoPill(title: "RÉSOLUTION VIDÉO", value: info.videoResolution ?? "N/A")
                                InfoPill(title: "CONTENEUR", value: info.container?.uppercased() ?? "N/A")
                                InfoPill(title: "IMAGES PAR SECONDES", value: info.videoFrameRate ?? "N/A")
                                InfoPill(title: "PROFIL VIDÉO", value: info.videoProfile?.uppercased() ?? "N/A")
                                InfoPill(title: "DATE D'AJOUT", value: addedAtDateString)
                                InfoPill(title: "DERNIÈRE MISE À JOUR", value: updatedAtDateString)
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("Impossible de charger les informations.")
                }
            }
            .navigationTitle("Informations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .task {
                await viewModel.loadDetails()
            }
        }
    }
}
