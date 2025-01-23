//
//  SegmentPickerView.swift
//  Tangem
//
//  Created by skibinalexander on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

/*
 https://github.com/Inxel/CustomizableSegmentedControl
 */
public struct SegmentedPickerView<Option: Hashable & Identifiable, SelectionView: View, SegmentContent: View>: View {
    // MARK: - Properties

    @Environment(\.segmentedControlInsets) var segmentedControlInsets
    @Environment(\.segmentedControlInterSegmentSpacing) var interSegmentSpacing
    @Environment(\.segmentedControlSlidingAnimation) var slidingAnimation
    @Environment(\.segmentedControlContentStyle) var contentStyle

    @Binding private var selection: Option
    private let options: [Option]
    private let selectionView: () -> SelectionView
    private let segmentContent: (Option, Bool) -> SegmentContent
    private let shouldStretchToFill: Bool
    private let isDisabled: Bool

    @State private var optionIsPressed: [Option.ID: Bool] = [:]
    @State private var selectedIndex: Int
    @State private var targetWidth: CGFloat?

    @Namespace private var namespaceID
    private let buttonBackgroundID: String = "buttonOverlayID"

    // MARK: - Init

    /// - parameters:
    ///   - selection: Current selection.
    ///   - options: All options in segmented control.
    ///   - insets: Inner insets from container. Default is EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0).
    ///   - interSegmentSpacing: Spacing between options. Default is 0.
    ///   - contentBlendMode: Blend mode applies to content. Default is difference.
    ///   - firstLevelOverlayBlendMode: Blend mode applies to first level overlay. Default is hue.
    ///   - highestLevelOverlayBlendMode: Blend mode applies to highest level overlay. Default is overlay..
    ///   - selectionView: Selected option background.
    ///   - segmentContent: Content of segment. Returns related option and isPressed parameters.
    public init(
        selection: Binding<Option>,
        options: [Option],
        shouldStretchToFill: Bool,
        isDisabled: Bool,
        selectionView: @escaping () -> SelectionView,
        @ViewBuilder segmentContent: @escaping (Option, Bool) -> SegmentContent
    ) {
        _selection = selection
        self.options = options
        self.selectionView = selectionView
        self.segmentContent = segmentContent
        self.shouldStretchToFill = shouldStretchToFill
        self.isDisabled = isDisabled
        optionIsPressed = Dictionary(uniqueKeysWithValues: options.lazy.map { ($0.id, false) })
        selectedIndex = options.firstIndex(of: selection.wrappedValue) ?? 0
    }

    // MARK: - UI

    public var body: some View {
        if #available(iOS 17, *) {
            content
                .sensoryFeedback(.selection, trigger: selection)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: interSegmentSpacing) {
            ForEach(Array(zip(options.indices, options)), id: \.1.id) { index, option in
                Segment(
                    isPressed: .init(
                        get: { optionIsPressed[option.id, default: false] },
                        set: { optionIsPressed[option.id] = $0 }
                    ),
                    content: segmentContent(option, optionIsPressed[option.id, default: false]),
                    selectionView: selectionView(),
                    isSelected: selection == option,
                    animation: slidingAnimation,
                    shouldStretchToFill: shouldStretchToFill,
                    backgroundID: buttonBackgroundID,
                    namespaceID: namespaceID,
                    targetWidth: targetWidth,
                    action: {
                        if selection == option || isDisabled {
                            return
                        }

                        withAnimation {
                            selection = option
                            selectedIndex = index
                        }

                        if #unavailable(iOS 17) {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        }
                    }
                )
                .zIndex(selection == option ? 0 : 1)
                .background {
                    if index < options.count - 1 {
                        HStack {
                            Spacer()
                            Divider()
                        }
                        .padding(.vertical, 4)
                        .opacity((selectedIndex == index || selectedIndex - 1 == index) ? 0.0 : 1.0)
                    }
                }
                .overlay(content: {
                    // We need this part to properly calculate segment size
                    segmentContent(option, true)
                        .fixedSize(horizontal: true, vertical: true)
                        .opacity(0)
                        .readGeometry(\.size.width) { value in
                            if shouldStretchToFill {
                                return
                            }

                            if value > (targetWidth ?? 0) {
                                withAnimation(nil) {
                                    targetWidth = value
                                }
                            }
                        }
                })
            }
        }
        .padding(segmentedControlInsets)
        .drawingGroup()
    }
}

// MARK: - Segment

private extension SegmentedPickerView {
    struct Segment<SegmentSelectionView: View, Content: View>: View {
        // MARK: - Properties

        @Binding var isPressed: Bool

        let content: Content
        let selectionView: SegmentSelectionView
        let isSelected: Bool
        let animation: Animation
        let shouldStretchToFill: Bool
        let backgroundID: String
        let namespaceID: Namespace.ID
        let targetWidth: CGFloat?
        let action: () -> Void

        // MARK: - UI

        var body: some View {
            Button(action: action) {
                content
                    .frame(maxWidth: shouldStretchToFill ? .infinity : targetWidth)
                    .background {
                        if isSelected {
                            selectionView
                                .zIndex(10)
                                .transition(.offset())
                                .matchedGeometryEffect(id: backgroundID, in: namespaceID)
                        }
                    }
                    .animation(animation, value: isSelected)
            }
            .buttonStyle(SegmentButtonStyle(isPressed: $isPressed))
        }
    }
}

// MARK: - CustomizableSegmentedControl + Custom Inits

public extension SegmentedPickerView {
    /// - parameters:
    ///   - selection: Current selection.
    ///   - options: All options in segmented control.
    ///   - insets: Inner insets from container. Default is EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0).
    ///   - interSegmentSpacing: Spacing between options. Default is 0.
    ///   - contentBlendMode: Blend mode applies to content. Default is difference.
    ///   - firstLevelOverlayBlendMode: Blend mode applies to first level overlay. Default is hue.
    ///   - highestLevelOverlayBlendMode: Blend mode applies to highest level overlay. Default is overlay..
    ///   - selectionView: Selected option background.
    ///   - segmentContent: Content of segment. Returns related option and isPressed parameter.s
    init(
        selection: Binding<Option>,
        options: [Option],
        shouldStretchToFill: Bool,
        isDisabled: Bool,
        selectionView: SelectionView,
        @ViewBuilder segmentContent: @escaping (Option, Bool) -> SegmentContent
    ) {
        self.init(
            selection: selection,
            options: options,
            shouldStretchToFill: shouldStretchToFill,
            isDisabled: isDisabled,
            selectionView: { selectionView },
            segmentContent: segmentContent
        )
    }
}

//// MARK: - SegmentButtonStyle

extension SegmentedPickerView.Segment {
    private struct SegmentButtonStyle: ButtonStyle {
        @Binding var isPressed: Bool

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .contentShape(Rectangle())
                .onChange(of: configuration.isPressed) { newValue in
                    isPressed = newValue
                }
        }
    }
}
