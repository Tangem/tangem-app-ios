//
//  FixedSpacer.swift
//  Tangem
//
//  Created by Sergey Balashov on 17.01.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A spacer with fixed dimensions.
struct FixedSpacer: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var length: CGFloat? = nil

    var body: some View {
        Spacer(minLength: length)
            .frame(width: width, height: height)
    }
}

// MARK: - Convenience extensions

extension FixedSpacer {
    static func horizontal(_ length: CGFloat) -> Self {
        FixedSpacer(width: length, length: length)
    }

    static func vertical(_ length: CGFloat) -> Self {
        FixedSpacer(height: length, length: length)
    }
}
