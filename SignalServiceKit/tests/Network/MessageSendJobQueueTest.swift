//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import XCTest
@testable import SignalServiceKit

class MessageSenderJobQueueTest: SSKBaseTestSwift {

    override func setUp() {
        super.setUp()
        self.databaseStorage.useGRDB = false
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: Dependencies

    private var messageSender: OWSFakeMessageSender {
        return MockSSKEnvironment.shared.messageSender as! OWSFakeMessageSender
    }

    // MARK: 

    func test_messageIsSent() {
        let message: TSOutgoingMessage = OutgoingMessageFactory().create()

        let expectation = sentExpectation(message: message)

        let jobQueue = MessageSenderJobQueue()
        jobQueue.setup()
        self.write { transaction in
            jobQueue.add(message: message, transaction: transaction)
        }

        self.wait(for: [expectation], timeout: 0.1)
    }

    func test_waitsForSetup() {
        let message: TSOutgoingMessage = OutgoingMessageFactory().create()

        let sentBeforeReadyExpectation = sentExpectation(message: message)
        sentBeforeReadyExpectation.isInverted = true

        let jobQueue = MessageSenderJobQueue()

        self.write { transaction in
            jobQueue.add(message: message, transaction: transaction)
        }

        self.wait(for: [sentBeforeReadyExpectation], timeout: 0.1)

        let sentAfterReadyExpectation = sentExpectation(message: message)

        jobQueue.setup()

        self.wait(for: [sentAfterReadyExpectation], timeout: 0.1)
    }

    func test_respectsQueueOrder() {
        let message1: TSOutgoingMessage = OutgoingMessageFactory().create()
        let message2: TSOutgoingMessage = OutgoingMessageFactory().create()
        let message3: TSOutgoingMessage = OutgoingMessageFactory().create()

        let jobQueue = MessageSenderJobQueue()
        self.write { transaction in
            jobQueue.add(message: message1, transaction: transaction)
            jobQueue.add(message: message2, transaction: transaction)
            jobQueue.add(message: message3, transaction: transaction)
        }

        let sendGroup = DispatchGroup()
        sendGroup.enter()
        sendGroup.enter()
        sendGroup.enter()

        var sentMessages: [TSOutgoingMessage] = []
        messageSender.sendMessageWasCalledBlock = { sentMessage in
            sentMessages.append(sentMessage)
            sendGroup.leave()
        }

        jobQueue.setup()

        switch sendGroup.wait(timeout: .now() + 1.0) {
        case .timedOut:
            XCTFail("timed out waiting for sends")
        case .success:
            XCTAssertEqual([message1, message2, message3].map { $0.uniqueId }, sentMessages.map { $0.uniqueId })
        }
    }

    func test_sendingInvisibleMessage() {
        let jobQueue = MessageSenderJobQueue()
        jobQueue.setup()

        let message = OutgoingMessageFactory().buildDeliveryReceipt()
        let expectation = sentExpectation(message: message)
        self.write { transaction in
            jobQueue.add(message: message, transaction: transaction)
        }

        self.wait(for: [expectation], timeout: 0.1)
    }

    func test_retryableFailure() {
        let message: TSOutgoingMessage = OutgoingMessageFactory().create()

        let jobQueue = MessageSenderJobQueue()
        self.write { transaction in
            jobQueue.add(message: message, transaction: transaction)
        }

        let finder = AnyJobRecordFinder()
        var readyRecords: [SSKJobRecord] = []
        self.read { transaction in
            readyRecords = finder.allRecords(label: MessageSenderJobQueue.jobRecordLabel, status: .ready, transaction: transaction)
        }
        XCTAssertEqual(1, readyRecords.count)

        let jobRecord = readyRecords.first!
        XCTAssertEqual(0, jobRecord.failureCount)

        // simulate permanent failure
        let error = NSError(domain: "foo", code: 0, userInfo: nil)
        error.isRetryable = true
        self.messageSender.stubbedFailingError = error
        let expectation = sentExpectation(message: message) {
            jobQueue.isSetup = false
        }

        jobQueue.setup()
        self.wait(for: [expectation], timeout: 0.1)

        self.read { transaction in
            guard let transitional_yapReadTransaction = transaction.transitional_yapReadTransaction else {
                XCTFail("GRDB TODO")
                return
            }
            jobRecord.reload(with: transitional_yapReadTransaction)
        }

        XCTAssertEqual(1, jobRecord.failureCount)
        XCTAssertEqual(.running, jobRecord.status)

        let retryCount: UInt = MessageSenderJobQueue.maxRetries
        (1..<retryCount).forEach { _ in
            let expectedResend = sentExpectation(message: message)
            // Manually kick queue restart.
            //
            // OWSOperation uses an NSTimer backed retry mechanism, but NSTimer's are not fired
            // during `self.wait(for:,timeout:` unless the timer was scheduled on the
            // `RunLoop.main`.
            //
            // We could move the timer to fire on the main RunLoop (and have the selector dispatch
            // back to a background queue), but the production code is simpler if we just manually
            // kick every retry in the test case.            
            XCTAssertNotNil(jobQueue.runAnyQueuedRetry())
            self.wait(for: [expectedResend], timeout: 0.1)
        }

        // Verify one retry left
        self.read { transaction in
            guard let transitional_yapReadTransaction = transaction.transitional_yapReadTransaction else {
                XCTFail("GRDB TODO")
                return
            }
            jobRecord.reload(with: transitional_yapReadTransaction)
        }
        XCTAssertEqual(retryCount, jobRecord.failureCount)
        XCTAssertEqual(.running, jobRecord.status)

        // Verify final send fails permanently
        let expectedFinalResend = sentExpectation(message: message)
        XCTAssertNotNil(jobQueue.runAnyQueuedRetry())
        self.wait(for: [expectedFinalResend], timeout: 0.1)

        self.read { transaction in
            guard let transitional_yapReadTransaction = transaction.transitional_yapReadTransaction else {
                XCTFail("GRDB TODO")
                return
            }
            jobRecord.reload(with: transitional_yapReadTransaction)
        }

        XCTAssertEqual(retryCount + 1, jobRecord.failureCount)
        XCTAssertEqual(.permanentlyFailed, jobRecord.status)

        // No remaining retries
        XCTAssertNil(jobQueue.runAnyQueuedRetry())
    }

    func test_permanentFailure() {
        let message: TSOutgoingMessage = OutgoingMessageFactory().create()

        let jobQueue = MessageSenderJobQueue()
        self.write { transaction in
            jobQueue.add(message: message, transaction: transaction)
        }

        let finder = AnyJobRecordFinder()
        var readyRecords: [SSKJobRecord] = []
        self.read { transaction in
            readyRecords = finder.allRecords(label: MessageSenderJobQueue.jobRecordLabel, status: .ready, transaction: transaction)
        }
        XCTAssertEqual(1, readyRecords.count)

        let jobRecord = readyRecords.first!
        XCTAssertEqual(0, jobRecord.failureCount)

        // simulate permanent failure
        let error = NSError(domain: "foo", code: 0, userInfo: nil)
        error.isRetryable = false
        self.messageSender.stubbedFailingError = error
        let expectation = sentExpectation(message: message) {
            jobQueue.isSetup = false
        }
        jobQueue.setup()
        self.wait(for: [expectation], timeout: 0.1)

        self.read { transaction in
            guard let transitional_yapReadTransaction = transaction.transitional_yapReadTransaction else {
                XCTFail("GRDB TODO")
                return
            }
            jobRecord.reload(with: transitional_yapReadTransaction)
        }

        XCTAssertEqual(1, jobRecord.failureCount)
        XCTAssertEqual(.permanentlyFailed, jobRecord.status)
    }

    // MARK: Private

    private func sentExpectation(message: TSOutgoingMessage, block: @escaping () -> Void = { }) -> XCTestExpectation {
        let expectation = self.expectation(description: "sent message")

        messageSender.sendMessageWasCalledBlock = { [weak messageSender] sentMessage in
            guard sentMessage == message else {
                XCTFail("unexpected sentMessage: \(sentMessage)")
                return
            }
            expectation.fulfill()
            block()
            guard let strongMessageSender = messageSender else {
                return
            }
            strongMessageSender.sendMessageWasCalledBlock = nil
        }

        return expectation
    }
}
