//
//  TangemNetworkLoggerPlugin.swift
//  TangemNetworkUtils
//
//  Created by Dmitry Fedorov on 21.03.2024.
//

import Foundation
import Moya
import Alamofire

public final class TangemNetworkLoggerPlugin {
    public let logOptions: LogOptions

    public init(logOptions: LogOptions) {
        self.logOptions = logOptions
    }
}

extension TangemNetworkLoggerPlugin: PluginType {
    public func willSend(_ request: RequestType, target: TargetType) {
        logNetworkRequest(request, target: target) { [weak self] output in
            NetworkLogger.info(output)
        }
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            NetworkLogger.info(logSuccessNetworkResponse(response, target: target))
        case .failure(.underlying(AFError.explicitlyCancelled, let response)):
            NetworkLogger.warning(logNetworkError(.underlying(AFError.explicitlyCancelled, response), target: target))
        case .failure(let error):
            NetworkLogger.error(logNetworkError(error, target: target), error: error)
        }
    }
}

extension TangemNetworkLoggerPlugin {
    func logNetworkRequest(_ request: RequestType, target: TargetType, completion: @escaping (String) -> Void) {
        // Request presence check
        guard let httpRequest = request.request else {
            completion("Invalid request ❌: \(target.requestDescription)")
            return
        }

        // Adding log entries for each given log option
        var output: [String] = []

        output.append("Request ➡️: \(target.requestDescription)")

        if logOptions.contains(.requestMethod),
           let httpMethod = httpRequest.httpMethod {
            output.append("Method: \(httpMethod)")
        }

        if logOptions.contains(.requestMethod) {
            var allHeaders = request.sessionHeaders

            if let httpRequestHeaders = httpRequest.allHTTPHeaderFields {
                allHeaders.merge(httpRequestHeaders) { $1 }
            }

            let headerKeys = allHeaders.keys.joined(separator: ",")

            output.append("Headers: \(headerKeys)")
        }

        if logOptions.contains(.requestBody), target.shouldLogResponseBody {
            if let bodyStream = httpRequest.httpBodyStream {
                output.append("Body stream: \(bodyStream.description)")
            }

            if let body = httpRequest.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                output.append("Body: \(bodyString)")
            }
        }

        completion(formatOutput(output))
    }

    func logSuccessNetworkResponse(_ response: Response, target: TargetType) -> String {
        // Adding log entries for each given log option
        var output: [String] = []

        // Response presence check
        if response.response != nil {
            output.append("Response ✅ \(response.statusCode): \(target.requestDescription)")
        } else {
            output.append("Response empty ⚠ \(response.statusCode): \(target.requestDescription)")
        }

        if logOptions.contains(.successResponseBody),
           target.shouldLogResponseBody,
           let bodyString = String(data: response.data, encoding: .utf8) {
            output.append("Body: \(bodyString)")
        }

        return formatOutput(output)
    }

    func logErrorNetworkResponse(_ response: Response, target: TargetType) -> String {
        // Adding log entries for each given log option
        var output: [String] = []

        // Response presence check
        if response.response != nil {
            output.append("Response ✅ \(response.statusCode): \(target.requestDescription)")
        } else {
            output.append("Response empty ⚠ \(response.statusCode): \(target.requestDescription)")
        }

        if logOptions.contains(.errorResponseBody),
           let bodyString = String(data: response.data, encoding: .utf8) {
            output.append("Body: \(bodyString)")
        }

        return formatOutput(output)
    }

    func logNetworkError(_ error: MoyaError, target: TargetType) -> String {
        // Some errors will still have a response, like errors due to Alamofire's HTTP code validation.
        if let moyaResponse = error.response {
            return logErrorNetworkResponse(moyaResponse, target: target)
        }

        // Errors without an HTTPURLResponse are those due to connectivity, time-out and such.
        return formatOutput(["Response error ❌: \(target.requestDescription) : \(error)"])
    }

    private func formatOutput(_ output: [String]) -> String {
        return output.joined(separator: "; ")
    }
}

// MARK: - LogOptions

public extension TangemNetworkLoggerPlugin {
    typealias LogOptions = NetworkLoggerPlugin.Configuration.LogOptions
}

// MARK: - TargetType+

private extension TargetType {
    var requestDescription: String {
        var description = ""

        if let logConvertible = self as? TargetTypeLogConvertible {
            description = logConvertible.requestDescription
        } else {
            description = path.isEmpty ? "❗️❗️❗️TargetTypeLogConvertible is missing" : path
        }

        return "\(baseURL.hostOrUnknown); Info: \(description)"
    }

    var shouldLogResponseBody: Bool {
        (self as? TargetTypeLogConvertible)?.shouldLogResponseBody ?? true
    }
}
