//
//  NonDismissableModalView.swift
//  Tangem
//
//  Created by Andrew Son on 12.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

protocol NonDismissableHostingControllerDelegate: UIAdaptivePresentationControllerDelegate {
    func didDisappear()
}

class NonDismissableHostingController<Content: View>: UIHostingController<Content> {
    weak var delegate: NonDismissableHostingControllerDelegate?

    var isModal: Bool = false

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        parent?.isModalInPresentation = isModal
        parent?.presentationController?.delegate = delegate
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didDisappear()
    }
}

struct NonDismissableModalView<T: View>: UIViewControllerRepresentable {
    let view: T
    let modal: Bool
    let onDismissalAttempt: (() -> Void)?
    let onDismissed: (() -> Void)?

    func makeUIViewController(context: Context) -> UIHostingController<T> {
        let controller = NonDismissableHostingController(rootView: view)
        controller.isModal = modal
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIHostingController<T>, context: Context) {
        context.coordinator.modalView = self
        uiViewController.rootView = view
        uiViewController.isModalInPresentation = modal
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NonDismissableHostingControllerDelegate {
        var modalView: NonDismissableModalView

        init(_ modalView: NonDismissableModalView) {
            self.modalView = modalView
        }

        func didDisappear() {
            modalView.onDismissed?()
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !modalView.modal
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            modalView.onDismissalAttempt?()
        }
    }
}

extension View {
    func presentation(modal: Bool = true, onDismissalAttempt: (() -> Void)? = nil, onDismissed: (() -> Void)? = nil) -> some View {
        NonDismissableModalView(view: self, modal: modal, onDismissalAttempt: onDismissalAttempt, onDismissed: onDismissed)
            .edgesIgnoringSafeArea(.bottom) // Otherwise background doesn't stretch all the way
    }
}
