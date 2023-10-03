//
//  ApplePayButton.swift
//  TangemShopify
//
//  Created by Andy on 22.12.2021.
//

import SwiftUI
import PassKit

struct ApplePayButton: UIViewRepresentable {
    let type: PKPaymentButtonType
    let action: () -> Void

    func makeUIView(context: Context) -> some UIView {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: .automatic)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.didTapButton),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator {
        let button: ApplePayButton

        init(_ button: ApplePayButton) {
            self.button = button
        }

        @objc
        func didTapButton() {
            button.action()
        }
    }
}

struct ApplePayButton_Previews: PreviewProvider {
    static var previews: some View {
        ApplePayButton(type: .buy, action: {})
            .frame(height: 45)
            .padding(.horizontal)
    }
}
