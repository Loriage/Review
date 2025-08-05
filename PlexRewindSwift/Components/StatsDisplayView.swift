import SwiftUI

struct StatsDisplayView: View {
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
                                        posterURL: movie.posterURL
                                    )
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
                                        posterURL: show.posterURL
                                    )
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
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2.weight(.medium))
                .foregroundColor(color)
            
            VStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
