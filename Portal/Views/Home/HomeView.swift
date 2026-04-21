import SwiftUI
import UIKit

// مۆدێلی داتاکان بەپێی فایلە JSON ـەکەی خۆت
struct AppItem: Identifiable, Codable {
    var id: String { name } // بەکارهێنانی ناوەکە وەک ID
    let name: String
    let version: String
    let category: String
    let image: String
    let size: String
    let button: String?
    let features: [String]?
    let status: String?
    let developer: String?
    let url: String? // پێویستە بۆ داگرتنی بەرنامەکە
    let banner: String?
    let updated: String?
    let bundle: String?
    let ios: String?
    let language: String?
}

struct HomeView: View {
    @State private var apps: [AppItem] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(apps) { app in
                        AppRowView(app: app)
                        
                        // هێڵێکی جیاکەرەوە لە نێوان ئەپەکان
                        Divider()
                            .padding(.leading, 88)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Apps & Games")
            .onAppear {
                loadAppsData()
            }
        }
    }
    
    // فەنکشنێک بۆ هێنانە ناوەوەی داتاکانی JSON
    private func loadAppsData() {
        guard let data = appsJSONString.data(using: .utf8) else { return }
        do {
            let decodedApps = try JSONDecoder().decode([AppItem].self, from: data)
            self.apps = decodedApps
        } catch {
            print("Error decoding JSON: \(error)")
        }
    }
}

// دیزاینی ڕیزی هەر ئەپێک بە ستایلی ستۆر
struct AppRowView: View {
    let app: AppItem
    
    // گۆڕاوێک بۆ نیشاندانی نامەی دڵنیابوونەوە لە کاتی داگرتن
    @State private var showInstallAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // شوێنی وێنەی ئەپەکە
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
                
                Image(systemName: app.category == "Games" ? "gamecontroller.fill" : "app.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            .frame(width: 72, height: 72)
            
            // زانیارییەکانی ئەپەکە (ناو، گەشەپێدەر، قەبارە)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                
                Text(app.developer ?? app.category)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(app.size)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 10)
            
            // دوگمەی Get
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                // نیشاندانی نامەی دڵنیابوونەوە
                showInstallAlert = true
            }) {
                Text(app.button ?? "Get")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(Capsule())
            }
            // نامەی Alert
            .alert("Install App", isPresented: $showInstallAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Install") {
                    installApp()
                }
            } message: {
                Text("Would you like to install \(app.name)?")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    // فەنکشنی ئینستاڵکردن بە itms-services
    private func installApp() {
        guard let base64Url = app.url,
              let decodedData = Data(base64Encoded: base64Url),
              let decodedUrlString = String(data: decodedData, encoding: .utf8) else {
            print("Error: Could not decode URL for \(app.name)")
            return
        }
        
        let manifestString = "itms-services://?action=download-manifest&url=\(decodedUrlString)"
        
        if let url = URL(string: manifestString) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("Successfully opened itms-services for \(app.name)")
                } else {
                    print("Failed to open itms-services link.")
                }
            }
        }
    }
}

// MARK: - داتای تەواوەتی JSON ـەکەی خۆت بە لینکەکانەوە
let appsJSONString = """
[
  { 
    "name": "VideoStar 26", 
    "version": "14.4.6", 
    "category": "Apps", 
    "image": "img/VideoStar26.png",
    "banner": "imgg/videostar1.png",
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvVmlkZW9TdGFyMS5pcGE=",
    "size": "592.47 MB",
    "status": "top",
    "button": "Get",
    "features": [
      "Pro Version Unlocked",
      "All Effects Free",
      "No Watermark"
    ]
  },
  { 
    "name": "Russian Village Traffic Racer", 
    "version": "0.4.3", 
    "category": "Games", 
    "image": "img/RussianVillage.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvUnVzc2lhblZpbGxhZ2UuaXBh",
    "size": "630.29 MB",
    "button": "Get",
    "features": [
      "Auto Complete Tasks",
      "Freeze Currency",
      "Unlock All Cars",
      "Unlock VIP",
      "No Ads"
    ]
  },
  { 
    "name": "Matchington", 
    "version": "V 1.198.0", 
    "category": "Games", 
    "image": "img/Matchington.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvTWF0Y2hpbmd0b24uaXBh",
    "size": "194.67 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.matchington",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Infinite Moves",
      "Infinite Booster",
      "Infinite Lives"
    ]
  },
  { 
    "name": "Tropic Escape", 
    "version": "V 1.121", 
    "category": "Games", 
    "image": "img/TropicEscape.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvVHJvcGljRXNjYXBlLmlwYQ==",
    "size": "200.07 MB", 
    "status": "new",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.tropicescape",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Freeze Currencies"
    ]
  },
  { 
    "name": "Prison Empire", 
    "version": "V 4.2.5", 
    "category": "Games", 
    "image": "img/PrisonEmpire.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvUHJpc29uRW1waXJlLmlwYQ==",
    "size": "378.47 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.prisonempire",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Freeze Cash",
      "No Ads"
    ]
  },
  { 
    "name": "Jawaker", 
    "version": "V 28.2.76", 
    "category": "Games", 
    "image": "img/Jawaker.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvSmF3YWtlci5pcGE=",
    "size": "192.76 MB",
    "status": "new",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.jawaker",
    "ios": "13.0",
    "language": "EN, AR",
    "button": "Get",
    "features": [
      "Pasha activation.",
      "More rewards.",
      "Open instant messages."
    ]
  },
  { 
    "name": "Polygun Arena", 
    "version": "V 1.0605", 
    "category": "Games", 
    "image": "img/PolygunArena.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvUG9seWd1bkFyZW5hLmlwYQ==",
    "size": "625.33 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.polygunarena",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Unlimited Ammo -> Will not decrease.",
      "No Camera Shake",
      "Damage Multiplayer",
      "Defence Multiplayer",
      "Speed Multiplayer"
    ]
  },
  { 
    "name": "Homescapes", 
    "version": "V 8.6.600", 
    "category": "Games", 
    "image": "img/Homescapes.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvSG9tZXNjYXBlcy5pcGE=",
    "size": "198.9 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.homescapes",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Infinite Moves",
      "Infinite Boosters",
      "Infinite Lives",
      "Infinite Coins",
      "Complete Tasks without Stars",
      "Unlock Season Pass"
    ]
  },
  { 
    "name": "Township", 
    "version": "V 34.0.1", 
    "category": "Games", 
    "image": "img/Township.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvVG93bnNoaXAuaXBh",
    "size": "192.42 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.township",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Freeze Currencies"
    ]
  },
  { 
    "name": "EA SPORTS FC™ Mobile", 
    "version": "V 26.1.04", 
    "category": "Games", 
    "image": "img/EASPORTSFC.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvRUFTUE9SVFNGQy5pcGE=",
    "size": "139.1 MB",
    "developer": "EA SPORTS",
    "updated": "2026-03-14",
    "bundle": "com.ea.ios.fifamobile",
    "ios": "13.0",
    "language": "EN, AR",
    "button": "Get",
    "features": [
      "Stupid Al Detense",
      "Sometimes works, sometimes doesn't."
    ]
  },
  { 
    "name": "Candy Crush Saga", 
    "version": "V 1.322.0", 
    "category": "Games", 
    "image": "img/CandyCrushSaga.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvQ2FuZHlDcnVzaFNhZ2EuaXBh",
    "size": "113.1 MB",
    "developer": "King",
    "updated": "2026-03-14",
    "bundle": "com.midasplayer.apps.candycrushsaga",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Infinite Lives",
      "Infinite Boosters"
    ]
  },
  { 
    "name": "Gardenscapes", 
    "version": "9.4.5", 
    "category": "Games", 
    "image": "img/Gardenscapes.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvR2FyZGVuc2NhcGVzLmlwYQ==",
    "size": "210.56 MB",
    "status": "update",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.gardenscapes",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Infinite Moves",
      "Infinite Boosters",
      "Infinite Lives"
    ]
  },
  { 
    "name": "Royal Match", 
    "version": "V 34386", 
    "category": "Games", 
    "image": "img/RoyalMatch.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvUm95YWxNYXRjaC5pcGE=",
    "size": "209.8 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.royalmatch",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Freeze Coins",
      "Freeze Lives",
      "Freeze Stars",
      "Freeze Boosters",
      "Freeze Time",
      "Freeze Moves",
      "Unlock VIP Badges",
      "Auto Win -> Finish Stage"
    ]
  },
  { 
    "name": "Fruit Ninja", 
    "version": "V 3.93.2", 
    "category": "Games", 
    "image": "img/FruitNinja.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvRnJ1aXROaW5qYS5pcGE=",
    "size": "270.8 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.fruitninja",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "No Bomb",
      "Freeze Starfruit",
      "Infinite Boosters"
    ]
  },
  { 
    "name": "8 Ball Pool", 
    "version": "V 56.18.2", 
    "category": "Games", 
    "image": "img/Ball.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvOEJhbGxQb29sLmlwYQ==",
    "size": "99.5 MB",
    "developer": "Miniclip",
    "updated": "2026-03-14",
    "bundle": "com.miniclip.8ballpoolmult",
    "ios": "13.0",
    "language": "EN, AR",
    "button": "Get",
    "features": [
      "Auto Aim (Cheat)",
      "One Shot",
      "Show Lines",
      "Long Cue No Jailbreak Required"
    ]
  },
  { 
    "name": "Subway Surf", 
    "version": "V 3.59.1", 
    "category": "Games", 
    "image": "img/SubwaySurf.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvU3Vid2F5U3VyZi5pcGE=",
    "size": "196.5 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.subwaysurf",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Unlimited Keys",
      "Unlimited Coins",
      "Never Dies",
      "High Jump",
      "Infinite XP"
    ]
  },
  { 
    "name": "LEGO Hill Climb", 
    "version": "V 2.3.1", 
    "category": "Games", 
    "image": "img/LEGOHill.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvTEVHT0hpbGwuaXBh",
    "size": "726.2 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.legohillclimb",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Unlimited Currencies"
    ]
  },
  { 
    "name": "Zombie Highway 2", 
    "version": "V 1.6.1", 
    "category": "Games", 
    "image": "img/Zombie.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2FzaHRlbXplcmUvTXlTaWduZXIvcmVsZWFzZXMvZG93bmxvYWQvdjEuMC9aSDIuaXBh",
    "size": "94 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.zombiehighway2",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Free Store (not iAP)",
      "One Hit Kill",
      "Infinite Ammo"
    ]
  },
  { 
    "name": "Video Star", 
    "version": "V 12.2.2", 
    "category": "Apps", 
    "image": "img/videostar.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvVmlkZW9TdGFyLmlwYQ==",
    "size": "169.5 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.videostar",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Pro Version Unlocked",
      "All Effects Free",
      "No Watermark"
    ]
  },
  { 
    "name": "InShot", 
    "version": "V 1.86.0", 
    "category": "Apps", 
    "image": "img/inshot.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvSW5TaG90LmlwYQ==",
    "size": "134.5 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.inshot",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Pro Unlocked",
      "No Ads",
      "All Transitions Unlocked"
    ]
  },
  { 
    "name": "PicsArt", 
    "version": "V 28.9.4", 
    "category": "Apps", 
    "image": "img/PicsArt.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvUGljc0FydC5pcGE=",
    "size": "110.7 MB",
    "developer": "AshteMobile",
    "updated": "2026-03-14",
    "bundle": "com.ashtemobile.picsart",
    "ios": "13.0",
    "language": "EN",
    "button": "Get",
    "features": [
      "Gold Features Unlocked",
      "Premium Filters Free",
      "No Ads"
    ]
  },
  { 
    "name": "TikTok", 
    "version": "V 34.1.0", 
    "category": "Apps", 
    "image": "img/tiktok.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvVGlrVG9rLmlwYQ==",
    "size": "243.0 MB",
    "developer": "TikTok Ltd.",
    "updated": "2026-03-14",
    "bundle": "com.zhiliaoapp.musically",
    "ios": "13.0",
    "language": "EN, AR",
    "button": "Get",
    "features": [
      "No Watermark Download",
      "Region Unlocked",
      "No Ads"
    ]
  },
  { 
    "name": "YouTube", 
    "version": "V 19.49.7", 
    "category": "Apps", 
    "image": "img/YouTube.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvWW91VHViZS5pcGE=",
    "size": "117.9 MB",
    "developer": "Google LLC",
    "updated": "2026-03-14",
    "bundle": "com.google.ios.youtube",
    "ios": "13.0",
    "language": "EN, AR, KU",
    "button": "Get",
    "features": [
      "YouTube Premium Unlocked",
      "Background Play",
      "Picture in Picture (PiP)",
      "No Ads"
    ]
  },
  { 
    "name": "Instagram", 
    "version": "V 359.0.0", 
    "category": "Apps", 
    "image": "img/instagram.png", 
    "url": "aHR0cHM6Ly9naXRodWIuY29tL2lvczk0L2lwYS9yZWxlYXNlcy9kb3dubG9hZC8xLjAvQkhJbnN0YWdyYW0uaXBh",
    "size": "147.3 MB",
    "developer": "Instagram, Inc.",
    "updated": "2026-03-14",
    "bundle": "com.burbn.instagram",
    "ios": "13.0",
    "language": "EN, AR",
    "button": "Get",
    "features": [
      "Rocket Features",
      "Download Media & Stories",
      "Ghost Mode (Hide Read)",
      "No Ads"
    ]
  }
]
"""
