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
                                        Text("media.detail.path").font(.caption).foregroundColor(.secondary)
                                        HStack {
                                            Text(part.file ?? "media.detail.path.unavailable")
                                                .font(.headline.weight(.semibold))
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
                                    InfoPill(title: "media.detail.duration", value: TimeFormatter.formatFullTime((info.duration ?? 0) / 1000), customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.debit", value: "\((info.bitrate ?? 0) / 1000) Mbit/s", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.width", value: "\(info.width ?? 0)", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.height", value: "\(info.height ?? 0)", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.aspectratio", value: String(format: "%.2f", info.aspectRatio ?? 0), customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.audio.channels", value: "\(viewModel.audioStream?.channels ?? 0)", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.audio.codec", value: viewModel.mediaInfo?.audioCodec?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.video.codec", value: viewModel.videoStream?.codec?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.video.resolution", value: info.videoResolution ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.container", value: info.container?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.fps", value: info.videoFrameRate ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.video.profile", value: info.videoProfile?.uppercased() ?? "N/A", customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.date.added", value: addedAtDateString, customBackgroundMaterial: .thin)
                                    InfoPill(title: "media.detail.date.updated", value: updatedAtDateString, customBackgroundMaterial: .thin)
                                }
                            }
                            .padding()
                        }
                    } else {
                        Text("media.data.unavailable")
                    }
                }
                if showCopyHUD {
                    HUDView(hudMessage: HUDMessage(iconName: "doc.on.doc.fill", text: "hud.copied", maxWidth: 180))
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .navigationTitle("activity.settings.media.details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
            .task {
                await viewModel.loadDetails()
            }
        }
    }
}
