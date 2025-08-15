import SwiftUI

struct SeasonInfoView: View {
    @ObservedObject var viewModel: SeasonHistoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let details = viewModel.seasonDetails {
                if let summary = details.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if let details = details.tagline {
                            Text(details)
                                .font(.headline)
                        } else {
                            Text("media.info.summary")
                                .font(.headline)
                        }
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                if let studio = details.studio, !studio.isEmpty {
                    InfoRow(label: "media.info.studio", value: studio)
                }
                if let genres = details.genre, !genres.isEmpty {
                    InfoRow(label: "media.info.genres", value: formatList(genres))
                }
                if let directors = details.director, !directors.isEmpty {
                    InfoRow(label: "media.info.directed.by", value: formatList(directors))
                }
                if let writers = details.writer, !writers.isEmpty {
                    InfoRow(label: "media.info.written.by", value: formatList(writers))
                }
                if let cast = details.role, !cast.isEmpty {
                    InfoRow(label: "media.info.with", value: formatList(cast))
                }
            } else {
                Text("media.info.not.available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatList(_ items: [MetadataItem.Genre]) -> String {
        let maxItems = 8
        let names = items.prefix(maxItems).map { $0.tag }

        return names.joined(separator: ", ")
    }
}
