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
        case .quit:
            break
        }
    }

    func makeView() -> some TUIView {
        PackageListView(state: state, theme: .bubbleTeaNeon)
    }

    func mapKeyToAction(_ key: KeyEvent) -> Action? {
        switch key {
        case .char("f"), .char("o"):
            return .toggleOutdatedFilter
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
        case .toggleOutdatedFilter:
            return false
        }
    }
}

struct PackageListState {
    var packages: [PackageInfo]
    var showOnlyOutdated: Bool

    init(
        packages: [PackageInfo] = PackageInfo.samples,
        showOnlyOutdated: Bool = false
    ) {
        self.packages = packages
        self.showOnlyOutdated = showOnlyOutdated
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
        Text("[f] filter outdated • [q] quit")
            .foregroundColor(theme.warning)
            .italic()
    }

    private var tableView: some TUIView {
        Table(
            state.visiblePackages,
            divider: .line()
        ) {
            TableColumn("Package", width: .flex(min: 18)) { (package: PackageInfo) in
                Text(package.name).bold()
            }
            TableColumn("Version", width: .fitContent, alignment: .center) { (package: PackageInfo) in
                versionText(for: package)
            }
            TableColumn("Platform", width: .fitContent) { (package: PackageInfo) in
                Text(package.platform)
            }
            TableColumn("Status", width: .fitContent) { (package: PackageInfo) in
                Text(package.status.label)
                    .foregroundColor(package.status.color)
            }
            TableColumn("Updated", width: .fitContent) { (package: PackageInfo) in
                Text(package.lastUpdated)
            }
        } footer: {
            Text("\(state.visiblePackages.count) of \(state.packages.count) packages")
                .foregroundColor(.cyan)
        } rowStyle: { (package: PackageInfo, index: Int) in
            if case .outdated = package.status {
                return TableRowStyle(backgroundColor: .yellow, isBold: true)
            }
            if index.isMultiple(of: 2) {
                return TableRowStyle(backgroundColor: .cyan)
            }
            return nil
        }
    }

    private func versionText(for package: PackageInfo) -> Text {
        switch package.status {
        case .outdated(let latest):
            return Text("\(package.version) → \(latest)").foregroundColor(.yellow)
        default:
            return Text(package.version).foregroundColor(.green)
        }
    }

    private var statusLeadingSegments: [StatusBar.Segment] {
        let total = state.packages.count
        let outdated = state.packages.filter { if case .outdated = $0.status { return true } else { return false } }.count
        let missing = state.packages.filter { $0.status == .missing }.count
        return [
            .init("Packages", color: .yellow),
            .init("Total \(total)", color: .cyan),
            .init("Outdated \(outdated)", color: .yellow),
            .init("Missing \(missing)", color: .cyan)
        ]
    }

    private var statusTrailingSegments: [StatusBar.Segment] {
        [
            .init("[f] filter outdated", color: .yellow),
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
}
