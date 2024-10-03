//
//  SegmentedPickerViewContentStyle.swift
//  Tangem
//
//  Created by skibinalexander on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

/// Style of segment content
public enum SegmentedPickerViewContentStyle {
    /// Default style. You configure color for all states of content.
    case `default`
    /// Blend mode style. You configure colors, but some of them depends on background.
    /// - parameters:
    ///   - contentBlendMode: Blend mode applies to content. Default is difference.
    ///   - firstLevelOverlayBlendMode: Blend mode applies to first level overlay. Default is hue.
    ///   - highestLevelOverlayBlendMode: Blend mode applies to highest level overlay. Default is overlay..
    case blendMode(
        contentBlendMode: BlendMode = .difference,
        firstLevelOverlayBlendMode: BlendMode = .hue,
        highestLevelOverlayBlendMode: BlendMode = .overlay
    )
}
