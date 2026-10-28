import XCTest
@testable import Wordroot

// With no connection, a page that was looked up before comes back from the cache.
final class OfflineTests: XCTestCase {
    final class NoNetwork: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "offline.test" }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        // Like the system loader: a cache-only request is answered from the cache, anything else fails offline.
        override func startLoading() {
            if request.cachePolicy == .returnCacheDataDontLoad, let cached = cachedResponse {
                client?.urlProtocol(self, cachedResponseIsValid: cached)
                client?.urlProtocolDidFinishLoading(self)
            } else {
                client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            }
        }
        override func stopLoading() {}
    }

    func testLookedUpPageOpensOffline() async throws {
        URLProtocol.registerClass(NoNetwork.self)
        defer { URLProtocol.unregisterClass(NoNetwork.self) }
        let url = URL(string: "https://offline.test/w/api.php?page=salt")!
        let body = Data("{\"parse\":{}}".utf8)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Cache-Control": "max-age=0, must-revalidate"])!
        URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: body), for: Wiktionary.request(url))
        let (data, _) = try await Wiktionary.load(url)
        XCTAssertEqual(data, body)
    }
}
