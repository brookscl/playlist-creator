import XCTest
@testable import PlaylistCreator

final class MatchStatusTests: XCTestCase {
    
    // MARK: - Enum Case Tests
    
    func testMatchStatusCases() throws {
        // Test all enum cases exist
        let auto = MatchStatus.auto
        let pending = MatchStatus.pending
        let selected = MatchStatus.selected
        let skipped = MatchStatus.skipped
        
        XCTAssertNotNil(auto)
        XCTAssertNotNil(pending)
        XCTAssertNotNil(selected)
        XCTAssertNotNil(skipped)
    }
    
    func testMatchStatusEquality() throws {
        XCTAssertEqual(MatchStatus.auto, MatchStatus.auto)
        XCTAssertEqual(MatchStatus.pending, MatchStatus.pending)
        XCTAssertEqual(MatchStatus.selected, MatchStatus.selected)
        XCTAssertEqual(MatchStatus.skipped, MatchStatus.skipped)
        
        XCTAssertNotEqual(MatchStatus.auto, MatchStatus.pending)
        XCTAssertNotEqual(MatchStatus.pending, MatchStatus.selected)
        XCTAssertNotEqual(MatchStatus.selected, MatchStatus.skipped)
        XCTAssertNotEqual(MatchStatus.skipped, MatchStatus.auto)
    }
    
    // MARK: - State Logic Tests
    
    func testInitialState() throws {
        // Pending should be the typical initial state for ambiguous matches
        let initialStatus = MatchStatus.pending
        XCTAssertEqual(initialStatus, .pending)
    }
    
    func testAutoSelectionState() throws {
        // Auto should be used for high-confidence matches
        let autoStatus = MatchStatus.auto
        XCTAssertEqual(autoStatus, .auto)
    }
    
    func testUserActionStates() throws {
        // Test user interaction states
        var status = MatchStatus.pending
        
        // User can select a match
        status = .selected
        XCTAssertEqual(status, .selected)
        
        // User can skip a match
        status = .skipped
        XCTAssertEqual(status, .skipped)
    }
    
    func testStateTransitions() throws {
        // Test logical state transitions
        var status = MatchStatus.pending
        
        // Can transition from pending to selected
        status = .selected
        XCTAssertEqual(status, .selected)
        
        // Can transition from pending to skipped
        status = .pending
        status = .skipped
        XCTAssertEqual(status, .skipped)
        
        // Auto matches typically don't change, but could be overridden
        status = .auto
        status = .skipped // User could manually skip an auto match
        XCTAssertEqual(status, .skipped)
    }
    
    // MARK: - Codable Tests
    
    func testMatchStatusCodableEncoding() throws {
        let encoder = JSONEncoder()
        
        let autoData = try encoder.encode(MatchStatus.auto)
        let pendingData = try encoder.encode(MatchStatus.pending)
        let selectedData = try encoder.encode(MatchStatus.selected)
        let skippedData = try encoder.encode(MatchStatus.skipped)
        
        XCTAssertFalse(autoData.isEmpty)
        XCTAssertFalse(pendingData.isEmpty)
        XCTAssertFalse(selectedData.isEmpty)
        XCTAssertFalse(skippedData.isEmpty)
        
        // Verify JSON format
        let autoString = String(data: autoData, encoding: .utf8)
        let pendingString = String(data: pendingData, encoding: .utf8)
        let selectedString = String(data: selectedData, encoding: .utf8)
        let skippedString = String(data: skippedData, encoding: .utf8)
        
        XCTAssertEqual(autoString, "\"auto\"")
        XCTAssertEqual(pendingString, "\"pending\"")
        XCTAssertEqual(selectedString, "\"selected\"")
        XCTAssertEqual(skippedString, "\"skipped\"")
    }
    
    func testMatchStatusCodableDecoding() throws {
        let decoder = JSONDecoder()
        
        let autoData = "\"auto\"".data(using: .utf8)!
        let pendingData = "\"pending\"".data(using: .utf8)!
        let selectedData = "\"selected\"".data(using: .utf8)!
        let skippedData = "\"skipped\"".data(using: .utf8)!
        
        let decodedAuto = try decoder.decode(MatchStatus.self, from: autoData)
        let decodedPending = try decoder.decode(MatchStatus.self, from: pendingData)
        let decodedSelected = try decoder.decode(MatchStatus.self, from: selectedData)
        let decodedSkipped = try decoder.decode(MatchStatus.self, from: skippedData)
        
        XCTAssertEqual(decodedAuto, .auto)
        XCTAssertEqual(decodedPending, .pending)
        XCTAssertEqual(decodedSelected, .selected)
        XCTAssertEqual(decodedSkipped, .skipped)
    }
    
    func testMatchStatusCodableRoundTrip() throws {
        let statuses: [MatchStatus] = [.auto, .pending, .selected, .skipped]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for status in statuses {
            let encoded = try encoder.encode(status)
            let decoded = try decoder.decode(MatchStatus.self, from: encoded)
            XCTAssertEqual(status, decoded)
        }
    }
    
    // MARK: - Invalid Data Handling Tests
    
    func testMatchStatusInvalidDecoding() throws {
        let decoder = JSONDecoder()
        let invalidData = "\"invalid_match_status\"".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(MatchStatus.self, from: invalidData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    func testMatchStatusInvalidJSONStructure() throws {
        let decoder = JSONDecoder()
        let invalidData = "{\"matchStatus\": \"pending\"}".data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(MatchStatus.self, from: invalidData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
    
    // MARK: - String Representation Tests
    
    func testMatchStatusStringRepresentation() throws {
        XCTAssertEqual(String(describing: MatchStatus.auto), "auto")
        XCTAssertEqual(String(describing: MatchStatus.pending), "pending")
        XCTAssertEqual(String(describing: MatchStatus.selected), "selected")
        XCTAssertEqual(String(describing: MatchStatus.skipped), "skipped")
    }
    
    // MARK: - Switch Coverage Tests
    
    func testExhaustiveSwitchCoverage() throws {
        let allStatuses: [MatchStatus] = [.auto, .pending, .selected, .skipped]
        
        for status in allStatuses {
            let description: String
            switch status {
            case .auto:
                description = "Automatically selected"
            case .pending:
                description = "Awaiting user decision"
            case .selected:
                description = "User selected"
            case .skipped:
                description = "User skipped"
            }
            
            XCTAssertFalse(description.isEmpty)
        }
    }
    
    // MARK: - Business Logic Tests
    
    func testIsUserActionRequired() throws {
        // Helper function to test business logic
        func requiresUserAction(_ status: MatchStatus) -> Bool {
            switch status {
            case .pending:
                return true
            case .auto, .selected, .skipped:
                return false
            }
        }
        
        XCTAssertTrue(requiresUserAction(.pending))
        XCTAssertFalse(requiresUserAction(.auto))
        XCTAssertFalse(requiresUserAction(.selected))
        XCTAssertFalse(requiresUserAction(.skipped))
    }
    
    func testIsIncludedInPlaylist() throws {
        // Helper function to test which statuses result in playlist inclusion
        func isIncludedInPlaylist(_ status: MatchStatus) -> Bool {
            switch status {
            case .auto, .selected:
                return true
            case .pending, .skipped:
                return false
            }
        }
        
        XCTAssertTrue(isIncludedInPlaylist(.auto))
        XCTAssertTrue(isIncludedInPlaylist(.selected))
        XCTAssertFalse(isIncludedInPlaylist(.pending))
        XCTAssertFalse(isIncludedInPlaylist(.skipped))
    }
}