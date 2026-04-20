import SwiftUI

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
    let developer: String? // ناوی گەشەپێدەرم زیاد کرد بۆ جوانی
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
    
    var body: some View {
        HStack(spacing: 16) {
            // شوێنی وێنەی ئەپەکە (دەتوانیت دواتر بیگۆڕیت بۆ AsyncImage بۆ هێنانی وێنە لە ئینتەرنێتەوە)
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
                print("Clicked Get for \(app.name)")
                // لێرەدا کۆدی دابەزاندن یان کردنەوەی زانیاری زیادە دادەنێیت
            }) {
                Text(app.button ?? "Get")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle()) 
    }
}

// MARK: - داتای تەواوەتی JSON ـەکەی خۆت
let appsJSONString = """
[
  { 
    "name": "VideoStar 26", 
    "version": "14.4.6", 
    "category": "Apps", 
    "image": "img/VideoStar26.png",
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
    "size": "194.67 MB",
    "developer": "AshteMobile",
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
    "size": "200.07 MB", 
    "status": "new",
    "developer": "AshteMobile",
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
    "size": "378.47 MB",
    "developer": "AshteMobile",
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
    "size": "192.76 MB",
    "status": "new",
    "developer": "AshteMobile",
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
    "size": "625.33 MB",
    "developer": "AshteMobile",
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
    "size": "198.9 MB",
    "developer": "AshteMobile",
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
    "size": "192.42 MB",
    "developer": "AshteMobile",
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
    "size": "139.1 MB",
    "developer": "EA SPORTS",
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
    "size": "113.1 MB",
    "developer": "King",
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
    "size": "210.56 MB",
    "status": "update",
    "developer": "AshteMobile",
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
    "size": "209.8 MB",
    "developer": "AshteMobile",
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
    "size": "270.8 MB",
    "developer": "AshteMobile",
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
    "size": "99.5 MB",
    "developer": "Miniclip",
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
    "size": "196.5 MB",
    "developer": "AshteMobile",
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
    "size": "726.2 MB",
    "developer": "AshteMobile",
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
    "size": "94 MB",
    "developer": "AshteMobile",
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
    "size": "169.5 MB",
    "developer": "AshteMobile",
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
    "size": "134.5 MB",
    "developer": "AshteMobile",
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
    "size": "110.7 MB",
    "developer": "AshteMobile",
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
    "size": "243.0 MB",
    "developer": "TikTok Ltd.",
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
    "size": "117.9 MB",
    "developer": "Google LLC",
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
    "size": "147.3 MB",
    "developer": "Instagram, Inc.",
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
