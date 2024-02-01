//
//  DismissSafariActionURLHelper.swift
//  Tangem
//
//  Created by Alexander Osokin on 30.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// `tangem://redirect?action=dismissBrowser`
/// `https://tangem.com/redirect?action=dismissBrowser`
struct DismissSafariActionURLHelper: IncomingActionURLHelper {
    let actionValue: String = "dismissBrowser"

    func buildURL(scheme: IncomingActionScheme) -> URL {
        var urlComponents = URLComponents(string: scheme.baseScheme)!
        urlComponents.percentEncodedQueryItems = [.init(name: IncomingActionConstants.incoimingActionName, value: actionValue)]
        return urlComponents.url!
    }

    func parse(_ url: URL) -> IncomingAction? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        if let action = components.queryItems?.first(where: { $0.name == IncomingActionConstants.incoimingActionName }),
           action.value == actionValue {
            return .dismissSafari
        }

        return nil
    }
}
