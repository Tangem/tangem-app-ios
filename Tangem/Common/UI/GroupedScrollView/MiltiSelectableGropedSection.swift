//
//  MiltiSelectableGropedSection.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct MiltiSelectableGropedSection<Model: Identifiable, Content: MultiSelectableView, Footer: View, Header: View>: View {
    private let models: [Model]
    private var selection: Binding<[Content.SelectionValue]>
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    // Use "Colors.Background.primary" as default with "Colors.Background.secondary" background
    // Use "Colors.Background.action" on sheets with "Colors.Background.teritary" background
    private var backgroundColor: Color = Colors.Background.primary
    private var contentAlignment: HorizontalAlignment = .leading
    private var innerHeaderPadding: CGFloat = GroupedSectionConstants.headerSpacing
    private var geometryEffect: GeometryEffect?

    init(
        _ models: [Model],
        selection: Binding<[Content.SelectionValue]>,
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

extension MiltiSelectableGropedSection: Setupable {
    func innerHeaderPadding(_ padding: CGFloat) -> Self {
        map { $0.innerHeaderPadding = padding }
    }

    func backgroundColor(_ color: Color) -> Self {
        map { $0.backgroundColor = color }
    }

    func geometryEffect(_ geometryEffect: GeometryEffect?) -> Self {
        map { $0.geometryEffect = geometryEffect }
    }

    func contentAlignment(_ alignment: HorizontalAlignment) -> Self {
        map { $0.contentAlignment = alignment }
    }
}

protocol MultiSelectableView: View, Setupable {
    associatedtype SelectionValue: Equatable
    var selectionId: SelectionValue { get }
    var isSelected: Binding<[SelectionValue]>? { get set }

    func isSelected(_ isSelected: Binding<[SelectionValue]>) -> Self
}

extension MultiSelectableView {
    func isSelected(_ isSelected: Binding<[SelectionValue]>) -> Self {
        map { $0.isSelected = isSelected }
    }

    var isSelectedProxy: Binding<Bool> {
        .init(
            get: { isSelected?.wrappedValue.contains(selectionId) ?? false },
            set: { _ in isSelected?.wrappedValue.append(selectionId) }
        )
    }
}
