//
//  SourcesView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

struct AshteApp: Codable, Identifiable {
    var id: String { url }
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String
    let hack: [String]?

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
}

class AshteAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
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

struct AshteDownloadButtonView: View {
    let app: AshteApp
    @ObservedObject var downloadManager: DownloadManager
    var onComplete: () -> Void
    
    @StateObject private var downloader = AshteAppDownloader()
    
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
                    if let downloadURL = URL(string: app.url) {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        downloader.start(url: downloadURL) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            DispatchQueue.main.async {
                                onComplete() 
                            }
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

struct AshteAppDetailView: View {
    let app: AshteApp
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
                            
                            // 👈 لێرەشدا شەیرکردنی ڕاستەوخۆی فایلەکەمان گۆڕی
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
                        
                        AshteDownloadButtonView(app: app, downloadManager: downloadManager, onComplete: onDownloadComplete)
                            .frame(width: 80, alignment: .leading)
                            .padding(.top, 4)
                            .padding(.leading, -20)
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

struct StoreSocialButton: View {
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
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct SourcesView: View {
    @StateObject var downloadManager = DownloadManager.shared 
    @State private var apps: [AshteApp] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    @State private var showNotification = false
    @State private var downloadedApp: AshteApp? = nil
    
    @State private var selectedFilter = "ALL"
    let filterOptions = ["ALL", "APP", "GAMES"]
    
    @State private var currentBanner = 0
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    let bannerURLs = [
        "https://ashtemobile.tututweak.com/1.png",
        "https://ashtemobile.tututweak.com/2.png",
        "https://ashtemobile.tututweak.com/3.png",
        "https://ashtemobile.tututweak.com/4.png"
    ]
    
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
        ZStack(alignment: .top) {
            NBNavigationView("Store") {
                NBListAdaptable {
                    
                    VStack(spacing: 20) {
                        TabView(selection: $currentBanner) {
                            ForEach(0..<bannerURLs.count, id: \.self) { index in
                                AsyncImage(url: URL(string: bannerURLs[index])) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .padding(.horizontal, 16)
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .frame(height: 180)
                        .onReceive(timer) { _ in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentBanner = (currentBanner + 1) % bannerURLs.count
                            }
                        }
                        
                        HStack(spacing: 28) {
                            StoreSocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
                            StoreSocialButton(icon: "camera.viewfinder", color: .yellow, url: "https://www.snapchat.com//add/ashtemzere")
                            StoreSocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashte.mobile?igsh=c3lqdHNsenozMmp2")
                            StoreSocialButton(icon: "play.tv.fill", color: .black, url: "https://www.tiktok.com/@ashtemobile")
                        }
                        .padding(.bottom, 5)
                        
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(filterOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .padding(.top, 16)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    
                    if isLoading {
                        ProgressView("Loading Apps...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if filteredApps.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "app.dashed")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Apps Found")
                                .font(.title3.bold())
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 250, alignment: .center)
                    } else {
                        NBSection("Apps") {
                            ForEach(filteredApps) { app in
                                NavigationLink(destination: AshteAppDetailView(app: app, downloadManager: downloadManager) {
                                    self.downloadedApp = app
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        self.showNotification = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        withAnimation(.easeOut) {
                                            self.showNotification = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        AsyncImage(url: app.fullImageURL) { image in
                                            image.resizable()
                                                 .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 55, height: 55)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(app.name)
                                                .font(.headline)
                                            Text("\(app.category ?? "App") • \(app.size ?? "Unknown")")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        
                                        AshteDownloadButtonView(app: app, downloadManager: downloadManager) {
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
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, placement: .platform())
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
    
    @ViewBuilder
    private func notificationBanner(for app: AshteApp) -> some View {
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
        DispatchQueue.main.async { isLoading = true }
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else {
            DispatchQueue.main.async { isLoading = false }
            return
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decodedApps = try JSONDecoder().decode([AshteApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decodedApps
                self.isLoading = false
            }
        } catch {
            print("Error decoding json: \(error)")
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}
