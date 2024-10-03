//
//  ContinuousCornerRadius.swift
//  Tangem
//
//  Created by Andrey Chukavin on 12.12.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - Convenience extensions

extension View {
    @ViewBuilder
    func cornerRadiusContinuous(_ radius: CGFloat) -> some View {
        modifier(
            ContinuousCornerRadiusViewModifier(radius: radius)
        )
    }

    /// - Note: The `UnevenRoundedRectangle` shape is available on iOS 16+ and Apple's formula for `continuous`
    /// corner radius is notoriously difficult to reproduce properly. Therefore this method has iOS 16+
    /// as a minimum supported version. Consider back-porting `UnevenRoundedRectangle` to lower iOS versions.
    @available(iOS 16.0, *)
    @ViewBuilder
    func cornerRadiusContinuous(
        topLeadingRadius: CGFloat = 0,
        bottomLeadingRadius: CGFloat = 0,
        bottomTrailingRadius: CGFloat = 0,
        topTrailingRadius: CGFloat = 0
    ) -> some View {
        modifier(
            UnevenContinuousCornerRadiusViewModifier(
                topLeadingRadius: topLeadingRadius,
                bottomLeadingRadius: bottomLeadingRadius,
                bottomTrailingRadius: bottomTrailingRadius,
                topTrailingRadius: topTrailingRadius
            )
        )
    }
}

// MARK: - Private implementation

private struct ContinuousCornerRadiusViewModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

@available(iOS 16.0, *)
private struct UnevenContinuousCornerRadiusViewModifier: ViewModifier {
    let topLeadingRadius: CGFloat
    let bottomLeadingRadius: CGFloat
    let bottomTrailingRadius: CGFloat
    let topTrailingRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: topLeadingRadius,
            bottomLeadingRadius: bottomLeadingRadius,
            bottomTrailingRadius: bottomTrailingRadius,
            topTrailingRadius: topTrailingRadius,
            style: .continuous
        )

        content
            .clipShape(shape)
    }
}
