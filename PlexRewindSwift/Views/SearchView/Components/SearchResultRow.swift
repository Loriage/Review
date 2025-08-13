import SwiftUI

struct SearchResultRow: View {
    let result: SearchResult
    let posterURL: URL?

    var body: some View {
        HStack(spacing: 15) {
            AsyncImageView(url: posterURL, contentMode: .fill)
                .frame(width: 60, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.type == "episode" ? result.grandparentTitle ?? result.title : result.title)
                    .font(.headline)

                if result.type == "episode" {
                    Text(result.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let season = result.parentIndex, let episode = result.index {
                        Text("S\(season) - E\(episode)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 0) {
                        Text(PlexMediaTypeHelper.formattedTypeNameSingular(for: result.type).capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let year = result.year {
                            Text(" (\(String(year)))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                if let leafCount = result.leafCount, result.type == "show" {
                    Text("\(leafCount) épisodes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }
}
