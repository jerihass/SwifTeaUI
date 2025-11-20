import Foundation

final class ActionQueue<Action> {
    private var buffer: [Action] = []
    private let lock = NSLock()

    func enqueue(_ action: Action) {
        lock.lock()
        buffer.append(action)
        lock.unlock()
    }

    func drain() -> [Action] {
        lock.lock()
        let actions = buffer
        buffer.removeAll(keepingCapacity: true)
        lock.unlock()
        return actions
    }
}

final class EffectRuntime<Action> {
    private let actionQueue: ActionQueue<Action>
    private let lock = NSLock()
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var keyedTasks: [AnyHashable: Set<UUID>] = [:]

    init(actionQueue: ActionQueue<Action>) {
        self.actionQueue = actionQueue
    }

    func run(_ effect: Effect<Action>, id: AnyHashable?, cancelExisting: Bool) {
        if cancelExisting, let id {
            cancel(id)
        }

        let effectID = UUID()
        let task = Task(priority: effect.taskPriority) { [weak self] in
            guard let self else { return }
            await effect.run { [weak self] action in
                self?.actionQueue.enqueue(action)
            }
        }

        lock.lock()
        tasks[effectID] = task
        if let id {
            var set = keyedTasks[id, default: []]
            set.insert(effectID)
            keyedTasks[id] = set
        }
        lock.unlock()
    }

    func cancel(_ effectID: UUID) {
        lock.lock()
        let task = tasks.removeValue(forKey: effectID)
        for key in keyedTasks.keys {
            keyedTasks[key]?.remove(effectID)
        }
        lock.unlock()
        task?.cancel()
    }

    func cancel(_ id: AnyHashable) {
        lock.lock()
        guard let effectIDs = keyedTasks.removeValue(forKey: id) else {
            lock.unlock()
            return
        }
        for effectID in effectIDs {
            tasks.removeValue(forKey: effectID)?.cancel()
        }
        lock.unlock()
    }

    func cancelAll() {
        lock.lock()
        let currentTasks = tasks.values
        tasks.removeAll()
        keyedTasks.removeAll()
        lock.unlock()
        for task in currentTasks {
            task.cancel()
        }
    }
}

private struct RuntimeDispatchBox {
    let sendAction: (Any) -> Void
    let runEffect: (Any, AnyHashable?, Bool) -> Void
    let cancelEffects: (AnyHashable) -> Void
    let requestRender: () -> Void
}

enum RuntimeDispatch {
    private static let lock = NSLock()
    private static var box: RuntimeDispatchBox?

    static func install<Action>(
        queue: ActionQueue<Action>,
        effectRuntime: EffectRuntime<Action>,
        renderInvalidation: RenderInvalidationFlag,
        body: () -> Void
    ) {
        lock.lock()
        box = RuntimeDispatchBox(
            sendAction: { anyAction in
                guard let action = anyAction as? Action else {
                    assertionFailure("Dispatched action does not match active scene Action type.")
                    return
                }
                queue.enqueue(action)
            },
            runEffect: { anyEffect, id, cancelExisting in
                guard let effect = anyEffect as? Effect<Action> else {
                    assertionFailure("Dispatched effect does not match active scene Action type.")
                    return
                }
                effectRuntime.run(effect, id: id, cancelExisting: cancelExisting)
            },
            cancelEffects: { id in
                effectRuntime.cancel(id)
            },
            requestRender: {
                renderInvalidation.markDirty()
            }
        )
        lock.unlock()

        body()

        lock.lock()
        box = nil
        lock.unlock()
    }

    static func dispatch<Action>(action: Action) {
        lock.lock()
        let current = box
        lock.unlock()
        guard let current else { return }
        current.sendAction(action)
    }

    static func dispatch<Action>(effect: Effect<Action>, id: AnyHashable?, cancelExisting: Bool) {
        lock.lock()
        let current = box
        lock.unlock()
        guard let current else { return }
        current.runEffect(effect, id, cancelExisting)
    }

    static func cancel(id: AnyHashable) {
        lock.lock()
        let current = box
        lock.unlock()
        current?.cancelEffects(id)
    }

    static func requestRender() {
        lock.lock()
        let current = box
        lock.unlock()
        current?.requestRender()
    }
}
