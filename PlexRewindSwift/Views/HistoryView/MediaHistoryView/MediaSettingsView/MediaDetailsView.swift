import SwiftUI

struct MediaDetailsView: View {
    @StateObject var viewModel: MediaDetailsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showCopyHUD = false
    
    init(ratingKey: String, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: MediaDetailsViewModel(
            ratingKey: ratingKey,
            metadataService: PlexMetadataService(),
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
            ZStack {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if let info = viewModel.mediaInfo, let part = info.parts.first {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
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
                                        withAnimation {
                                            showCopyHUD = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            withAnimation {
                                                showCopyHUD = false
                                            }
                                        }
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.title2)
                                    }
                                }
                                
                                let columns = [GridItem(.adaptive(minimum: 120))]
                                LazyVGrid(columns: columns, spacing: 12) {
                                    InfoPill(title: "DURÉE", value: TimeFormatter.formatFullTime((info.duration ?? 0) / 1000), customBackgroundMaterial: .thin)
                                    InfoPill(title: "DÉBIT BINAIRE", value: "\((info.bitrate ?? 0) / 1000) Mbit/s", customBackgroundMaterial: .thin)
                                    InfoPill(title: "LARGEUR", value: "\(info.width ?? 0)", customBackgroundMaterial: .thin)
                                    InfoPill(title: "HAUTEUR", value: "\(info.height ?? 0)", customBackgroundMaterial: .thin)
                                    InfoPill(title: "RATIO D'ASPECT", value: String(format: "%.2f", info.aspectRatio ?? 0), customBackgroundMaterial: .thin)
                                    InfoPill(title: "CANAUX AUDIO", value: "\(viewModel.audioStream?.channels ?? 0)", customBackgroundMaterial: .thin)
                                    InfoPill(title: "CODEC AUDIO", value: viewModel.mediaInfo?.audioCodec?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "CODEC VIDÉO", value: viewModel.videoStream?.codec?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "RÉSOLUTION VIDÉO", value: info.videoResolution ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "CONTENEUR", value: info.container?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "IMAGES PAR SECONDES", value: info.videoFrameRate ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "PROFIL VIDÉO", value: info.videoProfile?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "DATE D'AJOUT", value: addedAtDateString, customBackgroundMaterial: .thin)
                                    InfoPill(title: "DERNIÈRE MISE À JOUR", value: updatedAtDateString, customBackgroundMaterial: .thin)
                                }
                            }
                            .padding()
                        }
                    } else {
                        Text("Impossible de charger les informations.")
                    }
                }
                if showCopyHUD {
                    HUDView(hudMessage: HUDMessage(iconName: "doc.on.doc.fill", text: "Copié !", maxWidth: 180))
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("Détails du média")
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
