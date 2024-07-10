//
//  SelectableGropedSection.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SelectableView: View, Setupable {
    associatedtype SelectionValue: Equatable

    var selectionId: SelectionValue { get }
    var isSelected: Binding<SelectionValue>? { get set }

    func isSelected(_ isSelected: Binding<SelectionValue>) -> Self
}

extension SelectableView {
    func isSelected(_ isSelected: Binding<SelectionValue>) -> Self {
        map { $0.isSelected = isSelected }
    }

    var isSelectedProxy: Binding<Bool> {
        .init(
            get: { isSelected?.wrappedValue == selectionId },
            set: { _ in isSelected?.wrappedValue = selectionId }
        )
    }
}

struct SelectableGropedSection<Model: Identifiable, Content: SelectableView, Footer: View, Header: View>: View {
    private let models: [Model]
    private var selection: Binding<Content.SelectionValue>
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    private var settings: Settings = .init()

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
        .settings(settings)
    }
}

extension SelectableGropedSection {
    typealias Settings = GroupedSection<Model, Content, Footer, Header>.Settings
}

// MARK: - Setupable

extension SelectableGropedSection: Setupable {
    func settings<V>(_ keyPath: WritableKeyPath<Settings, V>, _ value: V) -> Self {
        map { $0.settings[keyPath: keyPath] = value }
    }
}
