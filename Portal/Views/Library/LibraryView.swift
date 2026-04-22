//
//  LibraryView.swift
//  Feather
//

import SwiftUI
import CoreData
import NimbleViews

struct LibraryView: View {
    @StateObject var downloadManager = DownloadManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _alertDownloadString: String = ""
    
    // MARK: Selection State
    @State private var _selectedAppUUIDs: Set<String> = []
    @State private var _editMode: EditMode = .inactive
    @State private var _searchText = ""
    
    // شێوازی تابی نوێ لەبری Scope
    @State private var _selectedTab: Tab = .unsigned
    @Namespace private var _namespace
    
    private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
        apps.filter {
            _searchText.isEmpty ||
                (($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var _filteredSignedApps: [Signed] { filteredAndSortedApps(from: _signedApps) }
    private var _filteredImportedApps: [Imported] { filteredAndSortedApps(from: _importedApps) }
    
    // MARK: Fetch
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .snappy
    ) private var _importedApps: FetchedResults<Imported>
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Library")) {
            NBListAdaptable {
                // دوگمەی سەرەوە (Unsigned / Signed)
                Picker("", selection: $_selectedTab) {
                    Text(Tab.unsigned.displayName).tag(Tab.unsigned)
                    Text(Tab.signed.displayName).tag(Tab.signed)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                switch _selectedTab {
                case .signed:
                    ForEach(_filteredSignedApps, id: \.uuid) { app in
                        LibraryCellView(
                            app: app,
                            selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                            selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                            selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                            selectedAppUUIDs: $_selectedAppUUIDs
                        )
                        .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                    }

                case .unsigned:
                    ForEach(_filteredImportedApps, id: \.uuid) { app in
                        LibraryCellView(
                            app: app,
                            selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                            selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                            selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                            selectedAppUUIDs: $_selectedAppUUIDs
                        )
                        .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                    }
                }
            }
            .searchable(text: $_searchText, placement: .platform())
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                let isEmpty = (_selectedTab == .signed && _filteredSignedApps.isEmpty)
                           || (_selectedTab == .unsigned && _filteredImportedApps.isEmpty)

                if isEmpty, #available(iOS 17, *) {
                    ContentUnavailableView {
                        Label(.localized("No Apps"), systemImage: "questionmark.app.fill")
                    } description: {
                        Text(.localized("Get started by importing your first IPA file."))
                    } actions: {
                        Menu {
                            _importActions()
                        } label: {
                            NBButton(.localized("Import"), style: .text)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                
                if _editMode.isEditing {
                    NBToolbarButton(
                        .localized("Delete"),
                        systemImage: "trash",
                        isDisabled: _selectedAppUUIDs.isEmpty
                    ) {
                        _bulkDeleteSelectedApps()
                    }
                } else {
                    NBToolbarMenu(
                        systemImage: "plus",
                        style: .icon,
                        placement: .topBarTrailing
                    ) {
                        _importActions()
                    }
                }
            }
            .environment(\.editMode, $_editMode)
            .sheet(item: $_selectedInfoAppPresenting) { app in
                LibraryInfoView(app: app.base)
            }
            .sheet(item: $_selectedInstallAppPresenting) { app in
                InstallPreviewView(app: app.base, isSharing: app.archive)
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $_selectedSigningAppPresenting) { app in
                SigningView(app: app.base)
                    .compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
            }
            // فەرمانە ئەسڵییەکانی پڕۆژەکەی خۆت بۆ هێنانی فایل
            .sheet(isPresented: $_isImportingPresenting) {
                FileImporterRepresentableView(
                    allowedContentTypes:  [.ipa, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        guard !urls.isEmpty else { return }
                        
                        for url in urls {
                            let id = "FeatherManualDownload_\(UUID().uuidString)"
                            let dl = downloadManager.startArchive(from: url, id: id)
                            try? downloadManager.handlePachageFile(url: url, dl: dl)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            // بەشی داگرتن لە ڕێگەی لینکەوە
            .alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
                TextField(.localized("URL"), text: $_alertDownloadString)
                    .textInputAutocapitalization(.never)
                Button(.localized("Cancel"), role: .cancel) {
                    _alertDownloadString = ""
                }
                Button(.localized("OK")) {
                    if let url = URL(string: _alertDownloadString) {
                        _ = downloadManager.startDownload(from: url, id: "FeatherManualDownload_\(UUID().uuidString)")
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
                if let latest = _signedApps.first {
                    _selectedInstallAppPresenting = AnyApp(base: latest)
                }
            }
            .onChange(of: _editMode) { mode in
                if mode == .inactive {
                    _selectedAppUUIDs.removeAll()
                }
            }
        }
    }
    
    enum Tab {
        case unsigned
        case signed

        var displayName: String {
            switch self {
            case .unsigned: return .localized("Unsigned")
            case .signed: return .localized("Signed")
            }
        }
    }
}

// MARK: - Extension: View
extension LibraryView {
    @ViewBuilder
    private func _importActions() -> some View {
        Button(.localized("Import from Files"), systemImage: "folder") {
            _isImportingPresenting = true
        }
        Button(.localized("Import from URL"), systemImage: "globe") {
            _isDownloadingPresenting = true
        }
    }
}

// MARK: - Extension: Bulk Delete
extension LibraryView {
    private func _bulkDeleteSelectedApps() {
        let selectedApps = _getAllApps().filter { app in
            guard let uuid = app.uuid else { return false }
            return _selectedAppUUIDs.contains(uuid)
        }
        
        for app in selectedApps {
            Storage.shared.deleteApp(for: app)
        }
        
        _selectedAppUUIDs.removeAll()
    }
    
    private func _getAllApps() -> [AppInfoPresentable] {
        var allApps: [AppInfoPresentable] = []
        
        if _selectedTab == .signed {
            allApps.append(contentsOf: _filteredSignedApps)
        } else {
            allApps.append(contentsOf: _filteredImportedApps)
        }
        
        return allApps
    }
}
