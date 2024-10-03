//
//  CustomDisclosureGroup.swift
//  Tangem
//
//  Created by skibinalexander on 28.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomDisclosureGroup<Prompt: View, ExpandedView: View>: View {
    private let actionOnClick: () -> Void
    private let animation: Animation?
    private let isExpanded: Bool
    private let prompt: Prompt
    private let expandedView: ExpandedView

    init(
        animation: Animation? = .default,
        isExpanded: Bool,
        actionOnClick: @escaping () -> Void,
        prompt: () -> Prompt,
        expandedView: () -> ExpandedView
    ) {
        self.actionOnClick = actionOnClick
        self.isExpanded = isExpanded
        self.animation = animation
        self.prompt = prompt()
        self.expandedView = expandedView()
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { actionOnClick() }, label: {
                prompt
            })

            if isExpanded {
                expandedView
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .drawingGroup()
    }
}
