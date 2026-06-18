//
//  SnapshotTestConfiguration.swift
//  whattomake
//

import Foundation
import SnapshotTesting
import SwiftUI
import Testing
@testable import ForkPlan

enum SnapshotTestConfiguration {
    static let snapshotWidth: CGFloat = 402
    static let snapshotHeight: CGFloat = 874

    /// True when running on GitHub Actions / CI (compare and record both disabled).
    ///
    /// `GITHUB_ACTIONS` from the workflow step often does not propagate into `TEST_HOST`
    /// (`ForkPlan.app`); fall back to runner home path on GitHub-hosted macOS.
    static var isCI: Bool {
        let env = ProcessInfo.processInfo.environment
        if env["GITHUB_ACTIONS"] == "true" || env["CI"] == "true" { return true }
        if env["HOME"] == "/Users/runner" { return true }
        return FileManager.default.fileExists(atPath: "/Users/runner")
    }

    static let snapshotDirectory: String = {
        let testsRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Fixtures
            .deletingLastPathComponent() // Tests
        return testsRoot
            .appendingPathComponent("__Snapshots__/iPhone17Pro-iOS26")
            .path()
    }()

    static var recordMode: SnapshotTestingConfiguration.Record {
        if isCI { return .never }
        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1" { return .all }
        return .never
    }

    static func imageStrategy<V: View>() -> Snapshotting<V, UIImage> {
        .image(layout: .fixed(width: snapshotWidth, height: snapshotHeight))
    }

    static func applyBaselineEnvironment<V: View>(to view: V) -> some View {
        view
            .preferredColorScheme(.light)
            .environment(\.locale, Locale(identifier: "en_US"))
            .environment(\.sizeCategory, .large)
            .transaction { transaction in
                transaction.animation = nil
            }
            .fpAppTheme()
    }

    /// Wraps `@Query`-driven views so snapshot hosting sees a stable hierarchy.
    static func queryReady<V: View>(_ view: V) -> some View {
        view
    }

    /// Asserts a SwiftUI snapshot against the shared device slug directory.
    static func assertBaselineSnapshot<V: View>(
        of view: V,
        named name: String,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        // Story 2.2: baselines are recorded locally; macos-26 CI renders differently until
        // compare mode is configured for the pinned runner (re-record or perceptual tolerance).
        guard !isCI else { return }

        withSnapshotTesting(record: recordMode) {
            let failure = verifySnapshot(
                of: view,
                as: imageStrategy(),
                named: name,
                snapshotDirectory: snapshotDirectory,
                fileID: fileID,
                file: file,
                testName: testName,
                line: line,
                column: column
            )
            if let message = failure {
                Issue.record(
                    Comment(rawValue: message),
                    sourceLocation: SourceLocation(
                        fileID: fileID.description,
                        filePath: file.description,
                        line: Int(line),
                        column: Int(column)
                    )
                )
            }
        }
    }
}
