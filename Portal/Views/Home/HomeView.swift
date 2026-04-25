import SwiftUI
import NimbleViews
import Foundation
import UIKit

// ١. مۆدێلی داتا بۆ Home
struct HomeApp: Codable, Identifiable {
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
        if img.contains("http") { return URL(string: img) }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
    
    var fullBannerURL: URL? {
        if let ban = banner {
            if ban.contains("http") { return URL(string: ban) }
            return URL(string: "https://ashtemobile.tututweak.com/\(ban)")
        }
        return fullImageURL
    }
}

struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    @State private var isLoading = false
    
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    // فلتەرکردنی ئەو بەرنامانەی کە دەتەوێت لە سەرەوە (Banner) دەرکەون
    var featuredApps: [HomeApp] {
        let featured = apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }
        return Array(featured.prefix(5))
    }
    
    // گرووپکردنی بەرنامەکان بەپێی بەشەکان (Category)
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NBNavigationView("Ashte Store") {
                ScrollView {
                    VStack(spacing: 25) {
                        
                        if isLoading {
                            ProgressView().padding(.top, 50)
                        } else {
                            // بەشی Banner - تەنها ئەوانە پیشان دەدات کە Status-یان هەیە
                            if !featuredApps.isEmpty {
                                TabView {
                                    ForEach(featuredApps) { app in
                                        NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }) {
                                            FeaturedAppView(app: app, downloadManager: downloadManager) {
                                                showDownloadNotification(for: app)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(height: 220)
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            }
                            
                            // لیستی بەشەکان بە شێوەی ئاسۆیی (Horizontal)
                            VStack(alignment: .leading, spacing: 25) {
                                ForEach(groupedApps, id: \.0) { category, categoryApps in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(category)
                                            .font(.title3.bold())
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            LazyHStack(spacing: 16) {
                                                ForEach(categoryApps) { app in
                                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }) {
                                                        HomeAppCardView(app: app, downloadManager: downloadManager) {
                                                            showDownloadNotification(for: app)
                                                        }
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                    }
                }
                .refreshable {
                    await loadApps()
                }
            }
            .onAppear {
                if apps.isEmpty {
                    Task { await loadApps() }
                }
            }
            
            if showNotification, let app = downloadedApp {
                notificationBanner(for: app)
                    .padding(.top, 8)
                    .zIndex(100)
            }
        }
    }
    
    // هێنانی داتا لە ipa.json
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
                self.isLoading = false
            }
        } catch {
            print("Error loading Home apps: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }

    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            self.showNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeOut) {
                self.showNotification = false
            }
        }
    }
    
    @ViewBuilder
    private func notificationBanner(for app: HomeApp) -> some View {
        // ... (هەمان کۆدی NotificationBanner کە پێشتر هەبوو)
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.black }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("Success").font(.caption.bold()).foregroundColor(.blue)
                Text("\(app.name) downloaded!").font(.footnote)
            }
            Spacer()
        }
        .padding()
        .background(BlurView(style: .systemMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}
