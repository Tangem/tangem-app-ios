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
            configuration.output(target, logNetworkResponse(response, target: target, isFromError: false))
        case let .failure(error):
            configuration.output(target, logNetworkError(error, target: target))
        }
    }
}

extension TangemNetworkLoggerPlugin {
    func logNetworkRequest(_ request: RequestType, target: TargetType, completion: @escaping ([String]) -> Void) {
        //Request presence check
        guard let httpRequest = request.request,
              let url = httpRequest.url else {
            completion(["Invalid request for \(target)"])
            return
        }
        
        // Adding log entries for each given log option
        var output = [String]()
        
        output.append("Request: \(url)")
        
        if configuration.logOptions.contains(.requestMethod),
           let httpMethod = httpRequest.httpMethod {
            output.append("HTTP method: \(httpMethod)")
        }
        
        if configuration.logOptions.contains(.requestHeaders) {
            var allHeaders = request.sessionHeaders
            if let httpRequestHeaders = httpRequest.allHTTPHeaderFields {
                allHeaders.merge(httpRequestHeaders) { $1 }
            }
            output.append("headers: \(allHeaders.description)")
        }
        
        if configuration.logOptions.contains(.requestBody) {
            if let bodyStream = httpRequest.httpBodyStream {
                output.append("body stream: \(bodyStream.description)")
            }
            
            if let body = httpRequest.httpBody,
               let bodyString = prettyPrint(data: body) {
                output.append("body: \(bodyString)")
            }
        }
        
        completion(output)
    }
    
    func logNetworkResponse(_ response: Response, target: TargetType, isFromError: Bool) -> [String] {
        // Adding log entries for each given log option
        var output = [String]()
        
        //Response presence check
        if let httpResponse = response.response, let url = httpResponse.url {
            output.append("Response: \(url)")
        } else {
            output.append("Empty network response for \(target)")
        }
        
        if (isFromError && configuration.logOptions.contains(.errorResponseBody))
            || configuration.logOptions.contains(.successResponseBody) {
            output.append("body: \(prettyPrint(data: response.data) ?? "## Cannot map data to String ##")")
        }
        
        return output
    }
    
    func logNetworkError(_ error: MoyaError, target: TargetType) -> [String] {
        //Some errors will still have a response, like errors due to Alamofire's HTTP code validation.
        if let moyaResponse = error.response {
            return logNetworkResponse(moyaResponse, target: target, isFromError: true)
        }
        
        //Errors without an HTTPURLResponse are those due to connectivity, time-out and such.
        return ["Received error calling \(target) : \(error)"]
    }
    
    private func prettyPrint(data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        if configuration.logOptions.contains(.prettyPrintJSON),
           let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           JSONSerialization.isValidJSONObject(json),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return String(data: data, encoding: .utf8)
        }
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
        public init(output: @escaping OutputType = defaultOutput,
                    logOptions: LogOptions = .default) {
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
        public static let requestMethod: LogOptions = LogOptions(rawValue: 1 << 0)
        /// The request's body will be logged.
        public static let requestBody: LogOptions = LogOptions(rawValue: 1 << 1)
        /// The request's headers will be logged.
        public static let requestHeaders: LogOptions = LogOptions(rawValue: 1 << 2)
        /// The body of a response that is a success will be logged.
        public static let successResponseBody: LogOptions = LogOptions(rawValue: 1 << 4)
        /// The body of a response that is an error will be logged.
        public static let errorResponseBody: LogOptions = LogOptions(rawValue: 1 << 5)
        
        /// JSON output will be pretty printed
        public static let prettyPrintJSON: LogOptions = LogOptions(rawValue: 1 << 6)
        
        //Aggregate options
        /// Only basic components will be logged.
        public static let `default`: LogOptions = [requestMethod, requestHeaders]
        /// All components will be logged.
        public static let verbose: LogOptions = [requestMethod, requestHeaders, requestBody,
                                                 successResponseBody, errorResponseBody, prettyPrintJSON]
    }
}

