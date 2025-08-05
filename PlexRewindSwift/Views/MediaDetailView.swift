import SwiftUI

struct MediaDetailView: View {
    let detail: MediaDetail
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AsyncImageView(url: detail.posterURL, contentMode: .fit)
                        .aspectRatio(2 / 3, contentMode: .fit)
                        .frame(height: 350)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                        .frame(maxWidth: .infinity)

                    Text("Top Spectateurs")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    if detail.topUsers.isEmpty {
                        Text("Aucune donnée de spectateur disponible.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(
                                Array(detail.topUsers.enumerated()),
                                id: \.element.id
                            ) { index, user in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.headline)
                                        .frame(width: 30)

                                    VStack(alignment: .leading) {
                                        Text(user.userName)
                                            .fontWeight(.bold)
                                        Text(
                                            "\(user.playCount) lectures • \(user.formattedDuration)"
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle(detail.title)
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
}
