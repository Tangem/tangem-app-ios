//
//  ExceptionHandler.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 21.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol ExceptionHandlerOutput {
    func handleAPISwitch(currentHost: String, nextHost: String, message: String)
}

public final class ExceptionHandler {
    // MARK: - Static
    
    public static let shared: ExceptionHandler = .init()
    
    // MARK: - Properties
    
    private var outputs: [ExceptionHandlerOutput] = []
    
    // MARK: - Configuration
    
    public func append(output: ExceptionHandlerOutput) {
        self.outputs.append(output)
    }

    // MARK: - Handle
    
    func handleAPISwitch(currentHost: String, nextHost: String, message: String) {
        self.outputs.forEach { output in
            output.handleAPISwitch(
                currentHost: currentHost,
                nextHost: nextHost,
                message: message
            )
        }
    }
}
