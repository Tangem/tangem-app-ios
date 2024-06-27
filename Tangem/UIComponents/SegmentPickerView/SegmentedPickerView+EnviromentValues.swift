//
//  SegmentedPickerView+EnviromentKey.swift
//  Tangem
//
//  Created by skibinalexander on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

private struct SegmentedControlInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

private struct SegmentedControlInterSegmentSpacingKey: EnvironmentKey {
    static var defaultValue: CGFloat = .zero
}

private struct SegmentedControlContentStyleKey: EnvironmentKey {
    static var defaultValue: SegmentedPickerViewContentStyle = .default
}

private struct SegmentedControlSlidingAnimationKey: EnvironmentKey {
    static var defaultValue: Animation = .default
}

extension EnvironmentValues {
    var segmentedControlInsets: EdgeInsets {
        get { self[SegmentedControlInsetsKey.self] }
        set { self[SegmentedControlInsetsKey.self] = newValue }
    }

    var segmentedControlInterSegmentSpacing: CGFloat {
        get { self[SegmentedControlInterSegmentSpacingKey.self] }
        set { self[SegmentedControlInterSegmentSpacingKey.self] = newValue }
    }

    var segmentedControlContentStyle: SegmentedPickerViewContentStyle {
        get { self[SegmentedControlContentStyleKey.self] }
        set { self[SegmentedControlContentStyleKey.self] = newValue }
    }

    var segmentedControlSlidingAnimation: Animation {
        get { self[SegmentedControlSlidingAnimationKey.self] }
        set { self[SegmentedControlSlidingAnimationKey.self] = newValue }
    }
}

public extension SegmentedPickerView {
    func insets(_ insets: EdgeInsets) -> some View {
        environment(\.segmentedControlInsets, insets)
    }

    func insets(top: CGFloat? = nil, leading: CGFloat? = nil, bottom: CGFloat? = nil, trailing: CGFloat? = nil) -> some View {
        environment(\.segmentedControlInsets, .init(
            top: top ?? segmentedControlInsets.top,
            leading: leading ?? segmentedControlInsets.leading,
            bottom: bottom ?? segmentedControlInsets.bottom,
            trailing: trailing ?? segmentedControlInsets.trailing
        ))
    }

    func insets(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        switch edges {
        case .vertical:
            return insets(top: length, bottom: length)
        case .horizontal:
            return insets(leading: length, trailing: length)
        case .top:
            return insets(top: length)
        case .leading:
            return insets(leading: length)
        case .bottom:
            return insets(bottom: length)
        case .trailing:
            return insets(trailing: length)
        case .all:
            return insets(top: length, leading: length, bottom: length, trailing: length)
        default:
            assertionFailure("Unavailable type of edge")
            return insets(
                top: segmentedControlInsets.top,
                leading: segmentedControlInsets.leading,
                bottom: segmentedControlInsets.bottom,
                trailing: segmentedControlInsets.trailing
            )
        }
    }
}

public extension View {
    func segmentedControl(interSegmentSpacing: CGFloat) -> some View {
        environment(\.segmentedControlInterSegmentSpacing, interSegmentSpacing)
    }

    func segmentedControlContentStyle(_ style: SegmentedPickerViewContentStyle) -> some View {
        environment(\.segmentedControlContentStyle, style)
    }

    func segmentedControlSlidingAnimation(_ animation: Animation) -> some View {
        environment(\.segmentedControlSlidingAnimation, animation)
    }
}
