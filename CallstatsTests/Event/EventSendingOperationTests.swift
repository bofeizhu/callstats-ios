//
//  EventSendingOperationTests.swift
//  CallstatsTests
//
//  Created by Amornchai Kanokpullwad on 9/24/18.
//  Copyright © 2018 callstats. All rights reserved.
//

import XCTest
@testable import Callstats

class EventSendingOperationTests: XCTestCase {

    private var httpClient: StubHttpClient!
    
    override func setUp() {
        httpClient = StubHttpClient()
    }
    
    func testSuccessResponse() {
        let exp = expectation(description: "call http client")
        let operation = EventSendingOperation(httpClient: httpClient, event: TestEvent()) { e, s, r in
            XCTAssertTrue(s)
            XCTAssertEqual(r?["status"] as? String, "OK")
            exp.fulfill()
        }
        operation.start()
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFailedResponse() {
        httpClient.isFailed = true
        let exp = expectation(description: "call http client")
        let operation = EventSendingOperation(httpClient: httpClient, event: TestEvent()) { e, s, r in
            XCTAssertFalse(s)
            XCTAssertEqual(r?["status"] as? String, "ERROR")
            exp.fulfill()
        }
        operation.start()
        waitForExpectations(timeout: 1, handler: nil)
    }
}

private class StubHttpClient: HttpClient {
    var isFailed = false
    var successResponse: Response = .success(code: 200, dict: ["status": "OK"])
    var failedResponse: Response = .failed(code: 400, dict: ["status": "ERROR"])
    func sendRequest(request: URLRequest, completion: @escaping (Response) -> Void) {
        completion(isFailed ? failedResponse : successResponse)
    }
}

private class TestEvent: Event, Encodable {
    var localID: String = ""
    var deviceID: String = ""
    var timestamp: Int64 = 0
    func url() -> String { return "" }
    func path() -> String { return "" }
}
