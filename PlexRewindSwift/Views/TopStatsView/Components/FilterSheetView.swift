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
                Section(header: Text("filter.sheet.filters")) {
                    Picker("filter.sheet.user", selection: $selectedUserID) {
                        Text("filter.user.all").tag(Int?.none)
                        ForEach(serverViewModel.availableUsers) { user in
                            Text(user.title).tag(user.id as Int?)
                        }
                    }
                    
                    Picker("filter.sheet.period", selection: $selectedTimeFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                }
                
                Section(header: Text("filter.sheet.sort")) {
                    Picker("filter.sheet.sort.by", selection: $sortOption) {
                        ForEach(TopStatsSortOption.allCases) { option in
                            Text(LocalizedStringKey(option.displayName)).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("filter.sheet.title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
