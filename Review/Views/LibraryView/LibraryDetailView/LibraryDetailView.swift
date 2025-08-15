import SwiftUI

struct LibraryDetailView: View {
    @StateObject private var viewModel: LibraryDetailViewModel

    @ObservedObject var library: DisplayLibrary
    @EnvironmentObject var serverViewModel: ServerViewModel
    @EnvironmentObject var authManager: PlexAuthManager
    @EnvironmentObject var statsViewModel: StatsViewModel

    @State private var showingSettings = false
    @State private var showingRefreshAlert = false
    @State private var showingAnalyzeAlert = false
    @State private var showingEmptyTrashAlert = false
    @State private var navigateToLibrarySettings = false
    @State private var sheetHeight: CGFloat = 250

    init(library: DisplayLibrary, serverViewModel: ServerViewModel, authManager: PlexAuthManager, statsViewModel: StatsViewModel) {
        _viewModel = StateObject(wrappedValue: LibraryDetailViewModel(
            library: library,
            serverViewModel: serverViewModel,
            authManager: authManager,
            statsViewModel: statsViewModel
        ))
        self.library = library
    }

    var body: some View {
        ZStack {
            content
            
            if let hudMessage = viewModel.hudMessage {
                HUDView(hudMessage: hudMessage)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(), value: viewModel.hudMessage)
            }
        }
        .navigationTitle(viewModel.library.library.title)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingSettings, content: settingsSheet)
        .navigationDestination(isPresented: $navigateToLibrarySettings, destination: librarySettingsView)
        .alerts(
            showingRefreshAlert: $showingRefreshAlert,
            showingAnalyzeAlert: $showingAnalyzeAlert,
            showingEmptyTrashAlert: $showingEmptyTrashAlert,
            viewModel: viewModel
        )
        .task { await viewModel.loadInitialContent() }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                LibraryHeaderView(viewModel: viewModel, library: library)
                
                switch viewModel.state {
                case .loading:
                    ProgressView().padding(.top, 40)
                case .content:
                    MediaGridView(viewModel: viewModel)
                case .error(let message):
                    Text(message).foregroundColor(.red).padding()
                }
            }
            .padding(.horizontal)
        }
    }

    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
            }
        }
    }
    
    private func settingsSheet() -> some View {
        LibrarySettingsSheet(
            viewModel: viewModel,
            showingSettings: $showingSettings,
            navigateToLibrarySettings: $navigateToLibrarySettings,
            showingRefreshAlert: $showingRefreshAlert,
            showingAnalyzeAlert: $showingAnalyzeAlert,
            showingEmptyTrashAlert: $showingEmptyTrashAlert
        )
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .onAppear { sheetHeight = 260 }
    }
    
    private func librarySettingsView() -> some View {
        LibrarySettingsView(library: library, serverViewModel: serverViewModel, authManager: authManager)
    }
}

private extension View {
    func alerts(
        showingRefreshAlert: Binding<Bool>,
        showingAnalyzeAlert: Binding<Bool>,
        showingEmptyTrashAlert: Binding<Bool>,
        viewModel: LibraryDetailViewModel
    ) -> some View {
        self
        .alert("library.detail.refresh.alert.title", isPresented: showingRefreshAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("library.settings.sheet.refresh", role: .destructive) { Task { await viewModel.refreshMetadata() } }
        } message: {
            Text("library.detail.refresh.alert.message")
        }
        .alert("library.detail.analyze.alert.title", isPresented: showingAnalyzeAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("activity.settings.analyze", role: .destructive) { Task { await viewModel.analyzeLibrary() } }
        } message: {
            Text("library.detail.analyze.alert.message")
        }
        .alert("library.detail.empty.trash.alert.title", isPresented: showingEmptyTrashAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("library.settings.sheet.empty.trash", role: .destructive) { Task { await viewModel.emptyTrash() } }
        } message: {
            Text("library.detail.empty.trash.alert.message")
        }
    }
}
