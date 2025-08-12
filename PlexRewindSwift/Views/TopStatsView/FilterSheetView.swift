import SwiftUI

struct FilterSheetView: View {
    @Binding var selectedUserID: Int?
    @Binding var selectedTimeFilter: TimeFilter
    @Binding var sortOption: TopStatsSortOption
    
    @EnvironmentObject var serverViewModel: ServerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Filtres")) {
                    Picker("Utilisateur", selection: $selectedUserID) {
                        Text("Tous les utilisateurs").tag(Int?.none)
                        ForEach(serverViewModel.availableUsers) { user in
                            Text(user.title).tag(user.id as Int?)
                        }
                    }
                    
                    Picker("Période", selection: $selectedTimeFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                }
                
                Section(header: Text("Tri")) {
                    Picker("Trier par", selection: $sortOption) {
                        ForEach(TopStatsSortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Filtres et Tri")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
