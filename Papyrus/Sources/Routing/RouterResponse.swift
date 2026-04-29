import Foundation

public struct RouterResponse {
    public let status: Int
    public let headers: PapyrusHeaders
    public let body: Data?

    public init(_ status: Int, headers: PapyrusHeaders = [:], body: Data? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}
