import Foundation

/**
 Provides a way for `Consumers` to subscribe to items/events of a `Producer`
 */
public class Channel<T> {

    fileprivate class Subscriber<T> {
        weak var consumer: Consumer<T>?
        var callbackQueue: DispatchQueue

        init(consumer: Consumer<T>, callbackQueue: DispatchQueue) {
            self.consumer = consumer
            self.callbackQueue = callbackQueue
        }
    }

    // subclass keeping a strong reference to the consumer
    fileprivate class StrongSubscriber<T>: Subscriber<T> {
        var strongConsumer: Consumer<T>

        override init(consumer: Consumer<T>, callbackQueue: DispatchQueue) {
            self.strongConsumer = consumer
            super.init(consumer: consumer, callbackQueue: callbackQueue)
        }
    }

    // registered subscribers for this channel (consumer + callback q)
    fileprivate var subscribers = [String: Subscriber<T>]()
    // serialize access to the subscribers via this queue, to make it multi-threading safe
    fileprivate let channelQ = DispatchQueue(label: "ChannelQ", qos: .userInitiated)

    /**
     Subscribes a consumer to this channel that will be sent events/items using the given queue

     - Parameter consumer: The consumer. It will be referenced weakly.
     - Parameter callbackQueue: The queue on which the consumer’s notify method should be called on

     - Returns: An opaque token, that could be used to unsubscribe in the future, or maybe hold references (TODO)
     */
    public func subscribe(_ consumer: Consumer<T>, on callbackQueue: DispatchQueue = .main) -> Any {
        let token = UUID().uuidString
        channelQ.sync {
            subscribers[token] = Subscriber(consumer: consumer, callbackQueue: callbackQueue)
        }
        return token
    }

    /**
     Subscribes a consumer, keeping a strong reference to it

     - SeeAlso: `subscribe(_:on:)`
     */
    public func subscribeStrong(_ consumer: Consumer<T>, on q: DispatchQueue = .main) -> Any {
        let token = UUID().uuidString
        channelQ.sync {
            subscribers[token] = StrongSubscriber(consumer: consumer, callbackQueue: q)
        }
        return token
    }
}

internal final class WritableChannel<T>: Channel<T> {
    func push(_ item: T) {
        let subscribers = channelQ.sync {
            return self.subscribers
        }

        dispatch(item: item, to: [Subscriber<T>](subscribers.values))
    }

    private func dispatch(item: T, to subscribers: [Subscriber<T>]) {
        for subscriber in subscribers {
            guard let consumer = subscriber.consumer else { break }
            subscriber.callbackQueue.async {
                consumer.notify(item: item)
            }
        }
    }
}

extension Channel {

    final private class Transformer<T, U>: Consumer<T> {
        let producer: Producer<U>

        init(_ map: @escaping (T) -> (U)) {
            let producer = Producer<U>()
            self.producer = producer

            super.init { (item) in
                producer.emit(map(item))
            }
        }

        func transform(_ channel: Channel<T>, on q: DispatchQueue = .main) -> Channel<U> {
            // channel needs to keep a reference to Transformer, so subscribeStrong
            _ = channel.subscribeStrong(self, on: q)
            return producer.channel
        }
    }

    /**
     Transform values of a channel and return a new channel
     */
    public func map<U>(on q: DispatchQueue = .main, _ block: @escaping (T) -> (U)) -> Channel<U> {
        return Transformer<T, U>(block).transform(self, on: q)
    }
}
