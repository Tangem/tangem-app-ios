//
//  SafariManager.swift
//  Tangem
//
//  Created by Alexander Osokin on 23.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SafariServices

// MARK: - SafariManager

protocol SafariManager {
    /// You should retain the handle in the coordionator always
    func openURL(
        _ url: URL,
        configuration: SafariConfiguration,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL) -> Void
    ) -> SafariHandle

    /// For any calls without callback
    func openURL(_ url: URL, configuration: SafariConfiguration)
}

extension SafariManager {
    func openURL(_ url: URL, configuration: SafariConfiguration = .init(), onSuccess: @escaping (URL) -> Void = { _ in }) -> SafariHandle {
        openURL(url, configuration: configuration, onDismiss: {}, onSuccess: onSuccess)
    }

    func openURL(_ url: URL, configuration: SafariConfiguration = .init()) {
        openURL(url, configuration: configuration)
    }
}

// MARK: - SafariHandle

protocol SafariHandle: AnyObject {}

// MARK: - Dependencies

private struct SafariManagerKey: InjectionKey {
    static var currentValue: SafariManager = CommonSafariManager()
}

extension InjectedValues {
    var safariManager: SafariManager {
        get { Self[SafariManagerKey.self] }
        set { Self[SafariManagerKey.self] = newValue }
    }
}

// MARK: - CommonSafariManager

class CommonSafariManager: NSObject, SafariManager {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging

    private weak var context: SafariContext?

    override init() {
        super.init()
        incomingActionManager.becomeFirstResponder(self)
    }

    func openURL(_ url: URL, configuration: SafariConfiguration) {
        openURL(url, configuration: configuration, onDismiss: {}, onSuccess: { _ in })
    }

    @discardableResult
    func openURL(
        _ url: URL,
        configuration: SafariConfiguration,
        onDismiss: @escaping () -> Void,
        onSuccess: @escaping (URL) -> Void
    ) -> SafariHandle {
        AppLog.info("Open URL: \(url)")
        let controller = SFSafariViewController(url: url)
        controller.modalPresentationStyle = .pageSheet
        controller.dismissButtonStyle = configuration.dismissButtonStyle.sfDismissButtonStyle
        controller.delegate = self
        controller.presentationController?.delegate = self
        let context = SafariContext(controller: controller, onDismiss: onDismiss, onSuccess: onSuccess)
        self.context = context
        AppPresenter.shared.show(controller)
        return context
    }

    func dismiss(with url: URL) {
        // already dismissed by user, but we received an url from Safari
        if context?.controller.presentingViewController == nil {
            context?.onSuccess(url)
            return
        }

        context?.controller.dismiss(animated: true, completion: { [weak self] in
            self?.context?.onSuccess(url)
        })
    }
}

// MARK: - SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate

extension CommonSafariManager: SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        context?.onDismiss()
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        context?.onDismiss()
    }
}

// MARK: - IncomingActionResponder

extension CommonSafariManager: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .dismissSafari(let url) = action else {
            return false
        }

        dismiss(with: url)
        return true
    }
}

// MARK: - SafariContext

class SafariContext: SafariHandle {
    let controller: SFSafariViewController
    let onDismiss: () -> Void
    let onSuccess: (URL) -> Void

    init(controller: SFSafariViewController, onDismiss: @escaping () -> Void, onSuccess: @escaping ((URL) -> Void)) {
        self.controller = controller
        self.onDismiss = onDismiss
        self.onSuccess = onSuccess
    }
}

// MARK: - Configuration mappings

private extension SafariConfiguration.DismissButtonStyle {
    var sfDismissButtonStyle: SFSafariViewController.DismissButtonStyle {
        switch self {
        case .done:
            return .done
        case .close:
            return .close
        case .cancel:
            return .cancel
        }
    }
}
