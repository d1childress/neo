//
//  neoTests.swift
//  neoTests
//
//  Created by d1demos on 6/18/25.
//

import Testing
@testable import neo

struct neoTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

struct NetworkMonitorTests {

    /// Ensure that requesting an optimized session for the same purpose
    /// from concurrent contexts returns the same instance.
    @Test func optimizedSessionIsReused() async throws {
        async let first = NetworkMonitor.shared.getOptimizedSession(for: .speedTest)
        async let second = NetworkMonitor.shared.getOptimizedSession(for: .speedTest)

        let (session1, session2) = await (first, second)
        #expect(session1 === session2)
    }
}
