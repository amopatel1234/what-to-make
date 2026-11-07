@testable import ForkPlan
import Foundation
import Testing

struct WebsiteFixtureResolver: WebsiteHostResolving {
    var values: [String] = ["93.184.216.34"]
    func addresses(for host: String) async throws -> [String] { values }
}

@Suite
struct WebsiteURLPolicyTests {
    @Test(arguments: ["0.0.0.0", "10.1.2.3", "100.64.0.1", "127.0.0.1", "169.254.169.254",
                      "172.16.0.1", "172.31.255.255", "192.168.0.1", "192.0.2.1", "198.18.0.1",
                      "198.51.100.1", "203.0.113.1", "224.0.0.1", "255.255.255.255",
                      "::1", "::", "::ffff:127.0.0.1", "fc00::1", "fe80::1", "ff02::1",
                      "2001:db8::1", "2001::1", "2002:7f00:1::", "3fff::1"])
    func rejectsNonPublicAddresses(_ address: String) {
        #expect(!WebsiteURLPolicy.isPublicAddress(address))
    }

    @Test(arguments: ["93.184.216.34", "8.8.8.8", "172.15.1.1", "172.32.1.1", "100.128.0.1",
                      "2001:4860:4860::8888", "2606:4700:4700::1111"])
    func acceptsPublicAddresses(_ address: String) {
        #expect(WebsiteURLPolicy.isPublicAddress(address))
    }

    @Test(arguments: ["file:///etc/passwd", "ftp://example.com/recipe", "https://user:secret@example.com",
                      "http://localhost/", "http://LOCALHOST./", "http://printer.local/", "http://router/",
                      "http://127.1/", "http://2130706433/", "http://0177.0.0.1/", "http://0x7f000001/",
                      "http://001.002.003.004/", "http://93.184.216.034/", "http://0x5d.b8.d8.22/",
                      "http://[::1]/", "http://[::ffff:127.0.0.1]/"])
    func rejectsUnsupportedOrLocalURLs(_ value: String) throws {
        let url = try #require(URL(string: value))
        #expect(throws: WebsiteRecipeError.self) { try WebsiteURLPolicy.checkedURL(url) }
    }

    @Test func rejectsMixedPublicAndPrivateDNSAnswers() async throws {
        let url = try #require(URL(string: "https://recipes.example.com"))
        await #expect(throws: WebsiteRecipeError.unsafeDestination) {
            try await WebsiteURLPolicy.validate(url, resolver: WebsiteFixtureResolver(values: ["93.184.216.34", "10.0.0.1"]))
        }
    }

    @Test func rejectsEmptyDNSAnswers() async throws {
        let url = try #require(URL(string: "https://recipes.example.com"))
        await #expect(throws: WebsiteRecipeError.resolutionFailed) {
            try await WebsiteURLPolicy.validate(url, resolver: WebsiteFixtureResolver(values: []))
        }
    }

    @Test func DNSCancellationBeforeWaitWinsOverLateResolution() async {
        let result = WebsiteDNSResult()
        await result.complete(.failure(CancellationError()))
        await result.complete(.success(["93.184.216.34"]))
        await #expect(throws: CancellationError.self) { try await result.wait() }
    }

    @Test func DNSCompletionWakesWaitingCaller() async throws {
        let result = WebsiteDNSResult()
        let task = Task { try await result.wait() }
        await result.complete(.success(["93.184.216.34"]))
        #expect(try await task.value == ["93.184.216.34"])
    }
}
