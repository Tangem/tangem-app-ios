//
//  Analytics+WalletConnectDebugEvent.swift
//  Tangem
//
//  Created by Andrew Son on 31/10/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum WalletConnectDebugEvent {
        case webSocketConnected
        case webSocketDisconnected(closeCode: String, connectionState: String)
        case webSocketReceiveText(connectionState: String)
        case webSocketConnectionError(source: ConnectionErrorSource, error: Error)
        case webSocketConnectionTimeout
        case attemptingToOpenSession(url: String)
        case receiveSessionProposal(name: String, dAppURL: String)
        case receiveRequestFromDApp(method: String)
        case errorShownToTheUser(error: String)
        case attemptingToWriteMessageMultipleTimes
        case connectionSetupMessage(message: String)
    }
}

extension Analytics.WalletConnectDebugEvent: AnalyticsDebugEvent {
    var title: String {
        let prefix = "[WalletConnect Debug] "
        let webSocketPrefix = "Web socket "
        let suffix: String
        switch self {
        case .webSocketConnected:
            suffix = webSocketPrefix + "connected"
        case .webSocketDisconnected:
            suffix = webSocketPrefix + "receive disconnected event"
        case .webSocketReceiveText:
            suffix = webSocketPrefix + "receive text"
        case .webSocketConnectionError:
            suffix = webSocketPrefix + "receive connection error"
        case .webSocketConnectionTimeout:
            suffix = webSocketPrefix + "not connected and timeout for reconnection"
        case .attemptingToOpenSession:
            suffix = "Attempting to open new session"
        case .receiveSessionProposal:
            suffix = "Receive session proposal"
        case .receiveRequestFromDApp:
            suffix = "Receive request from dApp"
        case .errorShownToTheUser:
            suffix = "WalletConnectV2Service displays error to user"
        case .attemptingToWriteMessageMultipleTimes:
            suffix = webSocketPrefix + "write(message) called from WC library multiple times..."
        case .connectionSetupMessage:
            suffix = webSocketPrefix + "message during attempting to connect"
        }

        return prefix + suffix
    }

    var analyticsParams: [String: Any] {
        switch self {
        case .webSocketConnected, .attemptingToWriteMessageMultipleTimes, .webSocketConnectionTimeout:
            return [:]
        case .webSocketReceiveText(let connectionState):
            return [
                ParamKey.webSocketState.rawValue: connectionState,
            ]
        case .webSocketDisconnected(let closeCode, let connectionState):
            return [
                ParamKey.webSocketCloseCode.rawValue: closeCode,
                ParamKey.webSocketState.rawValue: connectionState,
            ]
        case .webSocketConnectionError(let source, let error):
            return [
                ParamKey.connectionErrorSource.rawValue: source.rawValue,
                ParamKey.webSocketConnectionError.rawValue: error.localizedDescription,
            ]
        case .attemptingToOpenSession(let url):
            return [ParamKey.dAppPairingURL.rawValue: url]
        case .receiveSessionProposal(let name, let dAppURL):
            return [
                ParamKey.dAppName.rawValue: name,
                ParamKey.dAppURL.rawValue: dAppURL,
            ]
        case .receiveRequestFromDApp(let method):
            return [
                ParamKey.requestMethod.rawValue: method,
            ]
        case .errorShownToTheUser(let error):
            return [
                ParamKey.errorShownToTheUser.rawValue: error,
            ]
        case .connectionSetupMessage(let message):
            return [
                ParamKey.connectionSetupMessage.rawValue: message,
            ]
        }
    }
}

extension Analytics.WalletConnectDebugEvent {
    enum ConnectionErrorSource: String {
        case send
        case receive
        case pingPong
        case webSocketConnectionDelegate
    }
}

private extension Analytics.WalletConnectDebugEvent {
    enum ParamKey: String {
        case webSocketCloseCode
        case webSocketState
        case webSocketConnectionError
        case dAppPairingURL
        case dAppName
        case dAppURL
        case requestMethod
        case errorShownToTheUser
        case connectionSetupMessage
        case connectionErrorSource
    }
}
