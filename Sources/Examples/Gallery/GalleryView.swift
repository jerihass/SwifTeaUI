import SwifTeaUI

struct GalleryView: TUIView {
    let activeSection: GalleryModel.Section
    let contentView: AnyTUIView
    let shortcutsEnabled: Bool
    let theme: SwifTeaTheme

    var body: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            header
            accentDivider
            sectionSelector
            contentView
            StatusBar(
                leading: leadingSegments,
                trailing: trailingSegments
            )
        }
    }

    private var header: some TUIView {
        VStack(spacing: 0, alignment: .leading) {
            Text("SwifTea Gallery")
                .foregroundColor(theme.accent)
                .bold()
            Text("One executable demo that stitches together the original Notebook, Task Runner, and Package List examples.")
                .foregroundColor(theme.info)
            gradientBar
        }
    }

    private var accentDivider: some TUIView {
        gradientBar
    }

    private var gradientBar: some TUIView {
        GradientBar(
            colors: theme.accentGradient,
            width: 80,
            symbol: theme.accentGradientSymbol
        )
    }

    private var sectionSelector: some TUIView {
        HStack(spacing: 2, horizontalAlignment: .leading, verticalAlignment: .center) {
            ForEach(GalleryModel.Section.allCases, id: \.self) { section in
                sectionBadge(for: section)
            }
            Spacer()
        }
    }

    private func sectionBadge(for section: GalleryModel.Section) -> some TUIView {
        let isActive = section == activeSection
        let foreground = isActive ? theme.headerPanel.foreground : theme.primaryText
        let background = isActive ? (theme.headerPanel.background ?? theme.accent) : (theme.background ?? .brightBlack)
        let badgeText = Text("[\(section.shortcut)] \(section.title)")
            .foregroundColor(foreground)
            .bold()
        return AnyTUIView(
            Border(
                padding: 0,
                color: isActive ? theme.accent : theme.info,
                background: background,
                badgeText.padding(1)
            )
        )
    }

    private var leadingSegments: [StatusBar.Segment] {
        [
            .init("Gallery", color: theme.accent),
            .init(activeSection.title, color: theme.info)
        ]
    }

    private var trailingSegments: [StatusBar.Segment] {
        var segments: [StatusBar.Segment] = [
            .init("[1] Notebook", color: theme.info),
            .init("[2] Tasks", color: theme.success),
            .init("[3] Packages", color: theme.warning),
            .init("[4] ZStack", color: theme.accent),
            .init("[Tab] Next", color: theme.accent),
            .init("[Shift+Tab] Previous", color: theme.accent),
            .init("[?] Help", color: theme.info),
            .init("[Ctrl-C] Quit", color: theme.warning)
        ]
        if !shortcutsEnabled {
            segments.append(.init("Finish editing note to switch", color: theme.warning))
        }
        return segments
    }
}
