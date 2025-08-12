import SwiftUI

struct TopMediaDetailView: View {
    let title: String
    @State var items: [TopMedia]
    @State private var sortOption: TopStatsSortOption = .byPlays
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    var body: some View {
        List {
            ForEach(items) { media in
                NavigationLink(destination: MediaHistoryView(
                    ratingKey: media.id,
                    mediaType: media.mediaType,
                    grandparentRatingKey: media.mediaType == "show" ? media.id : nil,
                    serverViewModel: serverViewModel,
                    authManager: authManager,
                    statsViewModel: statsViewModel
                )) {
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
                                if let lastViewed = media.lastViewedAt {
                                    Text("Dernier visionnage: \(lastViewed.formatted(.relative(presentation: .named)))")
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Trier par", selection: $sortOption) {
                        ForEach(TopStatsSortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } label: {
                    Label("Trier", systemImage: "arrow.up.arrow.down.circle")
                }
            }
        }
        .onChange(of: sortOption) {
            sortItems()
        }
    }
    
    private func sortItems() {
        if sortOption == .byPlays {
            items.sort { $0.viewCount > $1.viewCount }
        } else {
            items.sort { $0.totalWatchTimeSeconds > $1.totalWatchTimeSeconds }
        }
    }
}
