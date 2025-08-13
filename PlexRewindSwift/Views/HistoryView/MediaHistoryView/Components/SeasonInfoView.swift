import SwiftUI

struct SeasonInfoView: View {
    @ObservedObject var viewModel: SeasonHistoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let details = viewModel.seasonDetails {
                if let summary = details.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if let tagline = details.tagline, !tagline.isEmpty {
                            Text(tagline)
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
                    InfoRow(label: "Studio", value: studio)
                }
                if let genres = details.genre, !genres.isEmpty {
                    InfoRow(label: "Genres", value: formatList(genres))
                }
                if let directors = details.director, !directors.isEmpty {
                    InfoRow(label: "Réalisé par", value: formatList(directors))
                }
                if let writers = details.writer, !writers.isEmpty {
                    InfoRow(label: "Écrit par", value: formatList(writers))
                }
                if let cast = details.role, !cast.isEmpty {
                    InfoRow(label: "Avec", value: formatList(cast))
                }
            } else {
                Text("Informations non disponibles.")
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
