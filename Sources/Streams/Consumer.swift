import Foundation

/**
 Consumes events/items from a `Channel`. Invokes the given block for each event/item
 */
public class Consumer<T> {
    private let notifyBlock: (T) -> Void

    public init(notifyBlock: @escaping (T) -> Void) {
        self.notifyBlock = notifyBlock
    }

    internal func notify(item: T) {
        notifyBlock(item)
    }
}
