import Foundation

struct TerminalInputParser: Sendable {
    private static let pasteStart: [UInt8] = [0x1B, 0x5B, 0x32, 0x30, 0x30, 0x7E]
    private static let pasteEnd: [UInt8] = [0x1B, 0x5B, 0x32, 0x30, 0x31, 0x7E]

    private let maximumPasteBytes: Int
    private var buffer: [UInt8] = []
    private var pasteBuffer: [UInt8]?
    private var pasteExceededLimit = false

    init(maximumPasteBytes: Int) {
        self.maximumPasteBytes = max(0, maximumPasteBytes)
    }

    mutating func append(_ bytes: [UInt8]) {
        buffer.append(contentsOf: bytes)
    }

    mutating func nextEvent(flushIncompleteEscape: Bool = false) -> TerminalInputEvent? {
        while true {
            if pasteBuffer != nil {
                return consumePasteBytes()
            }
            guard let first = buffer.first else { return nil }

            switch first {
            case 0x03:
                buffer.removeFirst()
                return .key(.ctrlC)
            case 0x09:
                buffer.removeFirst()
                return .key(.tab)
            case 0x0A, 0x0D:
                buffer.removeFirst()
                return .key(.enter)
            case 0x08, 0x7F:
                buffer.removeFirst()
                return .key(.backspace)
            case 0x1B:
                if buffer.starts(with: Self.pasteStart) {
                    buffer.removeFirst(Self.pasteStart.count)
                    pasteBuffer = []
                    pasteExceededLimit = false
                    continue
                }
                if Self.pasteStart.starts(with: buffer), !flushIncompleteEscape {
                    return nil
                }
                if buffer.count < 3, !flushIncompleteEscape {
                    return nil
                }
                if buffer.count >= 3, buffer[1] == 0x5B {
                    let key: KeyEvent?
                    switch buffer[2] {
                    case 0x41: key = .upArrow
                    case 0x42: key = .downArrow
                    case 0x43: key = .rightArrow
                    case 0x44: key = .leftArrow
                    case 0x5A: key = .backTab
                    default: key = nil
                    }
                    if let key {
                        buffer.removeFirst(3)
                        return .key(key)
                    }
                }
                buffer.removeFirst()
                return .key(.escape)
            default:
                guard first >= 0x20 else {
                    buffer.removeFirst()
                    continue
                }
                guard let length = utf8SequenceLength(first) else {
                    buffer.removeFirst()
                    continue
                }
                guard buffer.count >= length else { return nil }
                let bytes = Array(buffer.prefix(length))
                guard let decoded = String(bytes: bytes, encoding: .utf8), decoded.count == 1,
                    let character = decoded.first
                else {
                    buffer.removeFirst()
                    continue
                }
                buffer.removeFirst(length)
                return .key(.char(character))
            }
        }
    }

    private mutating func consumePasteBytes() -> TerminalInputEvent? {
        guard let endIndex = markerIndex(Self.pasteEnd, in: buffer) else {
            let retainedSuffixCount = markerPrefixSuffixLength(Self.pasteEnd, in: buffer)
            let consumedCount = buffer.count - retainedSuffixCount
            appendPaste(Array(buffer.prefix(consumedCount)))
            buffer.removeFirst(consumedCount)
            return nil
        }

        appendPaste(Array(buffer.prefix(endIndex)))
        buffer.removeFirst(endIndex + Self.pasteEnd.count)
        let completed = pasteBuffer ?? []
        pasteBuffer = nil
        defer { pasteExceededLimit = false }
        guard !pasteExceededLimit,
            let value = String(bytes: completed, encoding: .utf8)
        else { return nil }
        return .paste(value)
    }

    private mutating func appendPaste(_ bytes: [UInt8]) {
        guard !bytes.isEmpty else { return }
        guard !pasteExceededLimit else { return }
        let remaining = maximumPasteBytes - (pasteBuffer?.count ?? 0)
        guard bytes.count <= remaining else {
            if remaining > 0 {
                pasteBuffer?.append(contentsOf: bytes.prefix(remaining))
            }
            pasteExceededLimit = true
            return
        }
        pasteBuffer?.append(contentsOf: bytes)
    }
}

private func utf8SequenceLength(_ first: UInt8) -> Int? {
    switch first {
    case 0x20...0x7F: 1
    case 0xC2...0xDF: 2
    case 0xE0...0xEF: 3
    case 0xF0...0xF4: 4
    default: nil
    }
}

private func markerIndex(_ marker: [UInt8], in bytes: [UInt8]) -> Int? {
    guard bytes.count >= marker.count else { return nil }
    for index in 0...(bytes.count - marker.count) {
        if bytes[index..<(index + marker.count)].elementsEqual(marker) {
            return index
        }
    }
    return nil
}

private func markerPrefixSuffixLength(_ marker: [UInt8], in bytes: [UInt8]) -> Int {
    let maximum = min(marker.count - 1, bytes.count)
    guard maximum > 0 else { return 0 }
    for length in stride(from: maximum, through: 1, by: -1) {
        if bytes.suffix(length).elementsEqual(marker.prefix(length)) {
            return length
        }
    }
    return 0
}
