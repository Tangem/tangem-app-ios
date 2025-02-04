//
//  Logger.swift
//  TangemModules
//
//  Created by Sergey Balashov on 23.01.2025.
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import OSLog

public struct Logger {
    public typealias Category = OSLogCategory
    public typealias Level = OSLogLevel

    public static var configuration: Configuration = DefaultConfiguration()
    public static var logFile: URL { OSLogFileWriter.shared.logFile }

    private let category: Category

    public init(category: Category) {
        self.category = category
    }
}

// MARK: - Tagable

extension Logger: Logger.Tagable {
    public subscript(tag tag: String) -> Self {
        self.tag(tag)
    }

    public func tag(_ tag: String) -> Logger {
        Logger(category: category.tag(tag))
    }
}

// MARK: - PrefixOption

public extension Logger {
    enum PrefixOption {
        case object(CustomStringConvertible?)
        case verbose(file: StaticString, line: UInt, function: StaticString)
    }
}

public extension Logger {
    // MARK: - Object prefix

    func debug<T, M>(_ object: T?, _ message: @autoclosure () -> M) where T: CustomStringConvertible {
        log(.debug, message: message(), option: .object(object))
    }

    func info<T, M>(_ object: T?, _ message: @autoclosure () -> M) where T: CustomStringConvertible {
        log(.info, message: message(), option: .object(object))
    }

    func warning<T, M>(_ object: T?, _ message: @autoclosure () -> M) where T: CustomStringConvertible {
        log(.warning, message: message(), option: .object(object))
    }

    func error<T, M, E>(_ object: T?, _ message: @autoclosure () -> M, error: @autoclosure () -> E) where T: CustomStringConvertible, E: Error {
        log(.error, message: [message(), error()].describing(), option: .object(object))
    }

    func error<T, E>(_ object: T?, error: @autoclosure () -> E) where T: CustomStringConvertible, E: Error {
        log(.error, message: error(), option: .object(object))
    }

    // MARK: - File prefix

    func debug<M>(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function, _ message: @autoclosure () -> M) {
        log(.debug, message: message(), option: .verbose(file: file, line: line, function: function))
    }

    func info<M>(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function, _ message: @autoclosure () -> M) {
        log(.info, message: message(), option: .verbose(file: file, line: line, function: function))
    }

    func warning<M>(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function, _ message: @autoclosure () -> M) {
        log(.warning, message: message(), option: .verbose(file: file, line: line, function: function))
    }

    func error<M, E>(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function, _ message: @autoclosure () -> M, error: @autoclosure () -> E) where E: Error {
        log(.error, message: [message(), error()].describing(), option: .verbose(file: file, line: line, function: function))
    }

    func error<E>(file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function, error: @autoclosure () -> E) where E: Error {
        log(.error, message: error(), option: .verbose(file: file, line: line, function: function))
    }
}

// MARK: - Helpers

private extension Logger {
    func log<M>(_ level: OSLog.Level, message: @autoclosure () -> M, option: PrefixOption) {
        let message: String = {
            if let prefix = category.prefix?(level, option) {
                return [prefix, message()].describing()
            }

            return String(describing: message())
        }()

        guard Logger.configuration.isLoggable() else {
            return
        }

        do {
            OSLog.logger(for: category).log(level: level, message: "\(message)")
            try OSLogFileWriter.shared.write(message, category: category, level: level)
        } catch {
            OSLog.logger(for: .logFileWriter).fault("\(error.localizedDescription)")
        }
    }
}

private extension [Any] {
    func describing(separator: String = " ") -> String {
        map(String.init(describing:)).joined(separator: separator)
    }
}
