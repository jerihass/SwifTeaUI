import SwifTeaCore
import SwifTeaUI

struct TaskRunnerView: TUIView {
    let state: TaskRunnerState

    var body: some TUIView {
        VStack(spacing: 1, alignment: .leading) {
            Text("SwifTea Task Runner")
                .foregroundColor(.yellow)
                .bold()

            Border(
                padding: 1,
                VStack(spacing: 1, alignment: .leading) {
                    Text("Press Enter to simulate long-running steps; spinner marks the active task.")
                        .foregroundColor(.cyan)
                    Text(renderSteps())
                }
            )

            StatusBar(
                leading: statusLeadingSegments,
                trailing: statusTrailingSegments
            )
        }
        .padding(1)
    }

    private let spinnerVariants: [(style: Spinner.Style, label: String)] = [
        (.ascii, "ASCII"),
        (.braille, "Braille"),
        (.dots, "Dots"),
        (.line, "Line")
    ]

    private func spinnerVariant(for index: Int) -> (style: Spinner.Style, label: String) {
        spinnerVariants[index % spinnerVariants.count]
    }

    private var statusLeadingSegments: [StatusBar.Segment] {
        var segments: [StatusBar.Segment] = [
            .init("Task Runner", color: .yellow)
        ]

        if let activeIndex = state.activeIndex {
            let variant = spinnerVariant(for: activeIndex)
            let label = "Step \(activeIndex + 1)/\(state.totalCount) (\(variant.label))"
            let spinnerText = Spinner(
                label: label,
                style: variant.style,
                color: .cyan,
                isBold: true
            ).render()
            segments.append(.init(spinnerText))
        } else if state.isComplete {
            segments.append(.init("All tasks complete", color: .green))
        } else {
            segments.append(.init("Press Enter to start", color: .cyan))
        }

        let meter = ProgressMeter(
            value: state.progressFraction,
            width: 20,
            style: .tinted(.cyan)
        ).render()
        segments.append(.init(meter))

        return segments
    }

    private var statusTrailingSegments: [StatusBar.Segment] {
        var segments: [StatusBar.Segment] = [
            .init("[Enter] advance", color: .yellow),
            .init("[f] fail", color: .yellow),
            .init("[r] reset", color: .yellow),
            .init("[q] quit", color: .yellow)
        ]

        if let toast = state.activeToast {
            segments.append(.init("• \(toast.text)", color: toast.color))
        }

        return segments
    }

    private func renderSteps() -> String {
        state.steps.enumerated().map { index, step in
            let indicator = indicator(for: step.status, index: index)
            let title = colorize(
                "\(index + 1). \(step.title)",
                color: titleColor(for: step.status)
            )
            let status = colorize(
                statusText(for: step.status, index: index),
                color: statusColor(for: step.status)
            )
            return "\(indicator)  \(title) \(status)"
        }.joined(separator: "\n")
    }

    private func indicator(for status: TaskRunnerState.Step.Status, index: Int) -> String {
        switch status {
        case .pending:
            return colorize("•", color: .yellow)
        case .running:
            let variant = spinnerVariant(for: index)
            return Spinner(style: variant.style, color: .cyan, isBold: true).render()
        case .completed(.success):
            return colorize("✓", color: .green, bold: true)
        case .completed(.failure):
            return colorize("✘", color: .yellow, bold: true)
        }
    }

    private func titleColor(for status: TaskRunnerState.Step.Status) -> ANSIColor {
        switch status {
        case .pending, .completed(.failure):
            return .yellow
        case .running:
            return .cyan
        case .completed(.success):
            return .green
        }
    }

    private func statusText(for status: TaskRunnerState.Step.Status, index: Int) -> String {
        switch status {
        case .pending:
            return "pending"
        case .running:
            let variant = spinnerVariant(for: index)
            return "running (\(variant.label))"
        case .completed(.success):
            return "completed"
        case .completed(.failure):
            return "failed"
        }
    }

    private func statusColor(for status: TaskRunnerState.Step.Status) -> ANSIColor {
        switch status {
        case .pending, .completed(.failure):
            return .yellow
        case .running:
            return .cyan
        case .completed(.success):
            return .green
        }
    }

    private func colorize(_ text: String, color: ANSIColor, bold: Bool = false) -> String {
        var prefix = color.rawValue
        if bold {
            prefix += "\u{001B}[1m"
        }
        return prefix + text + ANSIColor.reset.rawValue
    }
}
