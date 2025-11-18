import Foundation
import SwifTeaUI
import GalleryExample

@main
struct PreviewDemoCLI {
    static func main() throws {
        let providers: [TUIViewPreviewProvider.Type] = [
            HelloWorldPreviewProvider.self
        ]
        let catalog = PreviewCatalog(providers)
        let cli = PreviewCommand(catalog: catalog)
        let success = cli.run(arguments: Array(CommandLine.arguments.dropFirst()))
        if !success {
            exit(EXIT_FAILURE)
        }
    }
}

private struct PreviewCommand {
    struct Options {
        var list = false
        var previewName: String?
        var overrideSize: TerminalSize?
    }

    let catalog: PreviewCatalog

    func run(arguments: [String]) -> Bool {
        let options = parse(arguments: arguments)
        if options.list || options.previewName == nil {
            printAvailablePreviews()
            if options.previewName == nil {
                return true
            }
        }

        guard let name = options.previewName else {
            printUsage()
            return false
        }

        return render(previewNamed: name, overrideSize: options.overrideSize)
    }

    private func parse(arguments: [String]) -> Options {
        var options = Options()
        var iterator = arguments.makeIterator()
        while let arg = iterator.next() {
            switch arg {
            case "--list", "-l":
                options.list = true
            case "--preview", "-p":
                options.previewName = iterator.next()
            case "--size":
                if let value = iterator.next(),
                   let size = parseSize(value) {
                    options.overrideSize = size
                }
            case "--help", "-h":
                printUsage()
                exit(EXIT_SUCCESS)
            default:
                if arg.hasPrefix("--preview=") {
                    let value = String(arg.dropFirst("--preview=".count))
                    if !value.isEmpty {
                        options.previewName = value
                    }
                } else if arg.hasPrefix("--size=") {
                    let value = String(arg.dropFirst("--size=".count))
                    options.overrideSize = parseSize(value)
                } else if options.previewName == nil {
                    options.previewName = arg
                }
            }
        }
        return options
    }

    private func parseSize(_ value: String) -> TerminalSize? {
        let parts = value.lowercased().split(separator: "x")
        guard parts.count == 2,
              let columns = Int(parts[0]),
              let rows = Int(parts[1]) else { return nil }
        return TerminalSize(columns: columns, rows: rows)
    }

    private func printAvailablePreviews() {
        print("Available previews:")
        let grouped = catalog.groupedByCategory()
        let sortedKeys = Array(grouped.keys).sorted { (lhs, rhs) -> Bool in
            let left = lhs ?? ""
            let right = rhs ?? ""
            return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
        }

        for key in sortedKeys {
            if let key, !key.isEmpty {
                print("\n[\(key)]")
            }
            for preview in grouped[key] ?? [] {
                let sizeDescription: String
                if let size = preview.size {
                    sizeDescription = " (\(size.columns)x\(size.rows))"
                } else {
                    sizeDescription = ""
                }
                print("- \(preview.name)\(sizeDescription)")
            }
        }
        print("\nRun with --preview <name> to render a preview.")
    }

    private func render(previewNamed name: String, overrideSize: TerminalSize?) -> Bool {
        guard let preview = catalog.previews.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            fputs("Preview named '\(name)' not found. Use --list to see options.\n", stderr)
            return false
        }

        let size = overrideSize ?? preview.size
        let output = PreviewRenderer.render(preview, terminalSize: size)
        print(output)
        return true
    }

    private func printUsage() {
        let usage = """
Usage: swift run SwifTeaPreviewDemo [--list] [--preview <name>] [--size <cols>x<rows>]

Options:
  --list, -l            List all available previews.
  --preview, -p NAME    Render the preview with the given name.
  --size COLSxROWS      Override terminal size when rendering.
  --help, -h            Show this help message.
"""
        print(usage)
    }
}
