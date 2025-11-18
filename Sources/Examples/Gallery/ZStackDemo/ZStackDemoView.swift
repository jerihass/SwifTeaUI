import SwifTeaUI

struct ZStackDemoView: TUIView {
    let theme: SwifTeaTheme

    private var canvasBackground: ANSIColor { theme.background ?? .brightBlack }

    var body: some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: canvasBackground,
            VStack(spacing: 2, alignment: .leading) {
                header
                layeredStatusStack
                modalOverlayStack
                nestedStacks
            }
        )
    }

    private var header: some TUIView {
        VStack(spacing: 0, alignment: .leading) {
            Text("ZStack Playground")
                .foregroundColor(theme.accent)
                .bold()
            Text("Each block renders a dedicated ZStack so you can see overlapping badges, modals, and nested overlays without shifting the base layout.")
                .foregroundColor(theme.mutedText)
        }
    }

    private var layeredStatusStack: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("Top-trailing badge")
                .foregroundColor(theme.info)
                .bold()
            ZStack(alignment: .topTrailing) {
                basePanel(
                    title: "Sync Dashboard",
                    detail: "Base content renders normally even while overlays appear."
                )
                badge(
                    text: "✓ Synced",
                    foreground: .black,
                    background: theme.success
                )
            }
        }
    }

    private var modalOverlayStack: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("Centered modal overlay")
                .foregroundColor(theme.info)
                .bold()
            ZStack(alignment: .center) {
                basePanel(
                    title: "Log Stream",
                    detail: "ZStack keeps the stream visible while modals float on top."
                )
                overlayCard(
                    title: "Deploy Preview",
                    lines: [
                        "Build #42 finished successfully.",
                        "Press Enter to acknowledge."
                    ],
                    accent: theme.accent
                )
            }
        }
    }

    private var nestedStacks: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("Nested stacks")
                .foregroundColor(theme.info)
                .bold()
            ZStack(alignment: .bottomTrailing) {
                basePanel(
                    title: "Terminal Canvas",
                    detail: "Combine stacked overlays for badges + contextual hints."
                )
                ZStack(alignment: .topLeading) {
                    overlayCard(
                        title: "Theme Preview",
                        lines: [
                            "Accent overlays stay bold and legible.",
                            "Info overlays show contextual hints."
                        ],
                        accent: theme.info
                    )
                    badge(
                        text: "Palette",
                        foreground: .brightWhite,
                        background: theme.accent
                    )
                }
            }
        }
    }

    private func basePanel(title: String, detail: String) -> some TUIView {
        Border(
            padding: 1,
            color: theme.frameBorder,
            background: canvasBackground,
            VStack(spacing: 1, alignment: .leading) {
                Text(title)
                    .foregroundColor(theme.primaryText)
                    .bold()
                Text(detail)
                    .foregroundColor(theme.mutedText)
            }
        )
    }

    private func overlayCard(
        title: String,
        lines: [String],
        accent: ANSIColor
    ) -> some TUIView {
        Border(
            padding: 1,
            color: accent,
            background: canvasBackground,
            VStack(spacing: 1, alignment: .leading) {
                Text(title)
                    .foregroundColor(accent)
                    .bold()
                ForEach(Array(lines.enumerated()), id: \.offset) { pair in
                    Text(pair.element)
                        .foregroundColor(theme.primaryText)
                }
            }
        )
    }

    private func badge(
        text: String,
        foreground: ANSIColor,
        background: ANSIColor
    ) -> some TUIView {
        Text(" \(text) ")
            .foregroundColor(foreground)
            .backgroundColor(background)
            .bold()
    }
}
