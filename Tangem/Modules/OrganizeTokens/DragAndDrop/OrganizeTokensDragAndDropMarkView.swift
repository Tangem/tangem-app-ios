//
//  OrganizeTokensDragAndDropMarkView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

/// Used for two purposes:
///  - to 'mark' the parts of the UI as eligible for starting a drag-and-drop gesture (long press and then drag).
///  - to transfer the value of drag-and-drop gesture context (`identifier`) between 'SwiftUI-UIKit' domains and vice versa.
struct OrganizeTokensDragAndDropGestureMarkView: UIViewRepresentable {
    typealias UIViewType = MarkUIView

    /// Contains all alive and currently used instances of `UIViewType`.
    static var allInstances: Set<UIViewType> = []

    var context: GestureContext

    func makeUIView(context _: Context) -> UIViewType {
        let uiView = UIViewType()
        uiView.context = context
        Self.allInstances.insert(uiView)

        return uiView
    }

    func updateUIView(_ uiView: UIViewType, context _: Context) {
        uiView.context = context
    }

    static func dismantleUIView(_ uiView: UIViewType, coordinator: Void) {
        Self.allInstances.remove(uiView)
    }
}

// MARK: - Auxiliary types

extension OrganizeTokensDragAndDropGestureMarkView {
    final class MarkUIView: UIView {
        var context: OrganizeTokensDragAndDropGestureMarkView.GestureContext?
    }

    struct GestureContext {
        let identifier: AnyHashable
    }
}
