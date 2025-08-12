import SwiftUI

struct SearchableItem: Identifiable {
    let id = UUID()
    let name: String
}

struct SearchView: View {
    @State private var searchText = ""

    private var allItems = [
        SearchableItem(name: "Superstore"),
        SearchableItem(name: "Breaking Bad"),
        SearchableItem(name: "Stranger Things"),
        SearchableItem(name: "The Office"),
        SearchableItem(name: "Loriage")
    ]
    
    var filteredItems: [SearchableItem] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { $0.name.localizedStandardContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    Text(item.name)
                }
            }
            .navigationTitle("Recherche")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
    }
}
