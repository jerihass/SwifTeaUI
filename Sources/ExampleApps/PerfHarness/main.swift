import Foundation
import GalleryExample
import SwifTeaUI

@main
struct SwifTeaPerfHarness {
    static func main() {
        let config = Config.fromEnvironment()
        let size = TerminalSize(columns: config.columns, rows: config.rows)
        let renderFrame = GalleryPerfSupport.makeRenderer()

        TerminalDimensions.withTemporarySize(size) {
            // Warm-up to stabilize caches/JIT.
            for _ in 0..<config.warmupIterations {
                _ = renderFrame()
            }

            var renderTimes: [UInt64] = []
            var writeTimes: [UInt64] = []
            var byteCounts: [Int] = []
            renderTimes.reserveCapacity(config.sampleIterations)
            writeTimes.reserveCapacity(config.sampleIterations)
            byteCounts.reserveCapacity(config.sampleIterations)

            let sink = FileHandle(forWritingAtPath: "/dev/null") ?? .standardOutput

            for _ in 0..<config.sampleIterations {
                let renderStart = DispatchTime.now().uptimeNanoseconds
                let frame = renderFrame()
                let renderElapsed = DispatchTime.now().uptimeNanoseconds - renderStart

                let writeStart = DispatchTime.now().uptimeNanoseconds
                if let data = frame.data(using: .utf8) {
                    try? sink.write(contentsOf: data)
                    byteCounts.append(data.count)
                } else {
                    byteCounts.append(0)
                }
                let writeElapsed = DispatchTime.now().uptimeNanoseconds - writeStart

                renderTimes.append(renderElapsed)
                writeTimes.append(writeElapsed)
            }

            let renderStats = Stats(renderTimes)
            let writeStats = Stats(writeTimes)
            let byteStats = ByteStats(byteCounts)

            let report = Report(
                timestamp: ISO8601DateFormatter().string(from: Date()),
                commit: config.commit,
                runID: config.runID,
                config: config,
                render: renderStats.snapshot,
                write: writeStats.snapshot,
                bytes: byteStats.snapshot
            )

            ReportPrinter.printHuman(report)
            if let path = config.outputPath {
                ReportPrinter.writeJSON(report, to: path)
            }
        }
    }

    private struct Config: Codable {
        var warmupIterations: Int = 20
        var sampleIterations: Int = 200
        var columns: Int = 120
        var rows: Int = 40
        var commit: String? = nil
        var outputPath: String? = nil
        var runID: String? = nil

        private enum CodingKeys: String, CodingKey {
            case warmupIterations
            case sampleIterations
            case columns
            case rows
            case commit
            case runID
        }

        static func fromEnvironment() -> Config {
            var config = Config()
            if let value = ProcessInfo.processInfo.environment["PERF_WARMUPS"], let warmups = Int(value), warmups > 0 {
                config.warmupIterations = warmups
            }
            if let value = ProcessInfo.processInfo.environment["PERF_SAMPLES"], let samples = Int(value), samples > 0 {
                config.sampleIterations = samples
            }
            if let value = ProcessInfo.processInfo.environment["PERF_COLUMNS"], let columns = Int(value), columns > 0 {
                config.columns = columns
            }
            if let value = ProcessInfo.processInfo.environment["PERF_ROWS"], let rows = Int(value), rows > 0 {
                config.rows = rows
            }
            if let value = ProcessInfo.processInfo.environment["PERF_COMMIT"], !value.isEmpty {
                config.commit = value
            }
            if let value = ProcessInfo.processInfo.environment["PERF_OUTPUT_PATH"], !value.isEmpty {
                config.outputPath = value
            }
            if let value = ProcessInfo.processInfo.environment["PERF_RUN_ID"], !value.isEmpty {
                config.runID = value
            }
            return config
        }
    }

    private struct Stats {
        let mean: Double
        let median: Double
        let p95: Double
        let max: UInt64

        init(_ samples: [UInt64]) {
            guard !samples.isEmpty else {
                self.mean = 0
                self.median = 0
                self.p95 = 0
                self.max = 0
                return
            }

            let total = samples.reduce(0, +)
            mean = Double(total) / Double(samples.count)

            let sorted = samples.sorted()
            median = Double(sorted[sorted.count / 2])
            let p95Index = Int(Double(sorted.count - 1) * 0.95)
            p95 = Double(sorted[p95Index])
            max = sorted.last ?? 0
        }

        var snapshot: StatSnapshot {
            StatSnapshot(
                meanNS: mean,
                medianNS: median,
                p95NS: p95,
                maxNS: Double(max)
            )
        }

        var meanMS: String { format(mean) }
        var medianMS: String { format(median) }
        var p95MS: String { format(p95) }
        var maxMS: String { format(Double(max)) }

        private func format(_ nanoseconds: Double) -> String {
            String(format: "%.3f", nanoseconds / 1_000_000)
        }
    }

    private struct ByteStats {
        let mean: Int
        let median: Int
        let max: Int

        init(_ samples: [Int]) {
            guard !samples.isEmpty else {
                self.mean = 0
                self.median = 0
                self.max = 0
                return
            }
            let total = samples.reduce(0, +)
            mean = Int(Double(total) / Double(samples.count))
            let sorted = samples.sorted()
            median = sorted[sorted.count / 2]
            max = sorted.last ?? 0
        }

        var snapshot: ByteSnapshot {
            ByteSnapshot(mean: mean, median: median, max: max)
        }
    }

    private struct Report: Codable {
        var version: Int = 1
        var timestamp: String
        var commit: String?
        var runID: String?
        var config: Config
        var render: StatSnapshot
        var write: StatSnapshot
        var bytes: ByteSnapshot
    }

    private struct StatSnapshot: Codable {
        var meanNS: Double
        var medianNS: Double
        var p95NS: Double
        var maxNS: Double

        var meanMS: String { Self.format(meanNS) }
        var medianMS: String { Self.format(medianNS) }
        var p95MS: String { Self.format(p95NS) }
        var maxMS: String { Self.format(maxNS) }

        private static func format(_ nanoseconds: Double) -> String {
            String(format: "%.3f", nanoseconds / 1_000_000)
        }
    }

    private struct ByteSnapshot: Codable {
        var mean: Int
        var median: Int
        var max: Int
    }

    private enum ReportPrinter {
        static func printHuman(_ report: Report) {
            print("=== SwifTea Perf Harness (Gallery) ===")
            print("Terminal: \(report.config.columns)x\(report.config.rows)")
            print("Warmups: \(report.config.warmupIterations) | Samples: \(report.config.sampleIterations)")
            if let commit = report.commit {
                print("Commit: \(commit)")
            }
            print("- render (ms): mean \(report.render.meanMS), median \(report.render.medianMS), p95 \(report.render.p95MS), max \(report.render.maxMS)")
            print("- write  (ms): mean \(report.write.meanMS), median \(report.write.medianMS), p95 \(report.write.p95MS), max \(report.write.maxMS)")
            print("- bytes/frame: mean \(report.bytes.mean), median \(report.bytes.median), max \(report.bytes.max)")
        }

        static func writeJSON(_ report: Report, to path: String) {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            guard let data = try? encoder.encode(report) else { return }
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }
}
