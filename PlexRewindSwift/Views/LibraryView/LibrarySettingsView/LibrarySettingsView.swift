import SwiftUI

struct LibrarySettingsView: View {
    @StateObject private var viewModel: LibrarySettingsViewModel

    init(libraryID: String) {
        _viewModel = StateObject(wrappedValue: LibrarySettingsViewModel(libraryID: libraryID))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations de la bibliothèque")) {
                    Text("ID de la bibliothèque :")
                    Text(viewModel.libraryID)
                        .font(.body.monospaced())
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Réglages de la bibliothèque")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
