//
//  OrganizeTokensDragAndDropGestureContextProvider.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

struct OrganizeTokensDragAndDropGestureContextProvider: DragAndDropGestureContextProviding {
    private static let validGestureRecognizerStates: Set<UIGestureRecognizer.State> = [
        .began,
    ]

    func makeContext(from gestureRecognizer: UIGestureRecognizer) -> AnyHashable? {
        guard
            Self.validGestureRecognizerStates.contains(gestureRecognizer.state),
            let window = gestureRecognizer.view?.window
        else {
            return nil
        }

        let globalPoint = gestureRecognizer.location(in: nil)

        for uiView in OrganizeTokensDragAndDropGestureMarkView.allInstances {
            let globalFrame = window.convert(uiView.frame, from: uiView.superview)
            if globalFrame.contains(globalPoint) {
                return uiView.context?.identifier
            }
        }

        return nil
    }
}
