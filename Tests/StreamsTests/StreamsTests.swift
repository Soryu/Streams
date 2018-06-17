import XCTest
@testable import Streams

final class StreamsTests: XCTestCase {
    func testExample() {
        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 2

        var buffer = [String]()
        let consumer = Consumer<String> { item in
            buffer.append(item)
            exp.fulfill()
        }

        let producer = Producer<String>()
        producer.emit("a")

        _ = producer.channel.subscribe(consumer, on: DispatchQueue(label: "foo"))

        producer.emit("b")
        producer.emit("c")

        waitForExpectations(timeout: 1)
        XCTAssertEqual(buffer, ["b", "c"])
    }

    func testManualTransform() {

        class Transformer<T, U>: Consumer<T> {
            let producer: Producer<U>

            init(_ map: @escaping (T) -> (U)) {
                let producer = Producer<U>()
                self.producer = producer

                super.init { (item) in
                    producer.emit(map(item))
                }
            }

            func transform(_ channel: Channel<T>) -> Channel<U> {
                _ = channel.subscribe(self)
                return producer.channel
            }
        }


        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 1

        var buffer = [String]()
        let consumer = Consumer<String> { item in
            buffer.append(item)
            exp.fulfill()
        }

        let producer = Producer<String>()
        let t = Transformer<String, String> { $0 + "_foo" }
        _ = t.transform(producer.channel).subscribe(consumer, on: DispatchQueue(label: "foo"))

        producer.emit("b")

        waitForExpectations(timeout: 1)
        XCTAssertEqual(buffer, ["b_foo"])
    }

    func testMap() {
        let exp = expectation(description: "")
        exp.expectedFulfillmentCount = 3

        var buffer = [String]()
        let consumer = Consumer<String> { item in
            buffer.append(item)
            exp.fulfill()
        }

        let producer = Producer<String>()
        _ = producer.channel.map { $0 + "_bar" }.subscribe(consumer)

        producer.emit("x")
        producer.emit("y")
        producer.emit("z")

        waitForExpectations(timeout: 1)
        XCTAssertEqual(buffer, ["x_bar", "y_bar", "z_bar"])
    }

    func testWithoutConsumer() {
        let exp = expectation(description: "")
        exp.isInverted = true
        let producer = Producer<String>()

        DispatchQueue(label: "subscribe q").sync {
            let consumer = Consumer<String> { _ in
                exp.fulfill()
            }
            _ = producer.channel.subscribe(consumer)
        }

        producer.emit("x")
        waitForExpectations(timeout: 1)
    }


    static var allTests = [
        ("testExample", testExample),
        ("testManualTransform", testManualTransform),
        ("testMap", testMap),
        ("testWithoutConsumer", testWithoutConsumer),
    ]
}
