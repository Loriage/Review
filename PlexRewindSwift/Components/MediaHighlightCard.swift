import SwiftUI

struct MediaHighlightCard: View {
    let title: String
    let subtitle: String
    let secondarySubtitle: String?
    let posterURL: URL?

    var body: some View {
        AsyncImageView(url: posterURL, contentMode: .fit)
            .overlay(
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .black.opacity(0.9),
                        ]),
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title2.bold())
                            .lineLimit(2)

                        Text(subtitle)
                            .font(.headline.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))

                        if let secondary = secondarySubtitle {
                            HStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                Text(secondary)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 2)
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                }
            )
            .aspectRatio(2 / 3, contentMode: .fit)
            .frame(height: 320)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(24)
            .clipped()
            .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
    }
}
