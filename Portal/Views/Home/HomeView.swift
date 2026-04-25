import SwiftUI
import NimbleViews

struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [AshteApp] = []
    @State private var isLoading = false
    
    var featuredApps: [AshteApp] {
        Array(apps.filter { $0.status != nil }.prefix(5))
    }
    
    var groupedApps: [(String, [AshteApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NBNavigationView("Home") {
            ScrollView {
                if isLoading {
                    ProgressView().padding(.top, 40)
                } else {
                    VStack(spacing: 25) {
                        // Banner Section
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: AshteAppDetailView(app: app, downloadManager: downloadManager, onDownloadComplete: {})) {
                                        FeaturedCard(app: app)
                                    }.buttonStyle(.plain)
                                }
                            }
                            .frame(height: 200)
                            .tabViewStyle(PageTabViewStyle())
                        }

                        // Categories Section
                        ForEach(groupedApps, id: \.0) { category, categoryApps in
                            VStack(alignment: .leading) {
                                Text(category).font(.title3.bold()).padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(categoryApps) { app in
                                            NavigationLink(destination: AshteAppDetailView(app: app, downloadManager: downloadManager, onDownloadComplete: {})) {
                                                AppCard(app: app)
                                            }.buttonStyle(.plain)
                                        }
                                    }.padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable { await loadData() }
        }
        .onAppear { Task { await loadData() } }
    }
    
    func loadData() async {
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
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}

// پێکهاتە لاوەکییەکان بۆ ڕێگری لە ئێرۆر
struct FeaturedCard: View {
    let app: AshteApp
    var body: some View {
        AsyncImage(url: app.fullImageURL) { img in
            img.resizable().aspectRatio(contentMode: .fill)
        } placeholder: { Color.blue.opacity(0.2) }
        .frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 20)).padding(.horizontal)
    }
}

struct AppCard: View {
    let app: AshteApp
    var body: some View {
        VStack {
            AsyncImage(url: app.fullImageURL) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.gray.opacity(0.2) }
            .frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 18))
            Text(app.name).font(.caption.bold()).lineLimit(1).frame(width: 80)
        }
    }
}
