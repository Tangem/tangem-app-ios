//
//  IncomingActionParser.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import TangemFoundation

public class IncomingActionParser {
    @Injected(\.walletConnectService) private var walletConnectService: WalletConnectService

    private var incomingActionURLParsers: [IncomingActionURLParser] = [
        NDEFURLParser(),
        DismissSafariActionURLHelper(),
        SellActionURLHelper(),
        WalletConnectURLParser(),
        BlockchainURLSchemesParser(),
    ]

    public init() {}

    public func parseDeeplink(_ url: URL) -> IncomingAction? {
        guard validateURL(url) else { return nil }

        for parser in incomingActionURLParsers {
            if let action = try? parser.parse(url) {
                return action
            }
        }

        return nil
    }

    public func parseIntent(_ intent: String) -> IncomingAction? {
        switch intent {
        case AppIntent.scanCard.rawValue:
            return .start
        default:
            AppLogger.warning("Received unknown intent: \(intent)")
            return nil
        }
    }

    private func validateURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString

        if urlString.starts(with: IncomingActionConstants.tangemDomain)
            || urlString.starts(with: IncomingActionConstants.appTangemDomain)
            || url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme)
            || SupportedURLSchemeCheck.isURLSchemeSupported(for: url) {
            return true
        }

        return false
    }
}

private extension IncomingActionParser {
    enum AppIntent: String {
        case scanCard = "ScanTangemCardIntent"
    }
}

enum SupportedURLSchemeCheck {
    static func isURLSchemeSupported(for url: URL) -> Bool {
        guard let supportedSchemes: [[String]] = InfoDictionaryUtils.bundleURLSchemes.value() else {
            // impossible case
            return false
        }
        return supportedSchemes.flatMap { $0 }.contains(url.scheme ?? "")
    }
}
