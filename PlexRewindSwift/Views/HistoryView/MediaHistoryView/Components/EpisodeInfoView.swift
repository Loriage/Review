import SwiftUI

struct EpisodeInfoView: View {
    @ObservedObject var viewModel: EpisodeHistoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let details = viewModel.episodeDetails {
                if let summary = viewModel.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(details.tagline ?? "Resumé")
                            .font(.headline)
                        Text(summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                if let year = details.year {
                    InfoRow(label: "Année de sortie", value: String(year))
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
        .padding(.horizontal)
    }

    private func formatList(_ items: [MetadataItem.Genre]) -> String {
        let maxItems = 8
        let names = items.prefix(maxItems).map { $0.tag }

        return names.joined(separator: ", ")
    }
}
