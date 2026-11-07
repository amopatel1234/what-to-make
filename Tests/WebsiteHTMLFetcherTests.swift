@testable import ForkPlan
import Foundation
import Testing

private actor WebsiteFixtureClient: WebsiteHTTPClient {
    let responses: [WebsiteHTTPResponse]
    private(set) var requests: [URL] = []
    private(set) var limits: [Int] = []

    init(_ responses: [WebsiteHTTPResponse]) { self.responses = responses }

    func get(_ url: URL, maximumBytes: Int, timeout: TimeInterval) async throws -> WebsiteHTTPResponse {
        requests.append(url)
        limits.append(maximumBytes)
        guard !responses.isEmpty else { throw WebsiteRecipeError.networkFailure }
        return responses[min(requests.count - 1, responses.count - 1)]
    }
}

private struct WebsiteMappingResolver: WebsiteHostResolving {
    func addresses(for host: String) async throws -> [String] {
        host == "private.example.com" ? ["192.168.1.1"] : ["93.184.216.34"]
    }
}

private struct WebsiteWaitingClient: WebsiteHTTPClient {
    func get(_ url: URL, maximumBytes: Int, timeout: TimeInterval) async throws -> WebsiteHTTPResponse {
        try await Task.sleep(for: .seconds(5))
        throw WebsiteRecipeError.networkFailure
    }
}

private struct WebsiteFailureClient: WebsiteHTTPClient {
    let error: URLError
    func get(_ url: URL, maximumBytes: Int, timeout: TimeInterval) async throws -> WebsiteHTTPResponse { throw error }
}

@Suite
struct WebsiteHTMLFetcherTests {
    private func url(_ value: String = "https://recipes.example.com/start") throws -> URL {
        try #require(URL(string: value))
    }

    private func htmlResponse(_ html: String = "<html></html>") -> WebsiteHTTPResponse {
        WebsiteHTTPResponse(statusCode: 200, headers: ["Content-Type": "text/html; charset=utf-8"], body: Data(html.utf8))
    }

    @Test func followsValidatedRelativeRedirectAndPreservesOriginalSource() async throws {
        let client = WebsiteFixtureClient([
            WebsiteHTTPResponse(statusCode: 302, headers: ["Location": "/final"], body: Data()),
            htmlResponse(try WebsiteTestFixtures.html("single-recipe"))
        ])
        let extractor = WebsiteRecipeExtractor(fetcher: WebsiteHTMLFetcher(client: client, resolver: WebsiteFixtureResolver()))
        let result = try await extractor.extract(from: url())
        #expect(result.sourceURL.path == "/start")
        #expect(result.resolvedURL.path == "/final")
        #expect(result.recipes.first?.name == "Chickpea stew")
        #expect(await client.requests.map(\.path) == ["/start", "/final"])
        #expect(await client.limits == [WebsiteHTMLFetcher.maximumBytes, WebsiteHTMLFetcher.maximumBytes])
    }

    @Test(arguments: ["http://127.0.0.1/secret", "http://[::1]/secret", "file:///secret", "https://private.example.com/secret"])
    func rejectsUnsafeRedirectBeforeRequestingIt(_ location: String) async throws {
        let client = WebsiteFixtureClient([
            WebsiteHTTPResponse(statusCode: 302, headers: ["Location": location], body: Data())
        ])
        let fetcher = WebsiteHTMLFetcher(client: client, resolver: WebsiteMappingResolver())
        await #expect(throws: WebsiteRecipeError.self) { try await fetcher.fetch(url()) }
        #expect(await client.requests.count == 1)
    }

    @Test func rejectsPrivateDNSBeforeFirstRequest() async throws {
        let client = WebsiteFixtureClient([htmlResponse()])
        let fetcher = WebsiteHTMLFetcher(client: client, resolver: WebsiteMappingResolver())
        await #expect(throws: WebsiteRecipeError.unsafeDestination) {
            try await fetcher.fetch(url("https://private.example.com/recipe"))
        }
        #expect(await client.requests.isEmpty)
    }

    @Test func boundsRedirectLoops() async throws {
        let client = WebsiteFixtureClient([WebsiteHTTPResponse(statusCode: 301, headers: ["location": "/start"], body: Data())])
        let fetcher = WebsiteHTMLFetcher(client: client, resolver: WebsiteFixtureResolver())
        await #expect(throws: WebsiteRecipeError.tooManyRedirects) { try await fetcher.fetch(url()) }
        #expect(await client.requests.count == WebsiteHTMLFetcher.maximumRedirects + 1)
    }

    @Test func rejectsRedirectWithoutLocation() async throws {
        let client = WebsiteFixtureClient([WebsiteHTTPResponse(statusCode: 302, headers: [:], body: Data())])
        let fetcher = WebsiteHTMLFetcher(client: client, resolver: WebsiteFixtureResolver())
        await #expect(throws: WebsiteRecipeError.invalidRedirect) { try await fetcher.fetch(url()) }
    }

    @Test func exposesHTTPError() async throws {
        let client = WebsiteFixtureClient([WebsiteHTTPResponse(statusCode: 503, headers: [:], body: Data())])
        let fetcher = WebsiteHTMLFetcher(client: client, resolver: WebsiteFixtureResolver())
        await #expect(throws: WebsiteRecipeError.httpStatus(503)) { try await fetcher.fetch(url()) }
    }

    @Test func rejectsNonHTMLAndOversizedMockResponses() async throws {
        let binary = WebsiteFixtureClient([WebsiteHTTPResponse(statusCode: 200, headers: ["content-type": "image/jpeg"], body: Data())])
        await #expect(throws: WebsiteRecipeError.unsupportedContentType) {
            try await WebsiteHTMLFetcher(client: binary, resolver: WebsiteFixtureResolver()).fetch(url())
        }
        let large = WebsiteFixtureClient([htmlResponse(String(repeating: "x", count: WebsiteHTMLFetcher.maximumBytes + 1))])
        await #expect(throws: WebsiteRecipeError.responseTooLarge) {
            try await WebsiteHTMLFetcher(client: large, resolver: WebsiteFixtureResolver()).fetch(url())
        }
    }

    @Test func deadlineCancelsAnUnresponsiveTransport() async throws {
        let fetcher = WebsiteHTMLFetcher(client: WebsiteWaitingClient(), resolver: WebsiteFixtureResolver(), timeout: 0.02)
        await #expect(throws: WebsiteRecipeError.timedOut) { try await fetcher.fetch(url()) }
    }

    @Test func preservesCancellation() async throws {
        let target = try url()
        let fetcher = WebsiteHTMLFetcher(client: WebsiteWaitingClient(), resolver: WebsiteFixtureResolver())
        let task = Task { try await fetcher.fetch(target) }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func mapsTransportTimeoutAndOfflineFailure() async throws {
        await #expect(throws: WebsiteRecipeError.timedOut) {
            try await WebsiteHTMLFetcher(client: WebsiteFailureClient(error: URLError(.timedOut)), resolver: WebsiteFixtureResolver()).fetch(url())
        }
        await #expect(throws: WebsiteRecipeError.networkFailure) {
            try await WebsiteHTMLFetcher(client: WebsiteFailureClient(error: URLError(.notConnectedToInternet)), resolver: WebsiteFixtureResolver()).fetch(url())
        }
    }

    @Test func handlesDeclaredEncodingAndUTF8BOM() throws {
        #expect(try WebsiteHTMLFetcher.decode(Data([0xef, 0xbb, 0xbf, 65]), contentType: "text/html") == "A")
        #expect(try WebsiteHTMLFetcher.decode(Data([0xe9]), contentType: "text/html; CHARSET='iso-8859-1'") == "é")
        #expect(throws: WebsiteRecipeError.unsupportedEncoding) {
            try WebsiteHTMLFetcher.decode(Data([0xff]), contentType: "text/html; charset=utf-8")
        }
        #expect(throws: WebsiteRecipeError.unsupportedEncoding) {
            try WebsiteHTMLFetcher.decode(Data(), contentType: "text/html; charset=made-up")
        }
    }
}

/// Stateless URLProtocol fixture: Foundation owns the inherited request/client state.
private final class WebsiteTransportProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "transport.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let url = request.url else { return }
        let path = url.path
        if path == "/redirect", let destination = URL(string: "https://transport.invalid/ok"),
           let response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: ["Location": destination.absoluteString]) {
            client?.urlProtocol(self, wasRedirectedTo: URLRequest(url: destination), redirectResponse: response)
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        var headers = ["Content-Type": path == "/binary" ? "image/png" : "text/html"]
        if path == "/declared-large" { headers["Content-Length"] = "99999" }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let body = path == "/ok" ? Data("<html>ok</html>".utf8) : Data(repeating: 65, count: 128)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite
struct WebsiteURLSessionTransportTests {
    private func client() -> URLSessionWebsiteHTTPClient {
        URLSessionWebsiteHTTPClient(sessionFactory: { _ in
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [WebsiteTransportProtocol.self]
            return URLSession(configuration: configuration)
        })
    }

    @Test func readsHTMLThroughRealURLSessionWithoutInternet() async throws {
        let url = try #require(URL(string: "https://transport.invalid/ok"))
        let result = try await client().get(url, maximumBytes: 100, timeout: 2)
        #expect(result.statusCode == 200)
        #expect(String(data: result.body, encoding: .utf8) == "<html>ok</html>")
    }

    @Test(arguments: ["/declared-large", "/stream-large"])
    func enforcesDeclaredAndStreamingSizeLimits(_ path: String) async throws {
        let url = try #require(URL(string: "https://transport.invalid" + path))
        await #expect(throws: WebsiteRecipeError.responseTooLarge) {
            try await client().get(url, maximumBytes: 8, timeout: 2)
        }
    }

    @Test func doesNotReadNonHTMLBodies() async throws {
        let url = try #require(URL(string: "https://transport.invalid/binary"))
        let result = try await client().get(url, maximumBytes: 8, timeout: 2)
        #expect(!result.isHTML)
        #expect(result.body.isEmpty)
    }

    @Test func blocksAutomaticURLSessionRedirects() async throws {
        let url = try #require(URL(string: "https://transport.invalid/redirect"))
        let result = try await client().get(url, maximumBytes: 100, timeout: 2)
        #expect(result.statusCode == 302)
        #expect(result.body.isEmpty)
    }
}
