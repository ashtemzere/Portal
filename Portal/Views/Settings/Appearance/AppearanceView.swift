import SwiftUI
import NimbleViews
import UIKit

struct AppearanceView: View {
    @Binding var currentIcon: String?

    @AppStorage("Feather.userInterfaceStyle")
    private var _userInterfaceStyle: Int = UIUserInterfaceStyle.unspecified.rawValue

    @AppStorage("Feather.storeCellAppearance")
    private var _storeCellAppearance: Int = 0

    private let _storeCellAppearanceMethods: [(name: String, desc: String)] = [
        (.localized("Minimal"), .localized("Minimal app description")),
        (.localized("Detailed"), .localized("Detailed app descriptions"))
    ]

    var body: some View {
        NBList(.localized("Appearance")) {
            
            // ١. بەشی لۆگۆ و ناوی ماڵپەڕەکەت
            Section {
                VStack(alignment: .center, spacing: 12) {
                    // هێنانی لۆگۆکەت لەسەر ئینتەرنێتەوە
                    AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 85, height: 85)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                    // ناوی ئەپەکەت
                    Text("Ashte Mobile")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            // ٢. بەشەکانی تری ڕێکخستنەکان وەک خۆیانن
            Section {
                Picker(.localized("Appearance"), selection: $_userInterfaceStyle) {
                    ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                        Text(style.label).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                NavigationLink(destination: AppIconView(currentIcon: $currentIcon)) {
                    Label(.localized("App Icon"), systemImage: "app.badge")
                }
            }

            NBSection(.localized("Theme")) {
                AppearanceTintColorView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(EmptyView())
            }
        }
        .onChange(of: _userInterfaceStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
            }
        }
    }
}
