//
//  HomeView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

struct HomeApp: Codable, Identifiable {
    var id: String { url }
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
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
    
    var fullBannerURL: URL? {
        if let ban = banner {
            return URL(string: "https://ashtemobile.tututweak.com/\(ban)")
        }
        return fullImageURL
    }
}

struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(3))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NBNavigationView("Home") {
                ScrollView {
                    VStack(spacing: 30) {
                        
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
                            .frame(height: 240)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        }
                        
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 15) {
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
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                    }
                    .padding(.top, 10)
                }
                .refreshable {
                    await loadApps()
                }
            }
            .onAppear {
                Task { await loadApps() }
            }
            
            if showNotification, let app = downloadedApp {
                notificationBanner(for: app)
                    .padding(.top, 8)
                    .zIndex(100)
            }
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
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Download Complete")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("now")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("\(app.name) has been downloaded successfully to the Library.")
                    .font(.footnote)
                    .lineLimit(2)
            }

            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(UIColor.systemBackground).opacity(0.95))
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ashte.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
            }
        } catch {
            print("Error loading: \(error)")
        }
    }
}

struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .global).minY
                    let isScrolledDown = minY > 0
                    let height = isScrolledDown ? 220 + minY : 220
                    let offset = isScrolledDown ? -minY : 0

                    ZStack(alignment: .top) {
                        AsyncImage(url: app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.blue.opacity(0.3)
                        }
                        .frame(width: proxy.size.width, height: height)
                        .clipped()
                        .blur(radius: 40)
                        .offset(y: offset)
                        
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.8)))
                            }
                            Spacer()
                            
                            // 👈 لێرەدا شەیرکردنی ڕاستەوخۆی فایلەکەمان گۆڕی بۆ شەیرکردنی تێکست و لینکی کەنال
                            Button(action: {
                                let shareText = "Download \(app.name) from AshteMobile Store!\nhttps://t.me/ashtemmobile"
                                let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                                UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(Color(UIColor.systemBackground).opacity(0.8)))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, safeAreaTop() + 10)
                    }
                }
                .frame(height: 220)
                
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(url: app.fullImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        if let hacks = app.hack, !hacks.isEmpty {
                            Text(hacks[0])
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text(app.category ?? "App")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                            .frame(width: 80, alignment: .leading)
                            .padding(.top, 4)
                    }
                    .padding(.top, 40)
                }
                .padding(.horizontal, 20)
                .offset(y: -55)
                .padding(.bottom, -35)
                
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color(UIColor.systemPurple))
                            .font(.system(size: 13))
                        Text(app.version ?? "1.0")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(UIColor.secondarySystemBackground)))
                    
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 13))
                        Text(app.size ?? "Unknown")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(UIColor.secondarySystemBackground)))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.title3.bold())
                    
                    if let hacks = app.hack, !hacks.isEmpty {
                        ForEach(hacks, id: \.self) { hack in
                            Text("• \(hack)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Download \(app.name) now and enjoy smooth performance and regular updates directly from the AshteMobile Store.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                Divider().padding(.horizontal, 20).padding(.bottom, 16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Information")
                        .font(.title3.bold())
                        .padding(.bottom, 4)
                    
                    AppInfoRow(title: "Source", value: "AshteMobile Repo")
                    AppInfoRow(title: "Developer", value: app.developer ?? "Unknown")
                    AppInfoRow(title: "Size", value: app.size ?? "Unknown")
                    AppInfoRow(title: "Version", value: app.version ?? "1.0")
                    AppInfoRow(title: "Updated", value: "Recently")
                    AppInfoRow(title: "Identifier", value: app.bundle ?? "com.ashte.\(app.name.replacingOccurrences(of: " ", with: "").lowercased())")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }
    
    private func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return window?.safeAreaInsets.top ?? 44
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
            Divider()
        }
    }
}

struct FeaturedAppView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.blue.opacity(0.2)
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .frame(height: 210)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    if let status = app.status {
                        Text(status.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    
                    Text(app.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(app.category ?? "App")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                    .colorScheme(.dark)
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 25)
    }
}

struct HomeAppCardView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
            
            Text(app.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 10))
                Text("4.6")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 6)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .padding(14)
        .frame(width: 130, height: 195)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Follow Us")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 25) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemmobile")
                SocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashtemobile")
                SocialButton(icon: "play.tv.fill", color: .black, url: "https://www.tiktok.com/@ashtemobile")
                SocialButton(icon: "camera.viewfinder", color: .yellow, url: "https://www.snapchat.com/add/ashtemmobile")
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color(UIColor.secondarySystemGroupedBackground)))
        .padding(.horizontal, 20)
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    let url: String
    
    var body: some View {
        Button(action: {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url
        self.onFinished = onFinished
        self.isDownloading = true
        self.progress = 0
        self.isFinished = false
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func stop() {
        downloadTask?.cancel()
        session?.invalidateAndCancel()
        self.isDownloading = false
        self.progress = 0
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            DispatchQueue.main.async {
                self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString)-\(downloadURL?.lastPathComponent ?? "app.ipa")"
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isFinished = true
                self.onFinished?(destinationURL)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isFinished = false
                    }
                }
            }
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
        }
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            DispatchQueue.main.async { self.isDownloading = false }
        }
        session.finishTasksAndInvalidate()
    }
}

struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        ZStack {
            if downloader.isFinished {
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.blue.opacity(0.3), lineWidth: 0.5))
                }
                .disabled(true)
            } else if downloader.isDownloading {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 24, height: 24)
                    
                    if downloader.progress > 0 {
                        Circle()
                            .trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 24, height: 24)
                            .animation(.linear(duration: 0.2), value: downloader.progress)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            downloader.stop()
                        }
                }
                .frame(height: 32)
            } else {
                Button(action: {
                    if let downloadURL = URL(string: app.url) {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        downloader.start(url: downloadURL) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            DispatchQueue.main.async {
                                onDownloadComplete()
                            }
                        }
                    }
                }) {
                    Text("Get")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.08))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.blue.opacity(0.4), lineWidth: 0.5))
                }
                .buttonStyle(.plain) 
            }
        }
        .frame(height: 32)
    }
}
