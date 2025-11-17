import SwifTeaUI

struct GalleryView: TUIView {
    let activeSection: GalleryModel.Section
    let contentView: AnyTUIView
    let shortcutsEnabled: Bool

    var body: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            header
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
                .foregroundColor(.brightMagenta)
                .bold()
            Text("One executable demo that stitches together the original Notebook, Task Runner, and Package List examples.")
                .foregroundColor(.brightCyan)
        }
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
        let text = Text("[\(section.shortcut)] \(section.title)")
            .foregroundColor(isActive ? .black : .brightCyan)
            .backgroundColor(isActive ? .brightYellow : .brightBlack)
            .bold()
        return AnyTUIView(text.padding(1))
    }

    private var leadingSegments: [StatusBar.Segment] {
        [
            .init("Gallery", color: .brightMagenta),
            .init(activeSection.title, color: .brightYellow)
        ]
    }

    private var trailingSegments: [StatusBar.Segment] {
        var segments: [StatusBar.Segment] = [
            .init("[1] Notebook", color: .brightCyan),
            .init("[2] Tasks", color: .brightCyan),
            .init("[3] Packages", color: .brightCyan),
            .init("[Tab] Next", color: .brightCyan),
            .init("[Shift+Tab] Previous", color: .brightCyan),
            .init("[Ctrl-C] Quit", color: .brightCyan)
        ]
        if !shortcutsEnabled {
            segments.append(.init("Finish editing note to switch", color: .yellow))
        }
        return segments
    }
}
