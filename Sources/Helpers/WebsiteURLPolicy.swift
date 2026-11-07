//
//  WebsiteURLPolicy.swift
//  ForkPlan
//

import Darwin
import Foundation

/// Injectable DNS boundary so automated tests never require internet access.
protocol WebsiteHostResolving: Sendable {
    func addresses(for host: String) async throws -> [String]
}

/// Resolves off the caller's executor; only value strings cross the task boundary.
struct SystemWebsiteHostResolver: WebsiteHostResolving {
    func addresses(for host: String) async throws -> [String] {
        try Task.checkCancellation()
        let result = WebsiteDNSResult()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            Task.detached(priority: .utility) {
                let resolved = Result { try Self.lookup(host) }
                await result.complete(resolved)
            }
            return try await result.wait()
        } onCancel: {
            // getaddrinfo itself is not cancellable. Release the awaiting caller now;
            // the detached lookup still frees its C resources when it eventually ends.
            Task { await result.complete(.failure(CancellationError())) }
        }
    }

    private static func lookup(_ host: String) throws -> [String] {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let first = result else {
            throw WebsiteRecipeError.resolutionFailed
        }
        defer { freeaddrinfo(first) }
        var values: [String] = []
        var current: UnsafeMutablePointer<addrinfo>? = first
        while let entry = current {
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(entry.pointee.ai_addr, entry.pointee.ai_addrlen,
                           &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
                values.append(String(decoding: bytes, as: UTF8.self))
            }
            current = entry.pointee.ai_next
        }
        return values
    }
}

/// Serializes completion/cancellation, including cancellation before wait is installed.
actor WebsiteDNSResult {
    private var result: Result<[String], Error>?
    private var continuation: CheckedContinuation<[String], Error>?

    func wait() async throws -> [String] {
        if let result { return try result.get() }
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func complete(_ result: Result<[String], Error>) {
        guard self.result == nil else { return }
        self.result = result
        continuation?.resume(with: result)
        continuation = nil
    }
}

/// Public website URL policy, applied before the initial request and every redirect.
enum WebsiteURLPolicy {
    @discardableResult
    static func checkedURL(_ url: URL) throws -> URL {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              components.user == nil, components.password == nil,
              let rawHost = components.host, !rawHost.isEmpty,
              components.port.map({ (1...65535).contains($0) }) ?? true else {
            throw WebsiteRecipeError.invalidURL
        }
        let host = normalizedHost(rawHost)
        guard !host.contains("%"), !host.contains("\\"),
              !["localhost", "local", "internal", "home", "lan"].contains(host),
              ![".localhost", ".local", ".internal", ".home", ".lan"].contains(where: host.hasSuffix) else {
            throw WebsiteRecipeError.unsafeDestination
        }
        if host.contains(":") || host.allSatisfy({ $0.isNumber || $0 == "." }) {
            guard isPublicAddress(host) else { throw WebsiteRecipeError.unsafeDestination }
        } else {
            // Reject alternate numeric IPv4 spellings and single-label LAN names.
            guard host.contains("."), !host.split(separator: ".").contains(where: { $0.hasPrefix("0x") }) else {
                throw WebsiteRecipeError.unsafeDestination
            }
        }
        return url
    }

    static func validate(_ url: URL, resolver: any WebsiteHostResolving) async throws {
        try checkedURL(url)
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else {
            throw WebsiteRecipeError.invalidURL
        }
        let addresses = try await resolver.addresses(for: normalizedHost(host))
        guard !addresses.isEmpty else { throw WebsiteRecipeError.resolutionFailed }
        guard addresses.allSatisfy(isPublicAddress) else { throw WebsiteRecipeError.unsafeDestination }
    }

    static func isPublicAddress(_ host: String) -> Bool {
        var ipv4 = in_addr()
        if inet_pton(AF_INET, host, &ipv4) == 1 {
            let bytes = withUnsafeBytes(of: ipv4) { Array($0) }
            let first = bytes[0], second = bytes[1], third = bytes[2]
            return first != 0 && first != 10 && first != 127 && first < 224
                && !(first == 100 && (64...127).contains(second))
                && !(first == 169 && second == 254)
                && !(first == 172 && (16...31).contains(second))
                && !(first == 192 && (second == 168 || (second == 0 && (third == 0 || third == 2))
                                      || (second == 88 && third == 99)))
                && !(first == 198 && (second == 18 || second == 19 || (second == 51 && third == 100)))
                && !(first == 203 && second == 0 && third == 113)
        }
        var ipv6 = in6_addr()
        guard inet_pton(AF_INET6, host, &ipv6) == 1 else { return false }
        let bytes = withUnsafeBytes(of: ipv6) { Array($0) }
        // Only global-unicast 2000::/3; excludes loopback, mapped IPv4, ULA and link-local.
        guard bytes[0] & 0xe0 == 0x20 else { return false }
        // Exclude special-purpose 2001::/23, documentation, 6to4 and former 6bone space.
        if bytes[0] == 0x20 && bytes[1] == 0x01 {
            if bytes[2] < 2 || (bytes[2] == 0x0d && bytes[3] == 0xb8) { return false }
        }
        if bytes[0] == 0x20 && bytes[1] == 0x02 { return false }
        if bytes[0] == 0x3f && bytes[1] == 0xfe { return false }
        if bytes[0] == 0x3f && bytes[1] == 0xff && bytes[2] < 0x10 { return false }
        return true
    }

    private static func normalizedHost(_ host: String) -> String {
        var value = host.lowercased()
        if value.hasPrefix("["), value.hasSuffix("]") { value = String(value.dropFirst().dropLast()) }
        if value.hasSuffix(".") { value.removeLast() }
        return value
    }
}
