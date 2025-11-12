import Testing
import SwifTeaCore
@testable import SwifTeaUI

struct TableTests {
    private struct Package: Identifiable {
        let id: Int
        let name: String
        let version: String
        let status: String
    }

    @Test("Table renders headers, divider, and rows")
    func testBasicRendering() {
        let packages = [
            Package(id: 1, name: "Mint", version: "0.17.2", status: "Installed"),
            Package(id: 2, name: "Tuist", version: "4.0.0", status: "Outdated")
        ]

        let table = Table(packages, divider: .line()) {
            TableColumn(width: .fitContent, alignment: .leading, header: { Text("Package") }) { (item: Package) in
                Text(item.name)
            }
            TableColumn(width: .fitContent, alignment: .leading, header: { Text("Version") }) { (item: Package) in
                Text(item.version)
            }
            TableColumn(width: .fitContent, alignment: .leading, header: { Text("Status") }) { (item: Package) in
                Text(item.status)
            }
        } header: {
            Text("Packages")
        } footer: {
            Text("2 total")
        }

        let lines = table.render().split(separator: "\n").map(String.init)
        #expect(lines == [
            "Packages",
            "Package  Version  Status   ",
            "───────────────────────────",
            "Mint     0.17.2   Installed",
            "Tuist    4.0.0    Outdated ",
            "2 total"
        ])
    }

    @Test("Column width rules clamp output as requested")
    func testColumnWidthRules() {
        let packages = [
            Package(id: 1, name: "Mint", version: "0.17.2", status: "Installed")
        ]

        let table = Table(packages, columnSpacing: 1, divider: .none) {
            TableColumn(width: .fixed(10), alignment: .trailing, header: { Text("Name") }) { (item: Package) in
                Text(item.name)
            }
            TableColumn(width: .flex(min: 5, max: 8), alignment: .center, header: { Text("Ver") }) { (item: Package) in
                Text(item.version)
            }
        }

        let lines = table.render().split(separator: "\n").map(String.init)
        #expect(lines == [
            "      Name  Ver  ",
            "      Mint 0.17.2"
        ])
    }

    @Test("Row style closure applies ANSI styling per row")
    func testRowStyle() {
        let packages = [
            Package(id: 1, name: "Mint", version: "0.17.2", status: "Installed"),
            Package(id: 2, name: "Tuist", version: "4.0.0", status: "Outdated")
        ]

        let table = Table(
            packages,
            divider: .none
        ) {
            TableColumn(width: .fitContent, alignment: .leading, header: { Text("Name") }) { (item: Package) in
                Text(item.name)
            }
            TableColumn(width: .fitContent, alignment: .leading, header: { Text("Version") }) { (item: Package) in
                Text(item.version)
            }
        } rowStyle: { _, index in
            index == 0 ? TableRowStyle(backgroundColor: .cyan, isBold: true) : nil
        }

        let output = table.render()
        #expect(output.contains(ANSIColor.cyan.backgroundCode))
        #expect(output.contains("\u{001B}[1m"))
    }
}
