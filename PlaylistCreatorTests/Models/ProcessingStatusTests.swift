import XCTest
@testable import PlaylistCreator

final class ProcessingStatusTests: XCTestCase {
    
    // MARK: - Enum Case Tests
    
    func testProcessingStatusCases() throws {
        // Test all enum cases exist
        let idle = ProcessingStatus.idle
        let processing = ProcessingStatus.processing
        let complete = ProcessingStatus.complete
        let error = ProcessingStatus.error
        
        XCTAssertNotNil(idle)
        XCTAssertNotNil(processing)
        XCTAssertNotNil(complete)
        XCTAssertNotNil(error)
    }
    
    func testProcessingStatusEquality() throws {
        XCTAssertEqual(ProcessingStatus.idle, ProcessingStatus.idle)
        XCTAssertEqual(ProcessingStatus.processing, ProcessingStatus.processing)
        XCTAssertEqual(ProcessingStatus.complete, ProcessingStatus.complete)
        XCTAssertEqual(ProcessingStatus.error, ProcessingStatus.error)
        
        XCTAssertNotEqual(ProcessingStatus.idle, ProcessingStatus.processing)
        XCTAssertNotEqual(ProcessingStatus.processing, ProcessingStatus.complete)
        XCTAssertNotEqual(ProcessingStatus.complete, ProcessingStatus.error)
        XCTAssertNotEqual(ProcessingStatus.error, ProcessingStatus.idle)
    }
    
    // MARK: - State Logic Tests
    
    func testInitialState() throws {
        // Idle should be the typical initial state
        let initialStatus = ProcessingStatus.idle
        XCTAssertEqual(initialStatus, .idle)
    }
    
    func testStateTransitions() throws {
        // Test logical state transitions
        var status = ProcessingStatus.idle
        
        // Can transition from idle to processing
        status = .processing
        XCTAssertEqual(status, .processing)
        
        // Can transition from processing to complete
        status = .complete
        XCTAssertEqual(status, .complete)
        
        // Can transition from processing to error
        status = .processing
        status = .error
        XCTAssertEqual(status, .error)
    }
    
    // MARK: - Codable Tests
    
    func testProcessingStatusCodableEncoding() throws {
        let encoder = JSONEncoder()
        
        let idleData = try encoder.encode(ProcessingStatus.idle)
        let processingData = try encoder.encode(ProcessingStatus.processing)
        let completeData = try encoder.encode(ProcessingStatus.complete)
        let errorData = try encoder.encode(ProcessingStatus.error)
        
        XCTAssertFalse(idleData.isEmpty)
        XCTAssertFalse(processingData.isEmpty)
        XCTAssertFalse(completeData.isEmpty)
        XCTAssertFalse(errorData.isEmpty)
        
        // Verify JSON format
        let idleString = String(data: idleData, encoding: .utf8)
        let processingString = String(data: processingData, encoding: .utf8)
        let completeString = String(data: completeData, encoding: .utf8)
        let errorString = String(data: errorData, encoding: .utf8)
        
        XCTAssertEqual(idleString, "\"idle\"")
        XCTAssertEqual(processingString, "\"processing\"")
        XCTAssertEqual(completeString, "\"complete\"")
        XCTAssertEqual(errorString, "\"error\"")
    }
    
    func testProcessingStatusCodableDecoding() throws {
        let decoder = JSONDecoder()
        
        let idleData = "\"idle\"".data(using: .utf8)!
        let processingData = "\"processing\"".data(using: .utf8)!
        let completeData = "\"complete\"".data(using: .utf8)!
        let errorData = "\"error\"".data(using: .utf8)!
        
        let decodedIdle = try decoder.decode(ProcessingStatus.self, from: idleData)
        let decodedProcessing = try decoder.decode(ProcessingStatus.self, from: processingData)
        let decodedComplete = try decoder.decode(ProcessingStatus.self, from: completeData)
        let decodedError = try decoder.decode(ProcessingStatus.self, from: errorData)
        
        XCTAssertEqual(decodedIdle, .idle)
        XCTAssertEqual(decodedProcessing, .processing)
        XCTAssertEqual(decodedComplete, .complete)
        XCTAssertEqual(decodedError, .error)
    }
    
    func testProcessingStatusCodableRoundTrip() throws {
        let statuses: [ProcessingStatus] = [.idle, .processing, .complete, .error]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for status in statuses {
            let encoded = try encoder.encode(status)
            let decoded = try decoder.decode(ProcessingStatus.self, from: encoded)
            XCTAssertEqual(status, decoded)
        }
    }
    
    // MARK: - Invalid Data Handling Tests
    
    func testProcessingStatusInvalidDecoding() throws {
        let decoder = JSONDecoder()
        let invalidData = "\"invalid_status\"".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(ProcessingStatus.self, from: invalidData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testProcessingStatusInvalidJSONStructure() throws {
        let decoder = JSONDecoder()
        let invalidData = "{\"status\": \"idle\"}".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(ProcessingStatus.self, from: invalidData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - String Representation Tests
    
    func testProcessingStatusStringRepresentation() throws {
        XCTAssertEqual(String(describing: ProcessingStatus.idle), "idle")
        XCTAssertEqual(String(describing: ProcessingStatus.processing), "processing") 
        XCTAssertEqual(String(describing: ProcessingStatus.complete), "complete")
        XCTAssertEqual(String(describing: ProcessingStatus.error), "error")
    }
    
    // MARK: - Switch Coverage Tests
    
    func testExhaustiveSwitchCoverage() throws {
        let allStatuses: [ProcessingStatus] = [.idle, .processing, .complete, .error]
        
        for status in allStatuses {
            let description: String
            switch status {
            case .idle:
                description = "Not started"
            case .processing:
                description = "In progress"
            case .complete:
                description = "Finished successfully"
            case .error:
                description = "Failed with error"
            }
            
            XCTAssertFalse(description.isEmpty)
        }
    }
}