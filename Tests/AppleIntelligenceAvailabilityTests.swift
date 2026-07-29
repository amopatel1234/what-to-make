//
//  AppleIntelligenceAvailabilityTests.swift
//  whattomake
//

@testable import ForkPlan
import FoundationModels
import Testing

@Suite
struct AppleIntelligenceAvailabilityTests {
    @Test
    func notEnabledShowsFeaturesButBlocksActions() {
        let status = AppleIntelligenceAvailability.status(
            forUnavailableReason: .appleIntelligenceNotEnabled
        )
        #expect(status == .notEnabled)
        #expect(status.showsFeatures == true)
        #expect(status.allowsActions == false)
        #expect(status.enablementHintMessage == AppleIntelligenceAvailability.notEnabledHintMessage)
    }

    @Test
    func deviceNotEligibleHidesFeatures() {
        let status = AppleIntelligenceAvailability.status(
            forUnavailableReason: .deviceNotEligible
        )
        #expect(status == .unavailable)
        #expect(status.showsFeatures == false)
        #expect(status.allowsActions == false)
        #expect(status.enablementHintMessage == nil)
    }

    @Test
    func modelNotReadyHidesFeatures() {
        let status = AppleIntelligenceAvailability.status(
            forUnavailableReason: .modelNotReady
        )
        #expect(status == .unavailable)
        #expect(status.showsFeatures == false)
        #expect(status.enablementHintMessage == nil)
    }

    @Test
    func availableAllowsActions() {
        let status = AppleIntelligenceAvailability.status(for: .available)
        #expect(status == .available)
        #expect(status.showsFeatures == true)
        #expect(status.allowsActions == true)
        #expect(status.enablementHintMessage == nil)
    }
}
