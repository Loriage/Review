import SwiftUI

struct TopMediaDetailView: View {
    let title: String
    private let originalItems: [TopMedia]
    @State private var displayedItems: [TopMedia]

    @State private var sortOption: TopStatsSortOption = .byPlays
    @State private var selectedUserID: Int?
    @State private var selectedTimeFilter: TimeFilter = .allTime
    
    @State private var isShowingFilterSheet = false
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    init(title: String, items: [TopMedia]) {
        self.title = title
        self.originalItems = items
        self._displayedItems = State(initialValue: items)
    }

    var body: some View {
        List {
            ForEach(displayedItems) { media in
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
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingFilterSheet = true }) {
                    Label("Filtres", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $isShowingFilterSheet) {
            FilterSheetView(
                selectedUserID: $selectedUserID,
                selectedTimeFilter: $selectedTimeFilter,
                sortOption: $sortOption
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: sortOption) { applyFiltersAndSort() }
        .onChange(of: selectedUserID) { applyFiltersAndSort() }
        .onChange(of: selectedTimeFilter) { applyFiltersAndSort() }
        .onAppear(perform: applyFiltersAndSort)
    }
    
    private func getStartDate(for filter: TimeFilter) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        switch filter {
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        case .year:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        case .allTime:
            return nil
        }
    }
    
    private func applyFiltersAndSort() {
        var processedItems = self.originalItems

        if let userID = selectedUserID {
            processedItems = processedItems.compactMap { media -> TopMedia? in
                let userSessions = media.sessions.filter { $0.accountID == userID }
                if userSessions.isEmpty { return nil }

                let totalDuration = userSessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                let lastViewed = userSessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) }

                return TopMedia(
                    id: media.id,
                    title: media.title,
                    mediaType: media.mediaType,
                    viewCount: userSessions.count,
                    totalWatchTimeSeconds: totalDuration,
                    lastViewedAt: lastViewed,
                    posterURL: media.posterURL,
                    sessions: userSessions
                )
            }
        }
        
        if let startDate = getStartDate(for: selectedTimeFilter) {
            processedItems = processedItems.compactMap { media -> TopMedia? in
                 let timeFilteredSessions = media.sessions.filter { session in
                    guard let viewedAt = session.viewedAt else { return false }
                    return Date(timeIntervalSince1970: viewedAt) >= startDate
                }
                if timeFilteredSessions.isEmpty { return nil }

                let totalDuration = timeFilteredSessions.reduce(0) { $0 + (($1.duration ?? 0) / 1000) }
                let lastViewed = timeFilteredSessions.max(by: { ($0.viewedAt ?? 0) < ($1.viewedAt ?? 0) })?.viewedAt.map { Date(timeIntervalSince1970: $0) }

                 return TopMedia(
                    id: media.id,
                    title: media.title,
                    mediaType: media.mediaType,
                    viewCount: timeFilteredSessions.count,
                    totalWatchTimeSeconds: totalDuration,
                    lastViewedAt: lastViewed,
                    posterURL: media.posterURL,
                    sessions: timeFilteredSessions
                )
            }
        }

        if sortOption == .byPlays {
            processedItems.sort { $0.viewCount > $1.viewCount }
        } else {
            processedItems.sort { $0.totalWatchTimeSeconds > $1.totalWatchTimeSeconds }
        }

        self.displayedItems = processedItems
    }
}
