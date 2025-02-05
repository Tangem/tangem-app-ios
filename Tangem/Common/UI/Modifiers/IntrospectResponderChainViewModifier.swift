//
//  IntrospectResponderChainViewModifier.swift
//  Tangem
//
//  Created by Andrey Fedorov on 14.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

// MARK: - Convenience extensions

extension View {
    @ViewBuilder
    func introspectResponderChain<IntrospectedType>(
        introspectedType: IntrospectedType.Type,
        updateOnChangeOf: AnyHashable? = nil,
        action: @escaping (_ introspectedInstance: IntrospectedType) -> Void
    ) -> some View {
        modifier(IntrospectResponderChainViewModifier(introspectedType: introspectedType, updateOnChangeOf: updateOnChangeOf, action: action))
    }
}

// MARK: - Private implementation

private struct IntrospectResponderChainViewModifier<IntrospectedType>: ViewModifier {
    typealias Action = (_ introspectedInstance: IntrospectedType) -> Void

    let introspectedType: IntrospectedType.Type
    let updateOnChangeOf: AnyHashable?
    let action: Action

    func body(content: Content) -> some View {
        content.overlay {
            IntrospectView(introspectedType: introspectedType, action: action)
                .frame(size: .zero)
                .allowsHitTesting(false)
                .accessibility(hidden: true)
                .modifier(ifLet: updateOnChangeOf) { view, id in
                    view.id(id)
                }
        }
    }
}

// MARK: - Auxiliary types

private extension IntrospectResponderChainViewModifier {
    struct IntrospectView: UIViewRepresentable {
        typealias UIViewType = UIView

        let introspectedType: IntrospectedType.Type
        let action: Action

        func makeUIView(context: Context) -> UIViewType {
            return UIView()
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {
            var nextResponder = uiView.next
            while nextResponder != nil {
                if let introspectedInstance = nextResponder as? IntrospectedType {
                    action(introspectedInstance)
                    break
                }
                nextResponder = nextResponder?.next
            }
        }
    }
}
