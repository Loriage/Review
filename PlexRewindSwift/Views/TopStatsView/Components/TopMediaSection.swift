import SwiftUI

struct TopMediaSection: View {
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    let title: String
    let items: [TopMedia]
    let fullList: [TopMedia]

    var body: some View {
        Section {
            ForEach(items) { media in
                NavigationLink(destination: MediaHistoryView(
                    ratingKey: media.id,
                    mediaType: media.mediaType,
                    grandparentRatingKey: media.mediaType == "show" ? media.id : nil,
                    serverViewModel: serverViewModel,
                    authManager: authManager,
                    statsViewModel: statsViewModel
                )) {
                    TopMediaRow(media: media)
                }
            }
        } header: {
            SectionHeader(title: title, fullList: fullList, items: items)
        }
    }
}
