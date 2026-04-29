import Foundation

public struct PapyrusURLRequest: PapyrusRequest {
    public var url: URL
    public var method: String
    public var headers: PapyrusHeaders
    public var body: Data?
    public var behaviors: PapyrusBehaviors

    public init(
        url: URL,
        method: String,
        headers: PapyrusHeaders,
        body: Data?,
        behaviors: PapyrusBehaviors = PapyrusBehaviors()
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.behaviors = behaviors
    }
}
