//
//  VIew+.swift
//  Tangem
//
//  Created by Alexander Osokin on 02.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func style(_ font: Font, color: Color) -> some View {
        self.font(font).foregroundColor(color)
    }

    /// A way to hide a SwiftUI view without altering the structural identity.
    /// See https://developer.apple.com/tutorials/swiftui-concepts/choosing-the-right-way-to-hide-a-view for details
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0.0 : 1.0)
    }

    func visible(_ shouldShow: Bool) -> some View {
        hidden(!shouldShow)
    }

    @ViewBuilder
    func matchedGeometryEffectOptional<ID>(id: ID?, in namespace: Namespace.ID?, properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center, isSource: Bool = true) -> some View where ID: Hashable {
        if let id, let namespace {
            matchedGeometryEffect(id: id, in: namespace, properties: properties, anchor: anchor, isSource: isSource)
        } else if id == nil, namespace == nil {
            self
        } else {
            #if DEBUG
            fatalError("You must set either both ID and namespace or neither")
            #else
            self
            #endif
        }
    }

    @ViewBuilder
    func matchedGeometryEffect(_ effect: GeometryEffect?) -> some View {
        if let effect {
            matchedGeometryEffect(id: effect.id, in: effect.namespace, isSource: effect.isSource)
        } else {
            self
        }
    }
}
