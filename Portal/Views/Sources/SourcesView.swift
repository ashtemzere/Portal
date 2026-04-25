import SwiftUI
import NimbleViews
import Foundation

// ئەگەر ئەم مۆدێلە لە شوێنێکی تری پرۆژەکەت هەیە، تەنها یەک دانەیان بهێڵەرەوە
struct AshteApp: Codable, Identifiable {
    var id: String { bundle ?? url }
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String
    let status: String?
    let banner: String?
    let hack: [String]?

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        return img.contains("http") ? URL(string: img) : URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
}

struct SourcesView: View {
    @StateObject var downloadManager = DownloadManager.shared 
    @State private var apps: [AshteApp] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedFilter = "ALL"
    
    private var filteredApps: [AshteApp] {
        var result = apps
        if selectedFilter == "APP" {
            result = result.filter { ($0.category ?? "").localizedCaseInsensitiveContains("App") }
        } else if selectedFilter == "GAMES" {
            result = result.filter { ($0.category ?? "").localizedCaseInsensitiveContains("Game") }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
    
    var body: some View {
        NBNavigationView("Store") {
            NBListAdaptable {
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag("ALL")
                    Text("Apps").tag("APP")
                    Text("Games").tag("GAMES")
                }.pickerStyle(.segmented).padding()

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding()
                } else {
                    ForEach(filteredApps) { app in
                        NavigationLink(destination: AshteAppDetailView(app: app, downloadManager: downloadManager, onDownloadComplete: {})) {
                            HStack(spacing: 15) {
                                AsyncImage(url: app.fullImageURL) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: { Color.gray.opacity(0.2) }
                                .frame(width: 55, height: 55).clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading) {
                                    Text(app.name).font(.headline)
                                    Text(app.version ?? "1.0").font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("GET").bold().padding(.horizontal, 15).padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1)).foregroundColor(.blue).clipShape(Capsule())
                            }
                        }.buttonStyle(.plain)
                    }
                }
            }
            .refreshable { await loadApps() }
            .searchable(text: $searchText)
        }
        .onAppear { Task { await loadApps() } }
    }
    
    func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([AshteApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
                self.isLoading = false
            }
        } catch {
            print("Error: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}
