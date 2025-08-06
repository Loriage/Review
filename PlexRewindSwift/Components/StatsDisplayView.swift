import SwiftUI

struct StatsDisplayView: View {
    @EnvironmentObject var viewModel: PlexMonitorViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    let stats: UserStats

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {

                VStack(alignment: .leading, spacing: 12) {
                    Text("Votre année en chiffres")
                        .font(.title2.bold())

                    HStack(spacing: 12) {
                        StatPill(
                            title: "Temps total",
                            value: stats.formattedTotalWatchTime,
                            icon: "hourglass",
                            color: .orange
                        )
                        StatPill(
                            title: "Films",
                            value: "\(stats.totalMovies)",
                            icon: "film.fill",
                            color: .blue
                        )
                        StatPill(
                            title: "Épisodes",
                            value: "\(stats.totalEpisodes)",
                            icon: "tv.fill",
                            color: .green
                        )
                    }
                }

                if !stats.rankedMovies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Films les plus regardés")
                            .font(.title2.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(stats.rankedMovies) { movie in
                                    MediaHighlightCard(
                                        title: movie.title,
                                        subtitle: movie.subtitle,
                                        secondarySubtitle: movie.secondarySubtitle,
                                        posterURL: movie.posterURL
                                    )
                                    .onTapGesture {
                                        Task {
                                            await viewModel.selectMedia(
                                                for: movie.id,
                                                authManager: authManager
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 15)
                        }
                        .padding(.horizontal, -10)
                    }
                }

                if !stats.rankedShows.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Séries les plus regardées")
                            .font(.title2.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(stats.rankedShows) { show in
                                    MediaHighlightCard(
                                        title: show.title,
                                        subtitle: show.subtitle,
                                        secondarySubtitle: show.secondarySubtitle,
                                        posterURL: show.posterURL
                                    )
                                    .onTapGesture {
                                        Task {
                                            await viewModel.selectMedia(
                                                for: show.id,
                                                authManager: authManager
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 15)
                        }
                        .padding(.horizontal, -10)
                    }
                }
            }
            .padding(.vertical)
        }
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(item: $viewModel.selectedMediaDetail) { detail in
            MediaDetailView(detail: detail)
        }
    }
}
