import SwiftUI

struct TopMediaRow: View {
    let media: TopMedia

    var body: some View {
        HStack(spacing: 15) {
            AsyncImageView(url: media.posterURL, contentMode: .fill)
                .frame(width: 60, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(media.title)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lectures: \(media.viewCount)")
                    Text("Durée: \(media.formattedWatchTime)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct TopMediaRowWithDetails: View {
    let media: TopMedia
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImageView(url: media.posterURL, contentMode: .fill)
                .frame(width: 60, height: 90)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(media.title)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nombre de lectures : \(media.viewCount)")
                    Text("Durée de visionnage : \(media.formattedWatchTime)")
                    if let lastViewed = media.lastViewedAt {
                        Text("Dernière lecture : \(lastViewed.formatted(.relative(presentation: .named)))")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}
