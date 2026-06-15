//
//  SnapshotTestingSmokeTests.swift
//  whattomake
//
@testable import ForkPlan
import SnapshotTesting
import Testing

@Suite
struct SnapshotTestingSmokeTests {
    @Test
    func snapshotTestingModuleLinks() {
        // Proves SPM linked correctly. assertSnapshot calls deferred to Epic 2.
        #expect(true)
    }
}
