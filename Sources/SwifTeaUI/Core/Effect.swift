import Foundation

public struct Effect<Action>: Sendable {
    public typealias Send = @Sendable (Action) -> Void

    private let priority: TaskPriority?
    private let operation: @Sendable (@escaping Send) async -> Void

    public init(
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable (@escaping Send) async -> Void
    ) {
        self.priority = priority
        self.operation = operation
    }

    @usableFromInline
    func run(send: @escaping Send) async {
        await operation(send)
    }

    @usableFromInline
    var taskPriority: TaskPriority? {
        priority
    }
}

public extension Effect {
    func map<NewAction>(_ transform: @escaping (Action) -> NewAction) -> Effect<NewAction> {
        Effect<NewAction>(priority: taskPriority) { send in
            await run { action in
                send(transform(action))
            }
        }
    }

    static func fire(_ action: Action) -> Effect<Action> {
        Effect { send in
            send(action)
        }
    }

    static func run(
        priority: TaskPriority? = nil,
        _ operation: @escaping @Sendable (_ send: @escaping Send) async throws -> Void
    ) -> Effect<Action> {
        Effect(priority: priority) { send in
            do {
                try await operation { action in
                    guard !Task.isCancelled else { return }
                    send(action)
                }
            } catch is CancellationError {
                // Ignore cancellations
            } catch {
                // Failure inside an effect should not crash the runtime.
            }
        }
    }

    static func timer(
        every interval: TimeInterval,
        initialDelay: TimeInterval? = nil,
        repeats: Bool = true,
        priority: TaskPriority? = nil,
        action: @escaping @Sendable () -> Action
    ) -> Effect<Action> {
        Effect(priority: priority) { send in
            let intervalNanoseconds = interval.nanosecondsClamped()
            let delayNanoseconds = (initialDelay ?? interval).nanosecondsClamped()

            func sleep(_ nanos: UInt64) async throws {
                guard nanos > 0 else { return }
                try await Task.sleep(nanoseconds: nanos)
            }

            do {
                try await sleep(delayNanoseconds)
                if Task.isCancelled { return }
                send(action())

                guard repeats else { return }

                while !Task.isCancelled {
                    try await sleep(intervalNanoseconds)
                    if Task.isCancelled { break }
                    send(action())
                }
            } catch is CancellationError {
                // Timer cancelled; nothing else to do.
            } catch {
                // Ignore timer errors to keep runtime stable.
            }
        }
    }
}

private extension TimeInterval {
    func nanosecondsClamped() -> UInt64 {
        if self.isNaN || self <= 0 {
            return 0
        }
        let capped = min(self, TimeInterval(UInt64.max) / 1_000_000_000)
        return UInt64(capped * 1_000_000_000)
    }
}
