//
//  TangemNetworkLoggerPlugin.swift
//  BlockchainSdk
//
//  Created by Dmitry Fedorov on 21.03.2024.
//

import Foundation
import Moya

public final class TangemNetworkLoggerPlugin {
    let configuration: TangemNetworkLoggerPlugin.Configuration

    public init(configuration: TangemNetworkLoggerPlugin.Configuration) {
        self.configuration = configuration
    }
}

extension TangemNetworkLoggerPlugin: PluginType {
    public func willSend(_ request: RequestType, target: TargetType) {
        logNetworkRequest(request, target: target) { [weak self] output in
            self?.configuration.output(target, output)
        }
    }

    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            configuration.output(target, logSuccessNetworkResponse(response, target: target))
        case .failure(let error):
            configuration.output(target, logNetworkError(error, target: target))
        }
    }
}

extension TangemNetworkLoggerPlugin {
    func logNetworkRequest(_ request: RequestType, target: TargetType, completion: @escaping ([String]) -> Void) {
        // Request presence check
        guard let httpRequest = request.request else {
            completion(["\(TangemNetworkLoggerConstants.networkPrefix) Invalid request ❌: \(target.requestDescription)"])
            return
        }

        // Adding log entries for each given log option
        var output: [String] = []

        output.append("Request ➡️: \(target.requestDescription)")

        if configuration.logOptions.contains(.requestMethod),
           let httpMethod = httpRequest.httpMethod {
            output.append("Method: \(httpMethod)")
        }

        if configuration.logOptions.contains(.requestMethod) {
            var allHeaders = request.sessionHeaders

            if let httpRequestHeaders = httpRequest.allHTTPHeaderFields {
                allHeaders.merge(httpRequestHeaders) { $1 }
            }

            let headerKeys = allHeaders.keys.joined(separator: ",")

            output.append("Headers: \(headerKeys)")
        }

        if configuration.logOptions.contains(.requestBody), target.shouldLogResponseBody {
            if let bodyStream = httpRequest.httpBodyStream {
                output.append("Body stream: \(bodyStream.description)")
            }

            if let body = httpRequest.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                output.append("Body: \(bodyString)")
            }
        }

        completion([formatOutput(output)])
    }

    func logSuccessNetworkResponse(_ response: Response, target: TargetType) -> [String] {
        // Adding log entries for each given log option
        var output: [String] = []

        // Response presence check
        if response.response != nil {
            output.append("Response ✅ \(response.statusCode): \(target.requestDescription)")
        } else {
            output.append("Response empty ⚠ \(response.statusCode): \(target.requestDescription)")
        }

        if configuration.logOptions.contains(.successResponseBody),
           target.shouldLogResponseBody,
           let bodyString = String(data: response.data, encoding: .utf8) {
            output.append("Body: \(bodyString)")
        }

        return [formatOutput(output)]
    }

    func logErrorNetworkResponse(_ response: Response, target: TargetType) -> [String] {
        // Adding log entries for each given log option
        var output: [String] = []

        // Response presence check
        if response.response != nil {
            output.append("Response ✅ \(response.statusCode): \(target.requestDescription)")
        } else {
            output.append("Response empty ⚠ \(response.statusCode): \(target.requestDescription)")
        }

        if configuration.logOptions.contains(.errorResponseBody),
           let bodyString = String(data: response.data, encoding: .utf8) {
            output.append("Body: \(bodyString)")
        }

        return [formatOutput(output)]
    }

    func logNetworkError(_ error: MoyaError, target: TargetType) -> [String] {
        // Some errors will still have a response, like errors due to Alamofire's HTTP code validation.
        if let moyaResponse = error.response {
            return logErrorNetworkResponse(moyaResponse, target: target)
        }

        // Errors without an HTTPURLResponse are those due to connectivity, time-out and such.
        return [formatOutput(["Response error ❌: \(target.requestDescription) : \(error)"])]
    }

    private func formatOutput(_ output: [String]) -> String {
        return "\(TangemNetworkLoggerConstants.networkPrefix) \(output.joined(separator: "; "))"
    }
}

// MARK: - Configuration

public extension TangemNetworkLoggerPlugin {
    struct Configuration {
        // MARK: - Typealiases

        // swiftlint:disable nesting
        public typealias OutputType = (_ target: TargetType, _ items: [String]) -> Void
        // swiftlint:enable nesting

        // MARK: - Properties

        public var output: OutputType
        public var logOptions: LogOptions

        /// The designated way to instantiate a Configuration.
        ///
        /// - Parameters:
        ///   - formatter: An object holding all formatter closures available for customization.
        ///   - output: A closure responsible for writing the given log entries into your log system.
        ///     The default value writes entries to the debug console.
        ///   - logOptions: A set of options you can use to customize which request component is logged.
        public init(
            output: @escaping OutputType = defaultOutput,
            logOptions: LogOptions = .default
        ) {
            self.output = output
            self.logOptions = logOptions
        }

        // MARK: - Defaults

        public static func defaultOutput(target: TargetType, items: [String]) {
            for item in items {
                print(item, separator: ",", terminator: "\n")
            }
        }
    }
}

public extension TangemNetworkLoggerPlugin.Configuration {
    struct LogOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        /// The request's method will be logged.
        public static let requestMethod: LogOptions = .init(rawValue: 1 << 0)
        /// The request's body will be logged.
        public static let requestBody: LogOptions = .init(rawValue: 1 << 1)
        /// The request's headers will be logged.
        public static let requestHeaders: LogOptions = .init(rawValue: 1 << 2)
        /// The body of a response that is a success will be logged.
        public static let successResponseBody: LogOptions = .init(rawValue: 1 << 4)
        /// The body of a response that is an error will be logged.
        public static let errorResponseBody: LogOptions = .init(rawValue: 1 << 5)

        // Aggregate options
        /// Only basic components will be logged.
        public static let `default`: LogOptions = [requestMethod, requestHeaders]
        /// All components will be logged.
        public static let verbose: LogOptions = [
            requestMethod,
            requestHeaders,
            requestBody,
            successResponseBody,
            errorResponseBody,
        ]
    }
}

// MARK: TargetType+

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
