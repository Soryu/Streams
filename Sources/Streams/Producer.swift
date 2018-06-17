import Foundation

/**
 Produces events/items and provides a `Channel` that `Consumers` can subscribe to
 */
public class Producer<T> {
    private var writableChannel = WritableChannel<T>()

    /**
     The `Channel` that consumers can subscribe to
     */
    public var channel: Channel<T> {
        return writableChannel
    }

    /**
     Push an item/event into the `Channel` to let consumers be notified about it
     */
    public func emit(_ item: T) {
        writableChannel.push(item)
    }
}
