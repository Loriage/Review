import SwiftUI

struct SectionHeader: View {
    let title: String
    let fullList: [TopMedia]
    let items: [TopMedia]

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title)).font(.headline)
            Spacer()
            if fullList.count > items.count {
                NavigationLink(destination: TopMediaDetailView(title: title, items: fullList)) {
                    Text("common.see.more").font(.subheadline)
                }
            }
        }
    }
}
