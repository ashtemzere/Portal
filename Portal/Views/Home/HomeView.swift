import SwiftUI
import CoreData
import NimbleViews // دڵنیابە لەوەی ئەم پەیکەیجەت هەیە
import UIKit
import UniformTypeIdentifiers

struct HomeView: View {
    @AppStorage("feather.profileImage") private var profileImageData: Data?
    @AppStorage("feather.profileName") private var profileName: String = ""

    @State private var widgetsEditing = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var titleText: String {
        let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? greeting : "\(greeting), \(name)"
    }

    var body: some View {
        NBNavigationView("") {
            ZStack {
                // باکگراوندێکی مۆدێرنی کاڵ بۆ جوانی زیاتر
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text(titleText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    // بەشی سۆشیاڵ میدیا و بەستەرە خێراکان
                    QuickLinksBar()

                    WidgetsPagerView(isEditing: $widgetsEditing)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if widgetsEditing {
                        Button {
                            NotificationCenter.default.post(name: .widgetsAddRequested, object: nil)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if widgetsEditing {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                widgetsEditing = false
                            }
                        } label: {
                            Text("Done").font(.system(size: 16, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    profileImage
                }
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let data = profileImageData, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
            }
        }
        .frame(width: 38, height: 38)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - بەشی مۆدێرنی سۆشیاڵ میدیا (گۆڕانکاری نوێ)
struct QuickLinksBar: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                SocialMediaIcon(icon: "globe", title: "Khoindvn", color: .blue)
                SocialMediaIcon(icon: "message.fill", title: "Discord", color: .indigo)
                SocialMediaIcon(icon: "bird.fill", title: "Twitter", color: .cyan)
                SocialMediaIcon(icon: "play.rectangle.fill", title: "YouTube", color: .red)
                SocialMediaIcon(icon: "camera.fill", title: "Instagram", color: .purple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .padding(.bottom, 8)
    }
}

struct SocialMediaIcon: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // لێرەدا دەتوانیت فرمانەکان بنووسیت بۆ کردنەوەی لینکەکان
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        LinearGradient(colors: [color.opacity(0.7), color], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

extension Notification.Name {
    static let widgetsAddRequested = Notification.Name("widgetsAddRequested")
}

struct WidgetsPagerView: View {
    @AppStorage("feather.guides.widgets.state") private var widgetStateJSON: String = ""

    @Binding var isEditing: Bool

    @State private var widgets: [WidgetState] = []
    @State private var draggingID: UUID?
    @State private var showingAddSheet = false

    @State private var currentPage: Int = 0
    @State private var addPageSnapshot: Int = 0

    private let hPadding: CGFloat = 16
    private let spacing: CGFloat = 12 // کەمێک بۆشاییم زیاد کرد بۆ هەناسەدانی کارتەکان
    private let baseHeight: CGFloat = 180 // کەمێک کورتم کردەوە بۆ ستایلێکی فراوانتر
    private let gridMax: CGFloat = 720

    private let lockedKinds: Set<WidgetKind> = [.stats, .time, .deviceStats]
    private let maxRowsPerPage: Int = 3

    private let tabBarClearance: CGFloat = 110
    private let pageTopInset: CGFloat = 10
    private let pageVisualGap: CGFloat = 42

    private var visibleWidgets: [WidgetState] { widgets.filter { !$0.isHidden } }
    private var maxUsedPage: Int { max(0, visibleWidgets.map(\.page).max() ?? 0) }

    private var pageCountToRender: Int {
        if visibleWidgets.isEmpty { return 1 }
        let used = maxUsedPage + 1
        return isEditing ? (used + 1) : used
    }

    private func pageWidgets(_ page: Int) -> [WidgetState] {
        widgets.filter { !$0.isHidden && $0.page == page }
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) { // نیشاندەری سکڕۆڵم شاردەوە بۆ جوانی
                LazyVStack(spacing: pageVisualGap) {
                    ForEach(0..<pageCountToRender, id: \.self) { p in
                        pageContainer(page: p)
                            .frame(minHeight: geo.size.height, alignment: .top)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: PageOffsetKey.self,
                                        value: [p: proxy.frame(in: .named("widgets-scroll")).minY]
                                    )
                                }
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.bottom, tabBarClearance)
            }
            .coordinateSpace(name: "widgets-scroll")
            .onPreferenceChange(PageOffsetKey.self) { offsets in
                guard let closest = offsets.min(by: { abs($0.value) < abs($1.value) })?.key else { return }
                if currentPage != closest {
                    currentPage = closest
                }
            }
            .onAppear {
                loadWidgetsIfNeeded()
                rebalanceByRowLimitIfNeeded()
                currentPage = min(currentPage, pageCountToRender - 1)
            }
            .onChange(of: widgets) { _, _ in saveWidgets() }
            .onChange(of: isEditing) { _, newValue in
                if !newValue { draggingID = nil }
                currentPage = min(currentPage, max(0, pageCountToRender - 1))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in draggingID = nil }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in draggingID = nil }
            .onReceive(NotificationCenter.default.publisher(for: .widgetsAddRequested)) { _ in
                guard isEditing else { return }
                addPageSnapshot = currentPage
                showingAddSheet = true
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWidgetsSheet(
                    hiddenWidgets: widgets.filter { $0.isHidden },
                    onAdd: { kind in addWidget(kind: kind, preferredPage: addPageSnapshot) }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .onDrop(of: [UTType.text], isTargeted: nil) { _ in
            draggingID = nil
            return true
        }
    }

    // (کۆدەکانی pageContainer و addWidget و loadWidgets و saveWidgets وەک خۆیان دەمێننەوە...)
    private func pageContainer(page: Int) -> some View {
        let items = pageWidgets(page)
        let noWidgetsAnywhere = visibleWidgets.isEmpty

        return VStack(spacing: 0) {
            ZStack(alignment: .top) {
                WidgetsGridView(
                    widgets: $widgets,
                    draggingID: $draggingID,
                    isEditing: $isEditing,
                    page: page,
                    visibleWidgets: items,
                    lockedKinds: lockedKinds,
                    hPadding: hPadding,
                    spacing: spacing,
                    baseHeight: baseHeight,
                    gridMax: gridMax,
                    onCommit: {
                        rebalanceByRowLimitIfNeeded()
                        draggingID = nil
                    }
                )
                .padding(.top, pageTopInset)
                .frame(maxWidth: .infinity, alignment: .top)
                .onDrop(of: [UTType.text], isTargeted: nil) { _ in
                    draggingID = nil
                    return true
                }

                if noWidgetsAnywhere && page == 0 {
                    EmptyAllWidgetsView(
                        onAdd: {
                            if !isEditing {
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.92)) {
                                    isEditing = true
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                addPageSnapshot = 0
                                showingAddSheet = true
                            }
                        }
                    )
                    .padding(.top, 28)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func addWidget(kind: WidgetKind, preferredPage: Int) {
        guard let idx = widgets.firstIndex(where: { $0.kind == kind }) else { return }

        widgets[idx].isHidden = false
        widgets[idx].page = max(0, preferredPage)

        if lockedKinds.contains(kind) { widgets[idx].size = .small }
        if kind == .portalVersion, widgets[idx].size == .large { widgets[idx].size = .wide }
        if kind == .guides, widgets[idx].size == .small { widgets[idx].size = .wide }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        rebalanceByRowLimitIfNeeded()
    }

    private func loadWidgetsIfNeeded() {
        if !widgets.isEmpty { return }

        if let data = widgetStateJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([WidgetState].self, from: data) {
            widgets = mergeWithDefaults(decoded)
            if widgets.isEmpty { widgets = WidgetState.defaultWidgets }
        } else {
            widgets = WidgetState.defaultWidgets
        }

        for i in widgets.indices {
            let kind = widgets[i].kind
            if lockedKinds.contains(kind) { widgets[i].size = .small }
            if kind == .portalVersion, widgets[i].size == .large { widgets[i].size = .wide }
            if kind == .guides, widgets[i].size == .small { widgets[i].size = .wide }
            if widgets[i].page < 0 { widgets[i].page = 0 }
        }

        saveWidgets()
    }

    private func mergeWithDefaults(_ existing: [WidgetState]) -> [WidgetState] {
        var out = existing
        let existingKinds = Set(existing.map(\.kind))
        for d in WidgetState.defaultWidgets where !existingKinds.contains(d.kind) { out.append(d) }
        return out
    }

    private func saveWidgets() {
        guard let data = try? JSONEncoder().encode(widgets),
              let str = String(data: data, encoding: .utf8) else { return }
        widgetStateJSON = str
    }

    private func computeUsedRows(for items: [WidgetState]) -> Int {
        if items.isEmpty { return 0 }

        var occ: [[Bool]] = []
        func ensureRows(_ r: Int) { while occ.count <= r { occ.append([false, false]) } }

        func canPlace(row r: Int, col c: Int, spanX: Int, spanY: Int) -> Bool {
            ensureRows(r + spanY - 1)
            if spanX == 2 && c != 0 { return false }
            if c < 0 || c > 1 { return false }
            for yy in 0..<spanY {
                for xx in 0..<spanX {
                    let rr = r + yy
                    let cc = c + xx
                    if cc > 1 { return false }
                    if occ[rr][cc] { return false }
                }
            }
            return true
        }

        func mark(row r: Int, col c: Int, spanX: Int, spanY: Int) {
            ensureRows(r + spanY - 1)
            for yy in 0..<spanY { for xx in 0..<spanX { occ[r + yy][c + xx] = true } }
        }

        var maxRowUsed = 0

        for it in items {
            let spanX = max(1, min(2, it.size.spanX))
            let spanY = max(1, min(2, it.size.spanY))

            var placed = false
            var r = 0
            while !placed {
                ensureRows(r)
                if spanX == 2 {
                    if canPlace(row: r, col: 0, spanX: 2, spanY: spanY) {
                        mark(row: r, col: 0, spanX: 2, spanY: spanY)
                        maxRowUsed = max(maxRowUsed, r + spanY)
                        placed = true
                    } else { r += 1 }
                } else {
                    if canPlace(row: r, col: 0, spanX: 1, spanY: spanY) {
                        mark(row: r, col: 0, spanX: 1, spanY: spanY)
                        maxRowUsed = max(maxRowUsed, r + spanY)
                        placed = true
                    } else if canPlace(row: r, col: 1, spanX: 1, spanY: spanY) {
                        mark(row: r, col: 1, spanX: 1, spanY: spanY)
                        maxRowUsed = max(maxRowUsed, r + spanY)
                        placed = true
                    } else { r += 1 }
                }
            }
        }

        return maxRowUsed
    }

    private func rebalanceByRowLimitIfNeeded() {
        var safety = 0

        while safety < 1000 {
            safety += 1

            let visibleIdx = widgets.indices.filter { !widgets[$0].isHidden }
            if visibleIdx.isEmpty { break }

            let maxP = max(0, visibleIdx.map { widgets[$0].page }.max() ?? 0)
            var movedAny = false

            for p in 0...maxP {
                let pageIdx = visibleIdx.filter { widgets[$0].page == p }
                if pageIdx.isEmpty { continue }

                let items = pageIdx.map { widgets[$0] }
                let usedRows = computeUsedRows(for: items)

                if usedRows <= maxRowsPerPage { continue }

                if let last = pageIdx.last {
                    widgets[last].page = p + 1
                    movedAny = true
                }
            }

            if !movedAny { break }
        }

        for i in widgets.indices where !widgets[i].isHidden && widgets[i].page < 0 {
            widgets[i].page = 0
        }

        saveWidgets()

        if currentPage > pageCountToRender - 1 {
            currentPage = max(0, pageCountToRender - 1)
        }
    }
}

private struct PageOffsetKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct EmptyAllWidgetsView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.dashed")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.blue.opacity(0.6))

            Text("No widgets here")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Button(action: onAdd) {
                Text("Add Widgets")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue, in: Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - دیزاینی نوێی کارتەکان (گۆڕانکاری بۆ مۆدێرن)
struct WidgetCard: View {
    let title: String
    let kind: WidgetKind
    let isEditing: Bool
    let size: WidgetSize
    let isDragging: Bool
    let isSizeLocked: Bool
    let portalRestrictNoLarge: Bool
    let guidesRestrictNoSmall: Bool
    let onRemove: () -> Void
    let onSetSize: (WidgetSize) -> Void
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // پاشخانی کارتەکە بە شێوازی مۆدێرن
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                    
                    // ئایکۆنێک بۆ دیاریکردنی جۆری ویجێتەکە
                    Image(systemName: iconForKind(kind))
                        .foregroundStyle(.blue.opacity(0.8))
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(kind.descriptionText(size: size))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(size.spanY == 2 ? 6 : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(18)

            if isEditing {
                HStack(spacing: 8) {
                    Menu {
                        if !isSizeLocked {
                            if !guidesRestrictNoSmall { Button("Small") { onSetSize(.small) } }
                            Button("Wide") { onSetSize(.wide) }
                            Button("Tall") { onSetSize(.tall) }
                            if !portalRestrictNoLarge { Button("Large") { onSetSize(.large) } }
                        }
                    } label: {
                        Image(systemName: "aspectratio")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.blue.opacity(0.8), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: onRemove) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.red.opacity(0.8), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
        }
        // سێبەری مۆدێرن (Soft UI)
        .shadow(color: Color.black.opacity(isDragging ? 0.08 : 0.04), radius: isDragging ? 12 : 16, x: 0, y: isDragging ? 6 : 8)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture { onTap() }
    }
    
    // فەنکشنێک بۆ دانانی ئایکۆنی گونجاو بۆ هەر جۆرێک
    private func iconForKind(_ kind: WidgetKind) -> String {
        switch kind {
        case .guides: return "book.fill"
        case .stats: return "chart.bar.fill"
        case .updates: return "arrow.triangle.2.circlepath"
        case .recent: return "clock.fill"
        case .sourceApps: return "apps.iphone"
        case .portalVersion: return "server.rack"
        case .deviceStats: return "iphone.gen3"
        case .time: return "timer"
        case .socialMedia: return "network" // ئایکۆنی نوێ
        }
    }
}

// (کۆدەکانی WidgetsGridView, TwoColumnWidgetLayout، WidgetDragDropModifier وەک خۆیان دەمێننەوە. لێرە تەنها شتە نوێیەکان و جۆرەکان دادەنێم بۆ کورتی)

struct WidgetsGridView: View {
    @Binding var widgets: [WidgetState]
    @Binding var draggingID: UUID?
    @Binding var isEditing: Bool
    let page: Int
    let visibleWidgets: [WidgetState]
    let lockedKinds: Set<WidgetKind>
    let hPadding: CGFloat
    let spacing: CGFloat
    let baseHeight: CGFloat
    let gridMax: CGFloat
    let onCommit: () -> Void

    var body: some View {
        TwoColumnWidgetLayout(spacing: spacing, hPadding: hPadding, baseHeight: baseHeight, maxWidth: gridMax) {
            ForEach(visibleWidgets) { w in widgetView(w) }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onDrop(of: [UTType.text], isTargeted: nil) { _ in
            draggingID = nil
            onCommit()
            return true
        }
    }

    private func widgetView(_ widget: WidgetState) -> some View {
        let isLocked = lockedKinds.contains(widget.kind)
        let portalNoLarge = widget.kind == .portalVersion
        let guidesNoSmall = widget.kind == .guides

        return WidgetCard(
            title: widget.title, kind: widget.kind, isEditing: isEditing, size: widget.size, isDragging: draggingID == widget.id, isSizeLocked: isLocked, portalRestrictNoLarge: portalNoLarge, guidesRestrictNoSmall: guidesNoSmall,
            onRemove: { hideWidget(widgetID: widget.id) },
            onSetSize: { newSize in setSize(widgetID: widget.id, size: newSize) },
            onTap: { if !isEditing { UIImpactFeedbackGenerator(style: .light).impactOccurred() } }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .layoutValue(key: WidgetSpanKey.self, value: .init(spanX: widget.size.spanX, spanY: widget.size.spanY))
        .onLongPressGesture(minimumDuration: 0.35) {
            if !isEditing {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isEditing = true }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        .modifier(WidgetDragDropModifier(widget: widget, isEditing: isEditing, widgets: $widgets, draggingID: $draggingID, onCommit: onCommit))
    }

    private func setSize(widgetID: UUID, size: WidgetSize) {
        guard let idx = widgets.firstIndex(where: { $0.id == widgetID }) else { return }
        let kind = widgets[idx].kind
        if lockedKinds.contains(kind) { widgets[idx].size = .small; UIImpactFeedbackGenerator(style: .light).impactOccurred(); onCommit(); return }
        if kind == .portalVersion, size == .large { UIImpactFeedbackGenerator(style: .light).impactOccurred(); return }
        if kind == .guides, size == .small { UIImpactFeedbackGenerator(style: .light).impactOccurred(); return }
        widgets[idx].size = size; UIImpactFeedbackGenerator(style: .light).impactOccurred(); onCommit()
    }

    private func hideWidget(widgetID: UUID) {
        guard let idx = widgets.firstIndex(where: { $0.id == widgetID }) else { return }
        widgets[idx].isHidden = true; UIImpactFeedbackGenerator(style: .light).impactOccurred(); onCommit()
    }
}

struct WidgetSpan: Equatable { var spanX: Int; var spanY: Int }
struct WidgetSpanKey: LayoutValueKey { static var defaultValue: WidgetSpan = .init(spanX: 1, spanY: 1) }
struct PlacedItem { var index: Int; var row: Int; var col: Int; var spanX: Int; var spanY: Int }

struct TwoColumnWidgetLayout: Layout {
    typealias Cache = [PlacedItem]
    var spacing: CGFloat
    var hPadding: CGFloat
    var baseHeight: CGFloat
    var maxWidth: CGFloat
    func makeCache(subviews: Subviews) -> Cache { [] }
    func updateCache(_ cache: inout Cache, subviews: Subviews) { }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let w0 = proposal.width ?? UIScreen.main.bounds.width
        let effectiveWidth = min(w0, maxWidth)
        let rowStep = baseHeight + spacing
        cache.removeAll(keepingCapacity: true)
        var occ: [[Bool]] = []
        func ensureRows(_ r: Int) { while occ.count <= r { occ.append([false, false]) } }
        func canPlace(row r: Int, col c: Int, spanX: Int, spanY: Int) -> Bool {
            ensureRows(r + spanY - 1)
            if spanX == 2 && c != 0 { return false }
            if c < 0 || c > 1 { return false }
            for yy in 0..<spanY { for xx in 0..<spanX { let rr = r + yy; let cc = c + xx; if cc > 1 { return false }; if occ[rr][cc] { return false } } }
            return true
        }
        func mark(row r: Int, col c: Int, spanX: Int, spanY: Int) { ensureRows(r + spanY - 1); for yy in 0..<spanY { for xx in 0..<spanX { occ[r + yy][c + xx] = true } } }
        for i in subviews.indices {
            let span = subviews[i][WidgetSpanKey.self]
            let spanX = max(1, min(2, span.spanX)); let spanY = max(1, min(2, span.spanY))
            var placed = false; var r = 0
            while !placed {
                ensureRows(r)
                if spanX == 2 {
                    if canPlace(row: r, col: 0, spanX: 2, spanY: spanY) { mark(row: r, col: 0, spanX: 2, spanY: spanY); cache.append(.init(index: i, row: r, col: 0, spanX: 2, spanY: spanY)); placed = true } else { r += 1 }
                } else {
                    if canPlace(row: r, col: 0, spanX: 1, spanY: spanY) { mark(row: r, col: 0, spanX: 1, spanY: spanY); cache.append(.init(index: i, row: r, col: 0, spanX: 1, spanY: spanY)); placed = true }
                    else if canPlace(row: r, col: 1, spanX: 1, spanY: spanY) { mark(row: r, col: 1, spanX: 1, spanY: spanY); cache.append(.init(index: i, row: r, col: 1, spanX: 1, spanY: spanY)); placed = true }
                    else { r += 1 }
                }
            }
        }
        var maxBottom: CGFloat = 0
        for item in cache { let y = CGFloat(item.row) * rowStep; let height = CGFloat(item.spanY) * baseHeight + CGFloat(item.spanY - 1) * spacing; maxBottom = max(maxBottom, y + height) }
        return CGSize(width: effectiveWidth, height: maxBottom)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let effectiveWidth = min(bounds.width, maxWidth); let innerWidth = max(0, effectiveWidth - (hPadding * 2)); let colWidth = (innerWidth - spacing) / 2; let rowStep = baseHeight + spacing
        let originX = bounds.minX + (bounds.width - effectiveWidth) / 2 + hPadding; let originY = bounds.minY
        for item in cache {
            let x = originX + CGFloat(item.col) * (colWidth + spacing); let y = originY + CGFloat(item.row) * rowStep; let width = item.spanX == 2 ? (colWidth * 2 + spacing) : colWidth; let height = CGFloat(item.spanY) * baseHeight + CGFloat(item.spanY - 1) * spacing
            subviews[item.index].place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: width, height: height))
        }
    }
}

struct WidgetDragDropModifier: ViewModifier {
    let widget: WidgetState; let isEditing: Bool; @Binding var widgets: [WidgetState]; @Binding var draggingID: UUID?; let onCommit: () -> Void
    func body(content: Content) -> some View {
        if !isEditing { content } else {
            content.transaction { $0.animation = nil }.opacity(draggingID == widget.id ? 0 : 1).onDrag {
                draggingID = widget.id; UIImpactFeedbackGenerator(style: .light).impactOccurred(); return NSItemProvider(object: widget.id.uuidString as NSString)
            } preview: { Color.clear.frame(width: 1, height: 1).opacity(0.0001) }.onDrop(of: [UTType.text], delegate: WidgetDropDelegate(targetID: widget.id, widgets: $widgets, draggingID: $draggingID, onCommit: onCommit))
        }
    }
}

struct WidgetDropDelegate: DropDelegate {
    let targetID: UUID; @Binding var widgets: [WidgetState]; @Binding var draggingID: UUID?; let onCommit: () -> Void
    func dropEntered(info: DropInfo) {
        guard let fromID = draggingID, fromID != targetID else { return }
        guard let fromIndex = widgets.firstIndex(where: { $0.id == fromID }), let toIndex = widgets.firstIndex(where: { $0.id == targetID }) else { return }
        if widgets[fromIndex].page != widgets[toIndex].page { return }
        if fromIndex == toIndex { return }
        withAnimation(.spring(response: 0.20, dampingFraction: 0.92)) { let item = widgets.remove(at: fromIndex); widgets.insert(item, at: toIndex) }
    }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool { draggingID = nil; UIImpactFeedbackGenerator(style: .medium).impactOccurred(); onCommit(); return true }
    func dropEnded(info: DropInfo) { draggingID = nil; onCommit() }
}

struct AddWidgetsSheet: View {
    let hiddenWidgets: [WidgetState]
    let onAdd: (WidgetKind) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if hiddenWidgets.isEmpty {
                    Text("Nothing to add right now.").foregroundStyle(.secondary)
                } else {
                    ForEach(hiddenWidgets) { w in
                        Button { onAdd(w.kind) } label: { HStack { Text(w.title); Spacer(); Image(systemName: "plus.circle.fill").foregroundStyle(.blue) } }
                    }
                }
            }
            .navigationTitle("Add Widgets")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.bold) } }
        }
    }
}

enum WidgetSize: String, Codable, CaseIterable {
    case small, wide, tall, large
    var spanX: Int { switch self { case .small, .tall: return 1; case .wide, .large: return 2 } }
    var spanY: Int { switch self { case .small, .wide: return 1; case .tall, .large: return 2 } }
}

// MARK: - زیادکردنی جۆری سۆشیاڵ میدیا بۆ ناو ویجێتەکان
enum WidgetKind: String, Codable, CaseIterable {
    case guides, stats, updates, recent, sourceApps, portalVersion, deviceStats, time
    case socialMedia // ← جۆرە نوێیەکە

    func descriptionText(size: WidgetSize) -> String {
        switch self {
        case .guides: return size.spanY == 2 ? "Tap for guides, tips, and helpful explanations." : "Tap for informational guides."
        case .stats: return "Stats widget placeholder."
        case .updates: return "Updates widget placeholder."
        case .recent: return "Recent widget placeholder."
        case .sourceApps: return "Source Apps widget placeholder."
        case .portalVersion: return "Portal Version widget placeholder."
        case .deviceStats: return "Device Stats widget placeholder."
        case .time: return "Time widget placeholder."
        case .socialMedia: return "Your connected social profiles." // پەیامی جۆرە نوێیەکە
        }
    }
}

struct WidgetState: Identifiable, Codable, Equatable {
    var id: UUID; var kind: WidgetKind; var title: String; var size: WidgetSize; var isHidden: Bool; var page: Int
    init(id: UUID, kind: WidgetKind, title: String, size: WidgetSize, isHidden: Bool = false, page: Int = 0) {
        self.id = id; self.kind = kind; self.title = title; self.size = size; self.isHidden = isHidden; self.page = page
    }
    enum CodingKeys: String, CodingKey { case id, kind, title, size, isHidden, isBig, page }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        kind = (try? c.decode(WidgetKind.self, forKey: .kind)) ?? .guides
        title = (try? c.decode(String.self, forKey: .title)) ?? "Widget"
        isHidden = (try? c.decode(Bool.self, forKey: .isHidden)) ?? false
        page = (try? c.decode(Int.self, forKey: .page)) ?? 0
        if let size = try? c.decode(WidgetSize.self, forKey: .size) { self.size = size }
        else if (try? c.decode(Bool.self, forKey: .isBig)) == true { self.size = .large }
        else { self.size = .small }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self); try c.encode(id, forKey: .id); try c.encode(kind, forKey: .kind); try c.encode(title, forKey: .title); try c.encode(size, forKey: .size); try c.encode(isHidden, forKey: .isHidden); try c.encode(page, forKey: .page)
    }

    // MARK: - لێرەدا ویجێتی Socials ـم بۆ ڕیزبەندییە سەرەتاییەکە زیاد کردووە
    static var defaultWidgets: [WidgetState] {
        [
            .init(id: UUID(), kind: .guides, title: "Guides", size: .wide, page: 0),
            .init(id: UUID(), kind: .socialMedia, title: "Socials", size: .small, page: 0), // ← ویجێتە نوێیەکە پێشان دەدرێت
            .init(id: UUID(), kind: .stats, title: "Stats", size: .small, page: 0),
            .init(id: UUID(), kind: .updates, title: "Updates", size: .small, page: 0),
            .init(id: UUID(), kind: .recent, title: "Recent", size: .small, page: 0),
            .init(id: UUID(), kind: .sourceApps, title: "Source Apps", size: .small, page: 0),
            .init(id: UUID(), kind: .portalVersion, title: "Portal Version", size: .small, page: 1),
            .init(id: UUID(), kind: .deviceStats, title: "Device", size: .small, page: 1),
            .init(id: UUID(), kind: .time, title: "Time", size: .small, page: 1)
        ]
    }
}
