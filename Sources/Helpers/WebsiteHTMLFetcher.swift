//
//  WebsiteHTMLFetcher.swift
//  ForkPlan
//

import Foundation

/// Small value response shared by the real streaming client and deterministic test clients.
struct WebsiteHTTPResponse: Sendable {
    var statusCode: Int
    var headers: [String: String]
    var body: Data

    func header(_ name: String) -> String? {
        headers.first { $0.key.lowercased() == name.lowercased() }?.value
    }

    var isHTML: Bool {
        guard let type = header("Content-Type")?.split(separator: ";").first else { return false }
        return ["text/html", "application/xhtml+xml"].contains(type.trimmingCharacters(in: .whitespaces).lowercased())
    }
}

protocol WebsiteHTTPClient: Sendable {
    func get(_ url: URL, maximumBytes: Int, timeout: TimeInterval) async throws -> WebsiteHTTPResponse
}

/// Stops URLSession's automatic redirects. The fetcher validates and follows them itself.
final class WebsiteRedirectBlocker: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest) async -> URLRequest? { nil }
}

/// Ephemeral, credential-free streaming transport; enforces the byte cap while reading.
struct URLSessionWebsiteHTTPClient: WebsiteHTTPClient {
    var sessionFactory: @Sendable (TimeInterval) -> URLSession = { timeout in
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = min(20, timeout)
        configuration.timeoutIntervalForResource = timeout
        return URLSession(configuration: configuration)
    }

    func get(_ url: URL, maximumBytes: Int, timeout: TimeInterval) async throws -> WebsiteHTTPResponse {
        let session = sessionFactory(timeout)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: min(20, timeout))
        request.setValue("text/html, application/xhtml+xml", forHTTPHeaderField: "Accept")
        let (bytes, response) = try await session.bytes(for: request, delegate: WebsiteRedirectBlocker())
        guard let response = response as? HTTPURLResponse else { throw WebsiteRecipeError.networkFailure }
        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            if let key = key as? String { headers[key.lowercased()] = String(describing: value) }
        }
        var result = WebsiteHTTPResponse(statusCode: response.statusCode, headers: headers, body: Data())
        // Redirect/error/non-HTML bodies are unnecessary and must not consume the download budget.
        guard (200...299).contains(result.statusCode), result.isHTML else { return result }
        guard response.expectedContentLength <= maximumBytes else { throw WebsiteRecipeError.responseTooLarge }
        for try await byte in bytes {
            try Task.checkCancellation()
            guard result.body.count < maximumBytes else { throw WebsiteRecipeError.responseTooLarge }
            result.body.append(byte)
        }
        return result
    }
}

struct WebsiteHTMLPage: Sendable {
    var sourceURL: URL
    var resolvedURL: URL
    var html: String
}

/// Fetching is independent of recipe parsing, UI, SwiftData and Foundation Models.
struct WebsiteHTMLFetcher: Sendable {
    static let maximumBytes = 2 * 1024 * 1024
    static let maximumRedirects = 5
    static let overallTimeout: TimeInterval = 60
    let client: any WebsiteHTTPClient
    let resolver: any WebsiteHostResolving
    let timeout: TimeInterval

    init(client: any WebsiteHTTPClient = URLSessionWebsiteHTTPClient(),
         resolver: any WebsiteHostResolving = SystemWebsiteHostResolver(),
         timeout: TimeInterval = WebsiteHTMLFetcher.overallTimeout) {
        self.client = client
        self.resolver = resolver
        self.timeout = timeout
    }

    func fetch(_ sourceURL: URL) async throws -> WebsiteHTMLPage {
        do {
            return try await withThrowingTaskGroup(of: WebsiteHTMLPage.self) { group in
                group.addTask { try await fetchFollowingRedirects(sourceURL) }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    throw WebsiteRecipeError.timedOut
                }
                defer { group.cancelAll() }
                guard let page = try await group.next() else { throw WebsiteRecipeError.networkFailure }
                return page
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as WebsiteRecipeError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw WebsiteRecipeError.timedOut
        } catch let error as URLError where error.code == .appTransportSecurityRequiresSecureConnection {
            throw WebsiteRecipeError.insecureConnection
        } catch {
            try Task.checkCancellation()
            throw WebsiteRecipeError.networkFailure
        }
    }

    private func fetchFollowingRedirects(_ sourceURL: URL) async throws -> WebsiteHTMLPage {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(timeout))
        var currentURL = sourceURL
        for redirectCount in 0...Self.maximumRedirects {
            try Task.checkCancellation()
            try await WebsiteURLPolicy.validate(currentURL, resolver: resolver)
            let remaining = clock.now.duration(to: deadline).components
            let timeout = Double(remaining.seconds) + Double(remaining.attoseconds) / 1e18
            guard timeout > 0 else { throw WebsiteRecipeError.timedOut }
            let response = try await client.get(currentURL, maximumBytes: Self.maximumBytes, timeout: timeout)
            if [301, 302, 303, 307, 308].contains(response.statusCode) {
                guard redirectCount < Self.maximumRedirects else { throw WebsiteRecipeError.tooManyRedirects }
                guard let location = response.header("Location"), !location.isEmpty,
                      let next = URL(string: location, relativeTo: currentURL)?.absoluteURL else {
                    throw WebsiteRecipeError.invalidRedirect
                }
                currentURL = next
                continue
            }
            guard (200...299).contains(response.statusCode) else { throw WebsiteRecipeError.httpStatus(response.statusCode) }
            guard response.isHTML else { throw WebsiteRecipeError.unsupportedContentType }
            guard response.body.count <= Self.maximumBytes else { throw WebsiteRecipeError.responseTooLarge }
            return WebsiteHTMLPage(sourceURL: sourceURL, resolvedURL: currentURL,
                                   html: try Self.decode(response.body, contentType: response.header("Content-Type")))
        }
        throw WebsiteRecipeError.tooManyRedirects
    }

    /// Honor an explicit HTTP charset, otherwise accept UTF-8 (including its BOM).
    static func decode(_ data: Data, contentType: String?) throws -> String {
        let parameters = contentType?.split(separator: ";").dropFirst() ?? []
        let charset = parameters.compactMap { parameter -> String? in
            let pair = parameter.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard pair.count == 2, pair[0].lowercased() == "charset" else { return nil }
            return pair[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'")).lowercased()
        }.first
        let encoding: String.Encoding
        switch charset {
        case nil, "utf-8", "utf8": encoding = .utf8
        case "us-ascii", "ascii": encoding = .ascii
        case "iso-8859-1", "latin1": encoding = .isoLatin1
        case "windows-1252": encoding = .windowsCP1252
        default: throw WebsiteRecipeError.unsupportedEncoding
        }
        guard var html = String(data: data, encoding: encoding) else { throw WebsiteRecipeError.unsupportedEncoding }
        if html.first == "\u{feff}" { html.removeFirst() }
        return html
    }
}

/// Entry point for #68's future draft-review flow; extraction never saves user data.
struct WebsiteRecipeExtractor: Sendable {
    var fetcher = WebsiteHTMLFetcher()

    func extract(from url: URL) async throws -> WebsiteRecipeExtraction {
        let page = try await fetcher.fetch(url)
        try Task.checkCancellation()
        return try WebsiteRecipeParser.parse(html: page.html, sourceURL: page.sourceURL, resolvedURL: page.resolvedURL)
    }
}
