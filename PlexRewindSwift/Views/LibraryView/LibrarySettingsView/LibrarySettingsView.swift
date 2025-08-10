import SwiftUI

struct LibrarySettingsView: View {
    @StateObject private var viewModel: LibrarySettingsViewModel
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @FocusState private var isTitleFieldFocused: Bool

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager) {
        _viewModel = StateObject(wrappedValue: LibrarySettingsViewModel(library: library, serverViewModel: serverViewModel, authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Informations de la bibliothèque")) {
                        HStack {
                            Text("ID :")
                            Text(viewModel.library.library.key)
                                .font(.body.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }

                    Section(
                        header: Text("Visibilité"),
                        footer: Text("Restreindre où le contenu de cette bibliothèque doit apparaître.")
                    ) {
                        Picker("Visibilité", selection: $viewModel.visibility) {
                            ForEach(LibraryVisibility.allCases) { visibility in
                                Text(visibility.description).tag(visibility)
                            }
                        }
                    }
                    Section(
                        header: Text("Options de lecture"),
                        footer: Text("Autoriser les bandes annonces à être jouées avant les objets de cette bibliothèque.").textCase(nil)
                    ) {
                        Toggle("Activer les bandes annonces", isOn: $viewModel.enableTrailers)
                    }
                }
                if let hudMessage = viewModel.hudMessage {
                    HUDView(hudMessage: hudMessage)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: viewModel.hudMessage)
                }
            }
            .navigationTitle("Réglages de la bibliothèque")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.hasChanges {
                        Button("Sauvegarder") {
                            isTitleFieldFocused = false
                            Task {
                                await viewModel.saveChanges()
                            }
                        }
                    }
                }
            }
        }
    }
}
