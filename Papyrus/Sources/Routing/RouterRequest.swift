import Foundation

public struct RouterRequest {
    public let url: URL
    public let method: String
    public let headers: PapyrusHeaders
    public let body: Data?

    public init(url: URL, method: String, headers: PapyrusHeaders, body: Data?) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}
