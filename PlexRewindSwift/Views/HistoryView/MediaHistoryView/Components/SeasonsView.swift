import SwiftUI

struct SeasonsView: View {
    @ObservedObject var viewModel: MediaHistoryViewModel
    let showRatingKey: String

    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading) {
            if !viewModel.seasons.isEmpty {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.seasons.sorted(by: { $0.index ?? -1 < $1.index ?? -1 })) { season in
                        NavigationLink(destination: SeasonHistoryView(
                            season: season,
                            showRatingKey: showRatingKey,
                            serverViewModel: serverViewModel,
                            authManager: authManager,
                            statsViewModel: statsViewModel
                        )) {
                            AsyncImageView(url: viewModel.seasonPosterURL(for: season))
                                .aspectRatio(2/3, contentMode: .fill)
                                .overlay(alignment: .bottomLeading) {
                                    Text(season.title)
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .padding([.leading, .trailing, .bottom], 10)
                                        .padding(.top, 30)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: .black.opacity(0.9), location: 0),
                                                    .init(color: .clear, location: 1)
                                                ]),
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                }
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            } else {
                Text("empty.state.no.seasons.message")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
