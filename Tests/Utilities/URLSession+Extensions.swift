import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {

  /// Defines the possible errors
  enum URLSessionAsyncErrors: Error {
      case invalidUrlResponse(String?)
      case missingResponseData
  }

  func asyncData(from url: URL) async throws -> (Data?, URLResponse?) {
    return try await withCheckedThrowingContinuation { continuation in
      let task = self.dataTask(with: url) { data, response, error in
        if let error = error {
          continuation.resume(throwing: NSError(domain: "\(#file)", code: -1000, userInfo: [ NSLocalizedDescriptionKey: error.localizedDescription ]))
          return
        }

        guard
          let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode)
        else {
          continuation.resume(throwing: URLSessionAsyncErrors.invalidUrlResponse("\((response as? HTTPURLResponse)?.statusCode ?? 0)"))
          return
        }

        guard let data = data else {
          continuation.resume(throwing: URLSessionAsyncErrors.missingResponseData)
          return
        }

        continuation.resume(returning: (data, response))
      }
      task.resume()
    }
  }
}
