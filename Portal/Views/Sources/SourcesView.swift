import SwiftUI
import NimbleViews
import Foundation
import UIKit

// ١. مۆدێلی داتا: دڵنیابوونەوە لەوەی لەگەڵ JSON یەکدەگرێتەوە
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
    let hack: [String]?

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        if img.contains("http") { return URL(string: img) }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
}

// ٢. بەڕێوەبەری دابەزاندن (Downloader)
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
        let fileName = "\(UUID().uuidString).ipa"
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isFinished = true
                self.onFinished?(destinationURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.isFinished = false }
            }
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
        }
    }
}

// ٣. پیشاندانی لیستەکە و نوێبوونەوەی خۆکار (SourcesView)
struct SourcesView: View {
    @StateObject var downloadManager = DownloadManager.shared 
    @State private var apps: [AshteApp] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedFilter = "ALL"
    
    // لێرە لینکە بنەڕەتییەکەت دانراوە
    let jsonURL = "https://ashtemobile.tututweak.com/ipa.json"
    
    var filteredApps: [AshteApp] {
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
        NBNavigationView("Ashte Store") {
            NBListAdaptable {
                
                // بەشی پاڵفتەکردن (Filter)
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag("ALL")
                    Text("Apps").tag("APP")
                    Text("Games").tag("GAMES")
                }
                .pickerStyle(.segmented)
                .padding()

                if isLoading {
                    ProgressView("Updating...").frame(maxWidth: .infinity).padding()
                } else {
                    ForEach(filteredApps) { app in
                        NavigationLink(destination: AshteAppDetailView(app: app, downloadManager: downloadManager, onDownloadComplete: {})) {
                            HStack(spacing: 15) {
                                AsyncImage(url: app.fullImageURL) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name).font(.headline)
                                    Text(app.category ?? "Software").font(.subheadline).foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                // دوگمەی Get
                                Text("GET")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .refreshable {
                await loadData() // ڕاکێشان بۆ خوارەوە بۆ نوێکردنەوە
            }
        }
        .onAppear {
            Task { await loadData() } // هەر کە بەرنامەکە کرایەوە داتا دەهێنێت
        }
    }
    
    // فەنکشن بۆ هێنانی داتا لە لینکەکەی تۆوە
    func loadData() async {
        guard let url = URL(string: jsonURL) else { return }
        
        // فێڵێک بۆ ئەوەی ئایفۆنەکە داتا کۆنەکە (Cache) پیشان نەداتەوە
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData 
        
        do {
            isLoading = true
            let (data, _) = try await URLSession.shared.data(for: request)
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
