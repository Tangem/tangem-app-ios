//
//  SelectableGropedSection.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SelectableView: View {
    associatedtype SelectionValue

    func isSelected(_ isSelected: Binding<SelectionValue>) -> Self
}

struct SelectableGropedSection<Model: Identifiable, Content: SelectableView, Footer: View, Header: View>: View {
    private let models: [Model]
    private var selection: Binding<Content.SelectionValue>
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    // Use "Colors.Background.primary" as default with "Colors.Background.secondary" background
    // Use "Colors.Background.action" on sheets with "Colors.Background.teritary" background
    private var backgroundColor: Color = Colors.Background.primary

    init(
        _ models: [Model],
        selection: Binding<Content.SelectionValue>,
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.models = models
        self.selection = selection
        self.content = content
        self.header = header
        self.footer = footer
    }

    var body: some View {
        GroupedSection(
            models,
            content: { model in
                content(model)
                    .isSelected(selection)
            },
            header: header,
            footer: footer
        )
    }
}

extension SelectableGropedSection: Setupable {
    func backgroundColor(_ color: Color) -> Self {
        map { $0.backgroundColor = color }
    }
}
