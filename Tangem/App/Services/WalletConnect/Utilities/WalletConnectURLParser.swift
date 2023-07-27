//
//  WalletConnectURLParser.swift
//  Tangem
//
//  Created by Alexander Osokin on 31.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletConnectURLParser {
    func parse(_ uriString: String) -> WalletConnectRequestURI? {
        if let wcURI = WalletConnectV2URI(string: uriString) {
            return .v2(wcURI)
        }

        return nil
    }

    func parse(_ url: URL) -> WalletConnectRequestURI? {
        guard let uri = extractURI(from: url) else {
            return nil
        }

        return parse(uri)
    }

    private func extractURI(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.path == Constants.wcPrefix || components.host == Constants.wcHost,
              components.queryItems?.first?.name == Constants.uriName else {
            return nil
        }

        return components.query?.remove(Constants.uriPrefix)
    }
}

extension WalletConnectURLParser {
    private enum Constants {
        static let uriPrefix = "\(uriName)="
        static let uriName = "uri"
        static let wcPrefix = "/\(wcHost)"
        static let wcHost = "wc"
    }
}

public enum WalletConnectRequestURI {
    case v2(WalletConnectV2URI)
}
