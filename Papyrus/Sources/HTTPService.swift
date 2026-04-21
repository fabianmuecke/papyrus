import Foundation

/// A type that can perform arbitrary HTTP requests.
public protocol HTTPService: Sendable {
    /// Build a `Request` from the given components.
    func build(from builder: RequestBuilder) throws -> PapyrusRequest

    /// Concurrency based API
    func request(_ req: PapyrusRequest) async -> PapyrusResponse
}
