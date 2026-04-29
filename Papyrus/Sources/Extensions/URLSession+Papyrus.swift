import Foundation
#if os(Linux)
import FoundationNetworking
#endif

extension Provider {
    public init(
        baseURL: String,
        urlSession: URLSession = .shared,
        modifiers: [any RequestModifier] = [],
        interceptors: [any Interceptor] = []
    ) {
        self.init(baseURL: baseURL, http: urlSession, modifiers: modifiers, interceptors: interceptors)
    }
}

// MARK: `HTTPService` Conformance

extension URLSession: HTTPService {
    public func build(from builder: RequestBuilder) throws -> PapyrusRequest {
        let url = try builder.fullURL()
        let (body, headers) = try builder.bodyAndHeaders()
        return PapyrusURLRequest(
            url: url,
            method: builder.method,
            headers: headers,
            body: body,
            behaviors: builder.behaviors
        )
    }

    public func request(_ req: PapyrusRequest) async -> PapyrusResponse {
        var urlRequest = URLRequest(url: req.url)
        urlRequest.httpMethod = req.method
        urlRequest.allHTTPHeaderFields = req.headers
        urlRequest.httpBody = req.body

        #if os(Linux) // Linux doesn't have access to async URLSession APIs
        return await withCheckedContinuation { continuation in
            dataTask(with: urlRequest) { data, response, error in
                let response = _Response(papyrusRequest: req, urlRequest: urlRequest, response: response, error: error, body: data)
                continuation.resume(returning: response)
            }.resume()
        }
        #else
        do {
            let (data, res) = try await data(for: urlRequest)
            return _Response(papyrusRequest: req, urlRequest: urlRequest, response: res, error: nil, body: data)
        } catch {
            return _Response(papyrusRequest: req, urlRequest: urlRequest, response: nil, error: error, body: nil)
        }
        #endif
    }
}

// MARK: `Response` Conformance

extension PapyrusResponse {
    public var urlRequest: URLRequest { (self as! _Response).urlRequest }
    public var urlResponse: URLResponse? { (self as! _Response).urlResponse }
}

private struct _Response: PapyrusResponse {
    let urlRequest: URLRequest
    let urlResponse: URLResponse?

    var request: PapyrusRequest?
    let error: Error?
    let body: Data?
    let headers: [String: String]?
    var statusCode: Int? { (urlResponse as? HTTPURLResponse)?.statusCode }

    init(papyrusRequest: PapyrusRequest, urlRequest: URLRequest, response: URLResponse?, error: Error?, body: Data?) {
        self.request = papyrusRequest
        self.urlRequest = urlRequest
        self.urlResponse = response
        self.error = error
        self.body = body
        let headerPairs = (response as? HTTPURLResponse)?
            .allHeaderFields
            .compactMap { key, value -> (String, String)? in
                guard let key = key as? String, let value = value as? String else {
                    return nil
                }

                return (key, value)
            }
        if let headerPairs {
            self.headers = .init(uniqueKeysWithValues: headerPairs)
        } else {
            self.headers = nil
        }
    }
}
