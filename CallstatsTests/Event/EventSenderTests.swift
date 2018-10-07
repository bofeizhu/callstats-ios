//
//  EventSenderTest.swift
//  CallstatsTests
//
//  Created by Amornchai Kanokpullwad on 9/28/18.
//  Copyright © 2018 callstats. All rights reserved.
//

import XCTest
@testable import Callstats

class EventSenderTests: XCTestCase {
    
    var operationQueue: FakeOperationQueue!
    var sender: EventSenderImpl!
    
    override func setUp() {
        operationQueue = FakeOperationQueue()
        sender = EventSenderImpl(
            httpClient: DummyHttpClient(),
            operationQueue: operationQueue,
            appID: "app1",
            localID: "local1",
            deviceID: "device1")
    }
    
    func testEventHasCorrectInfo() {
        let event = Event()
        sender.send(event: event)
        XCTAssertEqual(event.localID, "local1")
        XCTAssertEqual(event.deviceID, "device1")
    }
    
    func testEventWillNotOverrideTimeStamp() {
        let event = Event()
        event.timestamp = 123
        sender.send(event: event)
        XCTAssertEqual(event.timestamp, 123)
        event.timestamp = 0
        sender.send(event: event)
        XCTAssertNotEqual(event.timestamp, 0)
    }
    
    func testSendEventBeforeNeededState() {
        sender.send(event: AuthenticatedEvent())
        sender.send(event: SessionEvent())
        XCTAssertEqual(sender.authenticatedQueue.count, 1)
        XCTAssertEqual(sender.sessionQueue.count, 1)
    }
    
    func testSendEventInCorrectOrder() {
        sender.send(event: SessionEvent())
        sender.send(event: TestCreateSessionEvent())
        sender.send(event: TokenRequest(code: "code", clientID: "client"))
        XCTAssertTrue(operationQueue.sentOperations[0].event is TokenRequest)
        XCTAssertTrue(operationQueue.sentOperations[1].event is AuthenticatedEvent)
        XCTAssertTrue(operationQueue.sentOperations[2].event is SessionEvent)
    }
    
    func testNotSaveKeepAliveEvent() {
        sender.send(event: KeepAliveEvent())
        XCTAssertEqual(sender.sessionQueue.count, 0)
    }
}

class DummyHttpClient: HttpClient {
    func sendRequest(request: URLRequest, completion: @escaping (Response) -> Void) {}
}

class FakeOperationQueue: OperationQueue {
    var sentOperations: [EventSendingOperation] = []
    override func addOperation(_ op: Operation) {
        if let operation = op as? EventSendingOperation {
            sentOperations.append(operation)
            let data: [String: Any]
            switch operation.event {
            case is AuthenticationEvent: data = ["access_token": "1234"]
            case is CreateSessionEvent: data = ["ucID": "5678"]
            default: data = [:]
            }
            operation.completion?(operation.event, true, data)
        }
    }
}

class TestCreateSessionEvent: AuthenticatedEvent, CreateSessionEvent {
    var confID: String = "conf1"
}