//
//  BlockchainURLSchemesParser.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 26.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// Parser for custom blockchains URL schemes, e.g. bitcoin:, doge: etc.
/// current implementation just chekcs that url scheme is supported,
/// actual parsing may be implemented in the future
struct BlockchainURLSchemesParser: IncomingActionURLParser {
    func parse(_ url: URL) -> IncomingAction? {
        guard !url.absoluteString.starts(with: IncomingActionConstants.universalLinkScheme),
              SupportedURLSchemeCheck.isURLSchemeSupported(for: url) else {
            return nil
        }

        return .start
    }
}
