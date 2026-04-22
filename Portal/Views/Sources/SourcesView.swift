//
//  SourcesView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation

// ١. مۆدێلی ئەپەکان
struct AshteApp: Codable, Identifiable {
    var id: String { url }
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String // لینکی Base64

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
}

// ٢. بەڕێوەبەری دابەزاندن بۆ زانینی قەبارە و کاتی داونلۆدکردن بە شێوەی App Store
class AppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Double = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    private var downloadTask: URLSessionDownloadTask?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url
        self.onFinished = onFinished
        
        DispatchQueue.main.async {
            self.isDownloading = true
            self.progress = 0
            self.isFinished = false
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func stop() {
        downloadTask?.cancel()
        DispatchQueue.main.async {
            self.isDownloading = false
            self.progress = 0
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            if totalBytesExpectedToWrite > 0 {
                // پێوانەکردنی قەبارەی داونلۆدکراو بۆ پڕکردنەوەی بازنەکە
                self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
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
            }
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            DispatchQueue.main.async { self.isDownloading = false }
        }
    }
}

// ٣. دیزاینی دوگمەی Get کە شێوەی دەگۆڕێت بۆ بازنەی App Store
struct DownloadButtonView: View {
    let app: AshteApp
    @ObservedObject var downloadManager: DownloadManager
    @StateObject private var downloader = AppDownloader()
    
    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            
            if downloader.isFinished {
                // دۆخی تەواوبوون (نیشانەی ڕاست)
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .font(.subheadline).bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .disabled(true)
            } else if downloader.isDownloading {
                // دۆخی داونلۆدکردن (بازنەی خولاوە و پڕبوونەوە)
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
                        // پێش ئەوەی دەست پێبکات با کەمێک بسوڕێتەوە
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    
                    // دوگمەی وەستان لە ناوەڕاستی بازنەکەدا
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .onTapGesture {
                            downloader.stop()
                        }
                }
                .frame(width: 50, height: 35, alignment: .center)
            } else {
                // دۆخی ئاسایی (دوگمەی Get)
                Button(action: {
                    if let decodedData = Data(base64Encoded: app.url),
                       let decodedString = String(data: decodedData, encoding: .utf8),
                       let downloadURL = URL(string: decodedString) {
                        
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // دەستپێکردنی داونلۆد و دواتر ناردنی بۆ Library
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
        .frame(width: 80, alignment: .trailing) // بۆ ئەوەی دوگمەکە جێگەی خۆی نەگۆڕێت
    }
}

// ٤. ڕووکاری سەرەکی بۆ نیشاندانی ئەپەکان
struct SourcesView: View {
    @StateObject var downloadManager = DownloadManager.shared 
    @State private var apps: [AshteApp] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    private var filteredApps: [AshteApp] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NBNavigationView("Store") {
            NBListAdaptable {
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
                            HStack(spacing: 16) {
                                // وێنەی ئەپەکە
                                AsyncImage(url: app.fullImageURL) { image in
                                    image.resizable()
                                         .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                }
                                .frame(width: 55, height: 55)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                // زانیارییەکانی ئەپەکە
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name)
                                        .font(.headline)
                                    Text("\(app.category ?? "App") • \(app.size ?? "Unknown")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // 👈 بەکارهێنانی دوگمە نوێیەکە (App Store Style)
                                DownloadButtonView(app: app, downloadManager: downloadManager)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .platform())
            .refreshable {
                loadApps()
            }
        }
        .onAppear {
            loadApps()
        }
    }
    
    // فرمانی هێنانی فایلی ipa.json لە سێرڤەرەکەتەوە
    private func loadApps() {
        isLoading = true
        
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data {
                    do {
                        let decodedApps = try JSONDecoder().decode([AshteApp].self, from: data)
                        self.apps = decodedApps
                    } catch {
                        print("Error decoding ipa.json: \(error)")
                    }
                }
            }
        }.resume()
    }
}
