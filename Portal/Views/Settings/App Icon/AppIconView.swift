//
//  AppIconView.swift
//  Feather
//

import SwiftUI
import NimbleViews

// MARK: - View extension: Model
extension AppIconView {
    struct AltIcon: Identifiable {
        var displayName: String
        var author: String
        var key: String?
        var id: String { key ?? displayName }
        
        init(displayName: String, author: String, key: String? = nil) {
            self.displayName = displayName
            self.author = author
            self.key = key
        }
    }
}

// MARK: - View
struct AppIconView: View {
    @Binding var currentIcon: String?
    
    // لیستی ئایکۆنەکانی بەرنامەکە
    var sections: [String: [AltIcon]] = [
        "Main": [
            AltIcon(displayName: "AshteMobile", author: "BY ashtemobile", key: nil)
        ],
    ]
    
    // MARK: Body
    var body: some View {
        NBList("About & Icon") {
            
            // ١. بەشی پرۆفایل و لۆگۆ و سۆشیاڵ میدیا
            Section {
                VStack(spacing: 16) {
                    // لۆگۆی سایتەکە
                    AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 85, height: 85)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    // ناو و زانیاری
                    VStack(spacing: 4) {
                        Text("AshteMobile")
                            .font(.title2.weight(.bold))
                        Text("The Best Tweaked Apps & Games")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // دوگمەکانی سۆشیاڵ میدیا
                    HStack(spacing: 24) {
                        SocialIconButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
                        SocialIconButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashtemobile")
                        SocialIconButton(icon: "play.tv.fill", color: .black, url: "https://www.tiktok.com/@ashtemobile")
                        SocialIconButton(icon: "camera.viewfinder", color: .yellow, url: "https://www.snapchat.com/add/ashtemobile")
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            
            // ٢. بەشی گۆڕینی ئایکۆن
            ForEach(sections.keys.sorted(), id: \.self) { section in
                if let icons = sections[section] {
                    NBSection("App Icon") {
                        ForEach(icons) { icon in
                            _icon(icon: icon)
                        }
                    }
                }
            }
        }
        .onAppear {
            currentIcon = UIApplication.shared.alternateIconName
        }
    }
}

// MARK: - View extension بۆ ئایکۆنەکان
extension AppIconView {
    @ViewBuilder
    private func _icon(
        icon: AppIconView.AltIcon
    ) -> some View {
        Button {
            UIApplication.shared.setAlternateIconName(icon.key) { _ in
                currentIcon = UIApplication.shared.alternateIconName
            }
        } label: {
            HStack(spacing: 18) {
                
                // 👈 لێرەدا لۆگۆکەی تۆم داناوە لەبری وێنە بەتاڵەکە
                AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
                
                NBTitleWithSubtitleView(
                    title: icon.displayName,
                    subtitle: icon.author,
                    linelimit: 0
                )
                
                Spacer()
                
                if currentIcon == icon.key {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - دیزاینی دوگمەی سۆشیاڵ میدیا
struct SocialIconButton: View {
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
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 46, height: 46)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
