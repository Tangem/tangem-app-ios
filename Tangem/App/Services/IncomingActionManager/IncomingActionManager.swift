//
//  IncomingActionManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

typealias IncomingActionManager = IncomingActionHandler & IncomingActionManaging

public protocol IncomingActionHandler {
    func handleDeeplink(_ url: URL) -> Bool
    func handleIntent(_ intent: String) -> Bool
}

/// Object's interface for encapsulating logic of deeplink handling
public protocol IncomingActionManaging: AnyObject {
    func becomeFirstResponder(_ responder: IncomingActionResponder)
    func resignFirstResponder(_ responder: IncomingActionResponder)
    func discardIncomingAction()
}

public protocol IncomingActionResponder: AnyObject {
    /// Asks responder to handle route. If it returns `true`, previous responders are not called.
    /// If it returns `false`, previous responder is called to handle route.
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool
}

// MARK: - Dependencies

private struct IncomingActionManagerKey: InjectionKey {
    static var currentValue: IncomingActionManager = CommonIncomingActionManager()
}

extension InjectedValues {
    var incomingActionHandler: IncomingActionHandler {
        manager
    }

    var incomingActionManager: IncomingActionManaging {
        manager
    }

    private var manager: IncomingActionManager {
        get { Self[IncomingActionManagerKey.self] }
        set { Self[IncomingActionManagerKey.self] = newValue }
    }
}
