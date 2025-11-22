import SwifTeaUI

public struct PackageListApp: TUIApp {
    public init() {}
    public static var framesPerSecond: Int { 20 }
    public var body: some TUIScene { PackageListScene() }
}

struct PackageListScene: TUIScene {
    typealias Model = PackageListModel
    typealias Action = PackageListModel.Action

    var model: PackageListModel

    init(model: PackageListModel = PackageListModel()) {
        self.model = model
    }

    mutating func update(action: Action) {
        model.update(action: action)
    }

    func view(model: PackageListModel) -> some TUIView {
        model.makeView()
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        model.mapKeyToAction(key)
    }

    func shouldExit(for action: Action) -> Bool {
        model.shouldExit(for: action)
    }
}

struct PackageListModel {
    enum Action {
        case toggleOutdatedFilter
        case focusNextPackage
        case focusPreviousPackage
        case toggleSelection
        case clearSelection
        case quit
    }

    @State private var state: PackageListState

    init(state: PackageListState = PackageListState()) {
        self._state = State(wrappedValue: state)
    }

    mutating func update(action: Action) {
        switch action {
        case .toggleOutdatedFilter:
            state.toggleOutdatedFilter()
            state.ensureFocusedPackageIsVisible()
        case .focusNextPackage:
            state.focusNext()
        case .focusPreviousPackage:
            state.focusPrevious()
        case .toggleSelection:
            state.toggleSelection()
        case .clearSelection:
            state.clearSelection()
        case .quit:
            break
        }
    }

    func makeView() -> some TUIView {
        PackageListView(state: state, theme: .basic)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("f"), .char("o"):
            return .toggleOutdatedFilter
        case .char("j"), .downArrow:
            return .focusNextPackage
        case .char("k"), .upArrow:
            return .focusPreviousPackage
        case .char(" "):
            return .toggleSelection
        case .char("x"):
            return .clearSelection
        case .char("q"), .escape, .ctrlC:
            return .quit
        default:
            return nil
        }
    }

    func shouldExit(for action: Action) -> Bool {
        switch action {
        case .quit:
            return true
        case .toggleOutdatedFilter,
             .focusNextPackage,
             .focusPreviousPackage,
             .toggleSelection,
             .clearSelection:
            return false
        }
    }
}

struct PackageListState {
    var packages: [PackageInfo]
    var showOnlyOutdated: Bool
    var focusedPackageID: Int?
    var selectedPackageIDs: Set<Int>

    init(
        packages: [PackageInfo] = PackageInfo.samples,
        showOnlyOutdated: Bool = false,
        focusedPackageID: Int? = nil,
        selectedPackageIDs: Set<Int> = []
    ) {
        self.packages = packages
        self.showOnlyOutdated = showOnlyOutdated
        self.focusedPackageID = focusedPackageID ?? packages.first?.id
        self.selectedPackageIDs = selectedPackageIDs
        ensureFocusedPackageIsVisible()
    }

    var visiblePackages: [PackageInfo] {
        guard showOnlyOutdated else { return packages }
        return packages.filter { package in
            switch package.status {
            case .outdated, .missing:
                return true
            case .installed:
                return false
            }
        }
    }

    mutating func toggleOutdatedFilter() {
        showOnlyOutdated.toggle()
    }

    mutating func ensureFocusedPackageIsVisible() {
        let visibleIDs = Set(visiblePackages.map(\.id))
        if let focusedPackageID, visibleIDs.contains(focusedPackageID) {
            return
        }
        focusedPackageID = visiblePackages.first?.id
    }

    mutating func focusNext() {
        let ids = visiblePackages.map(\.id)
        guard !ids.isEmpty else {
            focusedPackageID = nil
            return
        }
        guard let current = focusedPackageID,
              let currentIndex = ids.firstIndex(of: current) else {
            focusedPackageID = ids.first
            return
        }
        let nextIndex = (currentIndex + 1) % ids.count
        focusedPackageID = ids[nextIndex]
    }

    mutating func focusPrevious() {
        let ids = visiblePackages.map(\.id)
        guard !ids.isEmpty else {
            focusedPackageID = nil
            return
        }
        guard let current = focusedPackageID,
              let currentIndex = ids.firstIndex(of: current) else {
            focusedPackageID = ids.first
            return
        }
        let previousIndex = (currentIndex - 1 + ids.count) % ids.count
        focusedPackageID = ids[previousIndex]
    }

    mutating func toggleSelection() {
        guard let focusedPackageID else { return }
        if selectedPackageIDs.contains(focusedPackageID) {
            selectedPackageIDs.remove(focusedPackageID)
        } else {
            selectedPackageIDs.insert(focusedPackageID)
        }
    }

    mutating func clearSelection() {
        selectedPackageIDs.removeAll()
    }
}

struct PackageInfo: Identifiable {
    enum Status: Equatable {
        case installed
        case outdated(latestVersion: String)
        case missing

        var label: String {
            switch self {
            case .installed:
                return "Up-to-date"
            case .outdated(let version):
                return "Update → \(version)"
            case .missing:
                return "Not installed"
            }
        }

        var color: ANSIColor {
            switch self {
            case .installed:
                return .green
            case .outdated:
                return .yellow
            case .missing:
                return .cyan
            }
        }
    }

    let id: Int
    let name: String
    let version: String
    let platform: String
    let status: Status
    let lastUpdated: String

    static let samples: [PackageInfo] = [
        PackageInfo(
            id: 1,
            name: "Mint",
            version: "0.17.2",
            platform: "macOS",
            status: .installed,
            lastUpdated: "2 days ago"
        ),
        PackageInfo(
            id: 2,
            name: "Tuist",
            version: "4.0.0",
            platform: "macOS",
            status: .outdated(latestVersion: "4.0.1"),
            lastUpdated: "8 hours ago"
        ),
        PackageInfo(
            id: 3,
            name: "SwiftLint",
            version: "0.55.1",
            platform: "Cross-platform",
            status: .installed,
            lastUpdated: "5 days ago"
        ),
        PackageInfo(
            id: 4,
            name: "SwiftFormat",
            version: "0.52.3",
            platform: "Cross-platform",
            status: .missing,
            lastUpdated: "—"
        ),
        PackageInfo(
            id: 5,
            name: "Danger",
            version: "3.16.0",
            platform: "CI",
            status: .outdated(latestVersion: "3.17.0"),
            lastUpdated: "1 day ago"
        )
    ]
}

struct PackageListView: TUIView {
    let state: PackageListState
    let theme: SwifTeaTheme

    var body: some TUIView {
        MinimumTerminalSize(columns: 90, rows: 20) {
            VStack(spacing: 1, alignment: .leading) {
                header
                tableView
                instructions
                StatusBar(
                    leading: statusLeadingSegments,
                    trailing: statusTrailingSegments
                )
            }
            .padding(1)
        } fallback: { size in
            fallbackView(for: size)
        }
    }

    private var header: some TUIView {
        VStack(spacing: 0, alignment: .leading) {
            Text("Mint Package Dashboard")
                .foregroundColor(theme.accent)
                .bold()
                .underline()
            let filterText = state.showOnlyOutdated
                ? "Showing only outdated or missing packages."
                : "Showing all tracked packages."
            Text(filterText)
                .foregroundColor(theme.info)
        }
    }

    private var instructions: some TUIView {
        Text("[↑/↓] focus • [space] select • [x] clear • [f] filter outdated • [q] quit")
            .foregroundColor(theme.warning)
            .italic()
    }

    private var tableView: some TUIView {
        Table(
            state.visiblePackages,
            columnSpacing: 3,
            rowSpacing: 0,
            divider: .line(character: "─", color: theme.frameBorder, isBold: true),
            selection: selectionConfiguration,
            rowStyle: rowStyle(for:index:)
        ) {
            TableColumn("Package", width: .flex(min: 16)) { (package: PackageInfo) in
                Text(package.name)
                    .foregroundColor(theme.primaryText)
                    .bold()
            }
            TableColumn("Version", width: .flex(min: 14)) { (package: PackageInfo) in
                versionText(for: package)
            }
            TableColumn("Platform", width: .flex(min: 14)) { (package: PackageInfo) in
                Text(package.platform)
                    .foregroundColor(theme.info)
            }
            TableColumn("Status", width: .flex(min: 16)) { (package: PackageInfo) in
                Text(package.status.label)
                    .foregroundColor(package.status.color)
            }
            TableColumn("Last Updated", width: .fitContent, alignment: .trailing) { (package: PackageInfo) in
                Text(package.lastUpdated)
                    .foregroundColor(theme.mutedText)
            }
        }
    }

    private func versionText(for package: PackageInfo) -> Text {
        switch package.status {
        case .outdated(let latest):
            return Text("\(package.version) → \(latest)").foregroundColor(theme.warning)
        default:
            return Text(package.version).foregroundColor(.green)
        }
    }

    private var statusLeadingSegments: [StatusBar.Segment] {
        let total = state.packages.count
        let outdated = state.packages.filter { if case .outdated = $0.status { return true } else { return false } }.count
        let missing = state.packages.filter { $0.status == .missing }.count
        var segments: [StatusBar.Segment] = [
            .init("Packages", color: .yellow),
            .init("Total \(total)", color: .cyan),
            .init("Outdated \(outdated)", color: .yellow),
            .init("Missing \(missing)", color: .cyan)
        ]
        if state.selectedPackageIDs.count > 0 {
            segments.append(.init("Selected \(state.selectedPackageIDs.count)", color: theme.accent))
        }
        return segments
    }

    private var statusTrailingSegments: [StatusBar.Segment] {
        [
            .init("↑/↓ focus", color: .yellow),
            .init("[space] select", color: .yellow),
            .init("[f] filter", color: .yellow),
            .init("[q] quit", color: .yellow)
        ]
    }

    private func fallbackView(for size: TerminalSize) -> some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("Mint Package Dashboard")
                .foregroundColor(.yellow)
                .bold()
            Text("Needs at least 90×20, current is \(size.columns)×\(size.rows).")
                .foregroundColor(.cyan)
            Text("Resize the terminal to view the table.")
                .foregroundColor(.green)
        }
        .padding(1)
    }

    private var selectionConfiguration: TableSelectionConfiguration<Int> {
        TableSelectionConfiguration.multiple(
            .constant(state.selectedPackageIDs),
            focused: .constant(state.focusedPackageID),
            selectionStyle: TableRowStyle(
                foregroundColor: theme.primaryText,
                backgroundColor: theme.frameBorder,
                isBold: true
            ),
            focusedStyle: TableRowStyle.focused(accent: theme.accent)
        )
    }

    private func rowStyle(for package: PackageInfo, index: Int) -> TableRowStyle? {
        var baseStyle: TableRowStyle? = index.isMultiple(of: 2)
            ? TableRowStyle(backgroundColor: theme.background ?? .brightBlack, isDimmed: true)
            : nil

        switch package.status {
        case .missing:
            let missingStyle = TableRowStyle(
                foregroundColor: .black,
                backgroundColor: theme.info,
                isBold: true
            )
            baseStyle = baseStyle?.merging(missingStyle) ?? missingStyle
        case .outdated:
            let outdatedStyle = TableRowStyle(
                foregroundColor: theme.warning,
                isBold: true
            )
            baseStyle = baseStyle?.merging(outdatedStyle) ?? outdatedStyle
        case .installed:
            break
        }

        return baseStyle
    }
}
