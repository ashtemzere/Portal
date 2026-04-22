//
//  SourcesView.swift
//  Feather
//

import SwiftUI
import NimbleViews

// ١. مۆدێلێک بۆ خوێندنەوەی فایلی json ـەکەی خۆت
struct AshteApp: Codable, Identifiable {
    var id: String { bundle }
    let name: String
    let version: String
    let category: String
    let image: String
    let size: String
    let developer: String
    let bundle: String
    let url: String // لینکی دابەزاندن بە Base64

    // بەکارهێنانی دۆمەینی خۆت بۆ وێنەکان
    var fullImageURL: URL? {
        URL(string: "https://ashtemobile.tututweak.com/\(image)")
    }
}

// ٢. ڕووکاری سەرەکی بۆ نیشاندانی ئەپەکانت
struct SourcesView: View {
    @State private var apps: [AshteApp] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    // گەڕان بەناو ئەپەکاندا
    private var filteredApps: [AshteApp] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NBNavigationView("Store") { // ناوی بەشەکە گۆڕدرا بۆ Store
            NBListAdaptable {
                if isLoading {
                    ProgressView("Loading Apps...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if filteredApps.isEmpty {
                    ContentUnavailableView("No Apps Found", systemImage: "app.dashed")
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
                                    Text("\(app.category) • \(app.size)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // دوگمەی دابەزاندن (Install)
                                Button(action: {
                                    installApp(base64String: app.url)
                                }) {
                                    Text("Install")
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
    
    // ٣. فرمانی هێنانی فایلی json لە سێرڤەری ashtemobile
    private func loadApps() {
        isLoading = true
        
        guard let url = URL(string: "https://ashtemobile.tututweak.com/apps.json") else {
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
                        print("Error decoding apps.json: \(error)")
                    }
                }
            }
        }.resume()
    }
    
    // ٤. فرمانی دابەزاندن و کردنەوەی لینکی itms-services دوای وەرگێڕانی Base64
    private func installApp(base64String: String) {
        if let decodedData = Data(base64Encoded: base64String),
           let decodedString = String(data: decodedData, encoding: .utf8),
           let installURL = URL(string: decodedString) {
            
            UIApplication.shared.open(installURL)
        } else {
            print("Failed to decode base64 URL")
        }
    }
}
