//
//  CustomDisclosureGroup.swift
//  Tangem
//
//  Created by skibinalexander on 28.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct CustomDisclosureGroup<Prompt: View, ExpandedView: View>: View {
    @Binding var isExpanded: Bool

    var actionOnClick: () -> Void
    var animation: Animation?

    let prompt: Prompt
    let expandedView: ExpandedView

    init(animation: Animation?, isExpanded: Binding<Bool>, actionOnClick: @escaping () -> Void, prompt: () -> Prompt, expandedView: () -> ExpandedView) {
        self.actionOnClick = actionOnClick
        _isExpanded = isExpanded
        self.animation = animation
        self.prompt = prompt()
        self.expandedView = expandedView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            prompt

            if isExpanded {
                expandedView
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(animation) {
                actionOnClick()
            }
        }
    }
}
