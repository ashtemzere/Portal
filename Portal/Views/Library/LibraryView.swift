//
//  LibraryView.swift
//  Feather
//

import SwiftUI
import CoreData
import NimbleViews
import UniformTypeIdentifiers

struct LibraryView: View {
    @StateObject var downloadManager = DownloadManager.shared

    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _alertDownloadString: String = ""

    @State private var _selectedTab: Tab = .unsigned
    @Namespace private var _namespace

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

    private var _filteredSignedApps: [Signed] { Array(_signedApps) }
    private var _filteredImportedApps: [Imported] { Array(_importedApps) }

    var body: some View {
        NBNavigationView(.localized("Library")) {
            NBListAdaptable {
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
                            selectedAppUUIDs: .constant([])
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
                            selectedAppUUIDs: .constant([])
                        )
                        .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                    }
                }
            }
            .overlay {
                let isEmpty = (_selectedTab == .signed && _filteredSignedApps.isEmpty)
                           || (_selectedTab == .unsigned && _filteredImportedApps.isEmpty)

                if isEmpty, #available(iOS 17, *) {
                    ContentUnavailableView {
                        Label(.localized("No Apps"), systemImage: "questionmark.app.fill")
                    }
                }
            }
            .toolbar {
                NBToolbarMenu(systemImage: "plus", style: .icon, placement: .topBarTrailing) {
                    Button(.localized("Import from Files"), systemImage: "folder") {
                        _isImportingPresenting = true
                    }
                    Button(.localized("Import from URL"), systemImage: "globe") {
                        _isDownloadingPresenting = true
                    }
                }
            }
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
            .fileImporter(
                isPresented: $_isImportingPresenting,
                allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .archive, .zip],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        let gotAccess = url.startAccessingSecurityScopedResource()
                        if gotAccess {
                            let tempDirectory = FileManager.default.temporaryDirectory
                            let destinationUrl = tempDirectory.appendingPathComponent(url.lastPathComponent)
                            
                            do {
                                if FileManager.default.fileExists(atPath: destinationUrl.path) {
                                    try FileManager.default.removeItem(at: destinationUrl)
                                }
                                try FileManager.default.copyItem(at: url, to: destinationUrl)
                                
                                // کێشەی ئیرۆری 65 لێرەدا چارەسەر کرا بە بەکارهێنانی فەرمانی دروستی پڕۆژەکە
                                _ = downloadManager.startDownload(from: destinationUrl)
                                
                            } catch {
                                print("Copy Error: \(error.localizedDescription)")
                            }
                            
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                case .failure(let error):
                    print("Error importing file: \(error.localizedDescription)")
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
