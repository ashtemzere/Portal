//
//  SourcesView.swift
//  Feather
//

import SwiftUI
import NimbleViews

// ١. مۆدێلی نوێ کە لەگەڵ فایلی ipa.json دەگونجێت
struct AshteApp: Codable, Identifiable {
    var id: String { url } // لینکەکە وەک ID بەکاردێت چونکە جیاوازە بۆ هەر ئەپێک
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String // لینکی دابەزاندنی IPA بە Base64

    // بەکارهێنانی دۆمەینی خۆت بۆ وێنەکان
    var fullImageURL: URL? {
        guard let img = image else { return nil }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
}

// ٢. ڕووکاری سەرەکی
struct SourcesView: View {
    // 👈 هێنانی DownloadManager بۆ ئەوەی ڕاستەوخۆ بخرێتە ناو Library
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
                                    
                                    // بەکارهێنانی زانیارییەکان گەر هەبن، گەر نا بەتاڵ
                                    Text("\(app.category ?? "App") • \(app.size ?? "Unknown")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // دوگمەی دابەزاندن بۆ ناو Library
                                Button(action: {
                                    installApp(base64String: app.url)
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
    
    // ٣. هێنانی فایلی ipa.json لە سێرڤەرەکەتەوە
    private func loadApps() {
        isLoading = true
        
        // 👈 لینکەکە گۆڕدرا بۆ ipa.json
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
    
    // ٤. ناردنی لینکەکان بۆ ناو بەشی Library بە مەبەستی دابەزاندن
    private func installApp(base64String: String) {
        if let decodedData = Data(base64Encoded: base64String),
           let decodedString = String(data: decodedData, encoding: .utf8),
           let downloadURL = URL(string: decodedString) {
            
            // 👈 ئەم فەرمانە ڕاستەوخۆ دەست دەکات بە دابەزاندنی فایلەکە بۆ ناو بەشی Library
            _ = downloadManager.startDownload(from: downloadURL)
            
            // پیشاندانی ئاگادارکردنەوەیەکی کورت کە دابەزاندن دەستی پێکرد
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } else {
            print("Failed to decode base64 URL")
        }
    }
}
