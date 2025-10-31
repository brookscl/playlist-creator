import XCTest
@testable import PlaylistCreator

final class KeychainManagerTests: XCTestCase {
    var keychainManager: KeychainManager!
    let testService = "com.playlistcreator.tests"
    let testAccount = "openai-api-key-test"

    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager(service: testService, account: testAccount)
        // Clean up any existing test data
        try? keychainManager.deleteItem()
    }

    override func tearDown() {
        // Clean up test data
        try? keychainManager.deleteItem()
        keychainManager = nil
        super.tearDown()
    }

    // MARK: - Save Tests

    func testSaveItem() throws {
        let testValue = "sk-test1234567890abcdef"

        try keychainManager.saveItem(testValue)

        // Verify it was saved
        let retrieved = try keychainManager.getItem()
        XCTAssertEqual(retrieved, testValue)
    }

    func testSaveItemOverwritesExisting() throws {
        let firstValue = "sk-first-key"
        let secondValue = "sk-second-key"

        try keychainManager.saveItem(firstValue)
        try keychainManager.saveItem(secondValue)

        let retrieved = try keychainManager.getItem()
        XCTAssertEqual(retrieved, secondValue)
    }

    func testSaveEmptyString() throws {
        let emptyValue = ""

        try keychainManager.saveItem(emptyValue)

        let retrieved = try keychainManager.getItem()
        XCTAssertEqual(retrieved, emptyValue)
    }

    func testSaveItemWithSpecialCharacters() throws {
        let specialValue = "sk-!@#$%^&*()_+-=[]{}|;':\"<>?,./~`"

        try keychainManager.saveItem(specialValue)

        let retrieved = try keychainManager.getItem()
        XCTAssertEqual(retrieved, specialValue)
    }

    func testSaveItemWithUnicode() throws {
        let unicodeValue = "sk-test-🔑-密钥-مفتاح"

        try keychainManager.saveItem(unicodeValue)

        let retrieved = try keychainManager.getItem()
        XCTAssertEqual(retrieved, unicodeValue)
    }

    // MARK: - Get Tests

    func testGetItemWhenNotExists() throws {
        do {
            _ = try keychainManager.getItem()
            XCTFail("Should throw error when item doesn't exist")
        } catch KeychainError.itemNotFound {
            // Expected
            XCTAssertTrue(true)
        }
    }

    func testGetItemAfterSave() throws {
        let testValue = "sk-test-get-item"

        try keychainManager.saveItem(testValue)
        let retrieved = try keychainManager.getItem()

        XCTAssertEqual(retrieved, testValue)
    }

    // MARK: - Delete Tests

    func testDeleteItem() throws {
        let testValue = "sk-test-delete"

        try keychainManager.saveItem(testValue)
        try keychainManager.deleteItem()

        // Verify it was deleted
        do {
            _ = try keychainManager.getItem()
            XCTFail("Should throw error after deletion")
        } catch KeychainError.itemNotFound {
            XCTAssertTrue(true)
        }
    }

    func testDeleteItemWhenNotExists() throws {
        // Should not throw error when deleting non-existent item
        try keychainManager.deleteItem()
        XCTAssertTrue(true, "Delete should succeed even when item doesn't exist")
    }

    // MARK: - Multiple Operations Tests

    func testMultipleSaveAndGetOperations() throws {
        let values = ["sk-first", "sk-second", "sk-third"]

        for value in values {
            try keychainManager.saveItem(value)
            let retrieved = try keychainManager.getItem()
            XCTAssertEqual(retrieved, value)
        }
    }

    // MARK: - Edge Cases

    func testLongValue() throws {
        let longValue = String(repeating: "a", count: 10000)

        try keychainManager.saveItem(longValue)
        let retrieved = try keychainManager.getItem()

        XCTAssertEqual(retrieved, longValue)
    }

    func testConcurrentAccess() throws {
        // Test that concurrent reads are safe (writes need to be serialized)
        let expectation = self.expectation(description: "Concurrent read operations complete")
        expectation.expectedFulfillmentCount = 5

        // Save an initial value
        try keychainManager.saveItem("sk-test-concurrent")

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        // Concurrent reads should be safe
        for _ in 0..<5 {
            queue.async {
                do {
                    let value = try self.keychainManager.getItem()
                    XCTAssertEqual(value, "sk-test-concurrent")
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent read failed: \(error)")
                }
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Service Isolation Tests

    func testDifferentServicesDontInterfere() throws {
        let manager1 = KeychainManager(service: "com.test.service1", account: "api-key")
        let manager2 = KeychainManager(service: "com.test.service2", account: "api-key")

        defer {
            try? manager1.deleteItem()
            try? manager2.deleteItem()
        }

        try manager1.saveItem("value1")
        try manager2.saveItem("value2")

        let retrieved1 = try manager1.getItem()
        let retrieved2 = try manager2.getItem()

        XCTAssertEqual(retrieved1, "value1")
        XCTAssertEqual(retrieved2, "value2")
    }

    func testDifferentAccountsDontInterfere() throws {
        let manager1 = KeychainManager(service: testService, account: "account1")
        let manager2 = KeychainManager(service: testService, account: "account2")

        defer {
            try? manager1.deleteItem()
            try? manager2.deleteItem()
        }

        try manager1.saveItem("value1")
        try manager2.saveItem("value2")

        let retrieved1 = try manager1.getItem()
        let retrieved2 = try manager2.getItem()

        XCTAssertEqual(retrieved1, "value1")
        XCTAssertEqual(retrieved2, "value2")
    }
}
