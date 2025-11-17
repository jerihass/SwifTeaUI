
public struct Sidebar<Item>: TUIView {
    public typealias Body = Never

    public var body: Never {
        fatalError("Sidebar has no body")
    }
    public struct Style {
        public var titleColor: ANSIColor
        public var selectedColor: ANSIColor
        public var selectedFocusedColor: ANSIColor
        public var unselectedColor: ANSIColor
        public var selectedIndicator: String
        public var unselectedIndicator: String
        public var focusIndicator: String
        public var unfocusedIndicator: String
        public var borderPadding: Int
        public var focusStyle: FocusStyle
        public var showsBorder: Bool

        public init(
            titleColor: ANSIColor = .yellow,
            selectedColor: ANSIColor = .yellow,
            selectedFocusedColor: ANSIColor = .cyan,
            unselectedColor: ANSIColor = .green,
            selectedIndicator: String = ">",
            unselectedIndicator: String = " ",
            focusIndicator: String = "▌",
            unfocusedIndicator: String = " ",
            borderPadding: Int = 1,
            focusStyle: FocusStyle = .default,
            showsBorder: Bool = true
        ) {
            self.titleColor = titleColor
            self.selectedColor = selectedColor
            self.selectedFocusedColor = selectedFocusedColor
            self.unselectedColor = unselectedColor
            self.selectedIndicator = selectedIndicator
            self.unselectedIndicator = unselectedIndicator
            self.focusIndicator = focusIndicator
            self.unfocusedIndicator = unfocusedIndicator
            self.borderPadding = max(0, borderPadding)
            self.focusStyle = focusStyle
            self.showsBorder = showsBorder
        }
    }

    private let title: String
    private let items: [Item]
    private let selection: Int?
    private let isFocused: Bool
    private let style: Style
    private let label: (Item) -> String

    public init(
        title: String,
        items: [Item],
        selection: Int?,
        isFocused: Bool,
        style: Style = Style(),
        label: @escaping (Item) -> String
    ) {
        self.title = title
        self.items = items
        self.selection = selection
        self.isFocused = isFocused
        self.style = style
        self.label = label
    }

    public func render() -> String {
        let coloredLines = items.enumerated().map { index, element -> String in
            let isSelected = index == selection
            let indicator = isSelected ? style.selectedIndicator : style.unselectedIndicator
            let focusMarker = (isSelected && isFocused) ? style.focusIndicator : style.unfocusedIndicator
            let line = "\(indicator)\(focusMarker) \(label(element))"
            let color = color(forSelected: isSelected, focused: isFocused && isSelected)
            let base = color.rawValue + line + ANSIColor.reset.rawValue
            if isSelected && isFocused {
                return style.focusStyle.apply(to: base)
            }
            return base
        }

        let listBlock = coloredLines.joined(separator: "\n")

        let titleView: Text = {
            if isFocused {
                return Text(style.focusStyle.apply(to: title))
            } else {
                return Text(title).foregroundColor(style.titleColor)
            }
        }()

        let content = VStack(alignment: .leading) {
            titleView
            Text(listBlock)
        }

        if style.showsBorder {
            return content
                .focusRing(
                    padding: style.borderPadding,
                    isFocused: isFocused,
                    style: style.focusStyle
                )
                .render()
        }

        return content.render()
    }

    private func color(forSelected selected: Bool, focused: Bool) -> ANSIColor {
        if selected {
            return focused ? style.selectedFocusedColor : style.selectedColor
        }
        return style.unselectedColor
    }
}
