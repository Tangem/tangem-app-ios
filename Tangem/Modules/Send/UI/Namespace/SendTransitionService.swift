//
//  SendTransitionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendTransitionService {
    var destinationContentOffset: CGPoint = .zero
    var amountContentOffset: CGPoint = .zero
    var validatorsContentOffset: CGPoint = .zero
    var selectedValidatorContentOffset: CGPoint = .zero
    var feeContentOffset: CGPoint = .zero
    var selectedFeeContentOffset: CGPoint = .zero

    // MARK: - Destination

    var destinationAuxiliaryViewTransition: AnyTransition {
        .move(edge: .bottom)
            .combined(with: .opacity)
            .animation(SendTransitionService.Constants.auxiliaryViewAnimation)
    }

    func transitionToDestinationStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -destinationContentOffset.y) : .move(edge: .leading)
    }

    func transitionToDestinationCompactView(isEditMode: Bool) -> AnyTransition {
        .asymmetric(
            insertion: isEditMode ? .offset().combined(with: .opacity) : .opacity,
            removal: .opacity
        )
    }

    // MARK: - Amount

    var amountAuxiliaryViewTransition: AnyTransition {
        .move(edge: .bottom)
            .combined(with: .opacity)
            .animation(SendTransitionService.Constants.auxiliaryViewAnimation)
    }

    func transitionToAmountStep(isEditMode: Bool) -> AnyTransition {
        // HACK: I don't know why but in the staking flow
        // when amountContentOffset.y == 0 animation doesn't work
        let offset = max(-amountContentOffset.y, 1)
        return isEditMode ? .offset(y: offset) : .move(edge: .trailing)
    }

    func transitionToAmountCompactView(isEditMode: Bool) -> AnyTransition {
        .asymmetric(
            insertion: isEditMode ? .offset().combined(with: .opacity) : .opacity,
            removal: .opacity
        )
    }

    // MARK: - Validators

    func transitionToValidatorsStep() -> AnyTransition {
        .offset(y: -validatorsContentOffset.y)
    }

    func transitionToValidatorsCompactView(isEditMode: Bool) -> AnyTransition {
        let offset = -selectedValidatorContentOffset.y + validatorsContentOffset.y
        return .asymmetric(
            insertion: isEditMode ? .offset(y: offset) : .opacity,
            removal: .opacity
        )
    }

    // MARK: - Fee

    var feeAuxiliaryViewTransition: AnyTransition {
        .move(edge: .bottom)
            .combined(with: .opacity)
            .animation(SendTransitionService.Constants.auxiliaryViewAnimation)
    }

    var customFeeTransition: AnyTransition {
        .opacity
            .animation(SendTransitionService.Constants.auxiliaryViewAnimation)
    }

    func transitionToFeeStep() -> AnyTransition {
        .offset(y: -feeContentOffset.y)
    }

    func transitionToFeeCompactView(isEditMode: Bool) -> AnyTransition {
        let offset: CGFloat = -selectedFeeContentOffset.y + feeContentOffset.y
        return .asymmetric(
            insertion: .offset(y: offset),
            removal: .opacity
        )
    }

    // MARK: - Summary

    var summaryViewTransition: AnyTransition {
        .asymmetric(insertion: .opacity, removal: .opacity)
    }
}

extension SendTransitionService {
    enum Constants {
        static let animationDuration: TimeInterval = 0.3
        static let defaultAnimation: Animation = .easeIn(duration: animationDuration)

        // Just x2 faster
        static let auxiliaryViewAnimation: Animation = defaultAnimation.speed(2)
    }
}
