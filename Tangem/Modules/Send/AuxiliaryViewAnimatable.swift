//
//  AuxiliaryViewAnimatable.swift
//  Tangem
//
//  Created by Andrey Chukavin on 14.02.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol AuxiliaryViewAnimatable: AnyObject {
    var didProperlyDisappear: Bool { get set }
    var animatingAuxiliaryViewsOnAppear: Bool { get set }

    func onAuxiliaryViewAppear()
    func onAuxiliaryViewDisappear()
    func setAnimatingAuxiliaryViewsOnAppear()
}

extension AuxiliaryViewAnimatable {
    func onAuxiliaryViewAppear() {
        didProperlyDisappear = false

        if animatingAuxiliaryViewsOnAppear {
            withAnimation(SendView.Constants.defaultAnimation) {
                animatingAuxiliaryViewsOnAppear = false
            }
        }
    }

    func onAuxiliaryViewDisappear() {
        didProperlyDisappear = true
    }

    func setAnimatingAuxiliaryViewsOnAppear() {
        animatingAuxiliaryViewsOnAppear = didProperlyDisappear
    }
}
