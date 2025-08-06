import SwiftUI

struct MediaDetailView: View {
    let detail: MediaDetail
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL

    var body: some View {
        NavigationStack {
            ZStack{
                ScrollView(showsIndicators: false) {
                    content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var content: some View {
        VStack(spacing: 25) {
            posterSection
            summarySection
            topUsersSection
        }
        .padding(.horizontal)
        .padding(.bottom, 50)
    }

    private var posterSection: some View {
        VStack(spacing: 5) {
            AsyncImageView(url: detail.posterURL, contentMode: .fit)
                .frame(height: 250)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.25), radius: 5, y: 5)
                .padding(.top, 20)
            
            Text(detail.title)
                .font(.title.bold())
            
            if let tagline = detail.tagline, !tagline.isEmpty {
                Text(tagline)
                    .font(.headline)
            }
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var summarySection: some View {
        if let summary = detail.summary {
            VStack(alignment: .leading, spacing: 8) {
                Text("Résumé")
                    .font(.title2.bold())
                Text(summary)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var topUsersSection: some View {
        if !detail.topUsers.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
                Text("Top Spectateurs")
                    .font(.title2.bold())
                    .padding(.leading)
                
                ForEach(Array(detail.topUsers.enumerated()), id: \.element.id) { index, user in
                    HStack(spacing: 12) {
                        Text("\(index + 1).")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text(user.userName)
                                .fontWeight(.bold)
                            
                            Text("\(user.playCount) lectures • \(user.formattedDuration)")
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
