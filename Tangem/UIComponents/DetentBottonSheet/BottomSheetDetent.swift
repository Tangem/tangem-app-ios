//
//  BottomSheetDetent.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

enum BottomSheetDetent: Hashable {
    case medium
    case large
    case custom(CGFloat)
    case fraction(CGFloat)

    @available(iOS 16.0, *)
    var detentsAboveIOS16: PresentationDetent {
        switch self {
        case .large:
            return PresentationDetent.large
        case .medium:
            return PresentationDetent.medium
        case .custom(let height):
            return .height(height)
        case .fraction(let value):
            return .fraction(value)
        }
    }

    var detentsBelowIOS16: UISheetPresentationController.Detent {
        switch self {
        case .large, .custom(_), .fraction:
            return UISheetPresentationController.Detent.large()
        case .medium:
            return UISheetPresentationController.Detent.medium()
        }
    }
}
