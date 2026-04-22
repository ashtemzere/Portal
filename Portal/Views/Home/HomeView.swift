//
//  HomeView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// ١. مۆدێلی داتاکان
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

// ٢. ڕووکاری سەرەکی Home
struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    
    // هێنانی تەنها ٣ ئەپ کە status ـیان دیاریکراوە
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(3))
    }
    
    var body: some View {
        NBNavigationView("Home") {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // بەشی سەرەوە: سلایدی ئەپە تایبەتەکان
                    if !featuredApps.isEmpty {
                        TabView {
                            ForEach(featuredApps) { app in
                                FeaturedAppView(app: app, downloadManager: downloadManager)
                            }
                        }
                        .frame(height: 240)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    }
                    
                    // بەشی ناوەڕاست: لیستی هەموو ئەپەکان
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended For You")
                            .font(.title3.bold())
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(apps) { app in
                                HomeAppRowView(app: app, downloadManager: downloadManager)
                                Divider().padding(.leading, 84)
                            }
                        }
                    }
                    
                    // بەشی کۆتایی: سۆشیاڵ میدیا
                    SocialMediaFooter()
                        .padding(.vertical, 20)
                        .padding(.bottom, 30)
                }
                .padding(.top, 10)
            }
            .refreshable {
                await loadApps()
            }
        }
        .onAppear {
            Task {
                await loadApps()
            }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ashte.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
            }
        } catch {
            print("Error loading: \(error)")
        }
    }
}

// ٣. دیزاینی بەشی سەرەوە (Featured)
struct FeaturedAppView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // وێنە گەورەکەی ئەپەکە
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.blue.opacity(0.2)
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            
            // سێبەری خوارەوە بۆ ئەوەی نووسینەکان بە ڕوونی دەربکەون
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .frame(height: 210)
            
            // زانیارییەکانی ئەپەکە لەسەر وێنەکە
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
                
                // دوگمەی داونلۆدکردن
                HomeDownloadButtonView(app: app, downloadManager: downloadManager)
                    .colorScheme(.dark)
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 25)
    }
}

// ٤. دیزاینی ڕیزی ئەپەکان لە خوارەوە
struct HomeAppRowView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(app.category ?? "App") • \(app.size ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// ٥. بەشی سۆشیاڵ میدیا
struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Follow Us")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 25) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemmobile") // Telegram
                SocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashte.mobile") // Instagram
                SocialButton(icon: "play.tv.fill", color: .black, url: "https://www.tiktok.com/@ashtemmobile") // TikTok
                SocialButton(icon: "camera.viewfinder", color: .yellow, url: "https://www.snapchat.com/add/ashtemzere") // Snapchat
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(UIColor.secondarySystemBackground)))
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

// ٦. لۆجیکی داونلۆدکردن و نیشاندانی بازنەکە
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
            self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString)-\(downloadURL?.lastPathComponent ?? "app.ipa")"
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            self.isDownloading = false
            self.isFinished = true
            self.onFinished?(destinationURL)
        } catch {
            self.isDownloading = false
        }
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            self.isDownloading = false
        }
        session.finishTasksAndInvalidate()
    }
}

struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            
            if downloader.isFinished {
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .disabled(true)
            } else if downloader.isDownloading {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    
                    if downloader.progress > 0 {
                        Circle()
                            .trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 28, height: 28)
                            .animation(.linear(duration: 0.2), value: downloader.progress)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            downloader.stop()
                        }
                }
                .frame(width: 50, height: 35, alignment: .center)
            } else {
                Button(action: {
                    if let decodedData = Data(base64Encoded: app.url),
                       let decodedString = String(data: decodedData, encoding: .utf8),
                       let downloadURL = URL(string: decodedString) {
                        
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        downloader.start(url: downloadURL) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                        }
                    }
                }) {
                    Text("Get")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 80, alignment: .trailing)
    }
}
