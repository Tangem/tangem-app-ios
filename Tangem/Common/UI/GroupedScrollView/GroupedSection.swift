//
//  GroupedSection.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct GroupedSection<Model: Identifiable, Content: View, Footer: View, Header: View>: View {
    private let models: [Model]
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    private var verticalPadding: CGFloat = 12
    private var horizontalPadding: CGFloat = 16
    private var separatorPadding: CGFloat = 16
    private var separatorStyle: SeparatorStyle = .single
    private var interItemSpacing: CGFloat = 0
    private var interSectionPadding: CGFloat = 0
    private var backgroundColor: Color = Colors.Background.primary
    private var contentAlignment: HorizontalAlignment = .leading

    init(
        _ models: [Model],
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.models = models
        self.content = content
        self.header = header
        self.footer = footer
    }

    init(
        _ model: Model?,
        @ViewBuilder content: @escaping (Model) -> Content,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.init(
            model == nil ? [] : [model!],
            content: content,
            header: header,
            footer: footer
        )
    }

    var body: some View {
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                header()
                    .padding(.horizontal, horizontalPadding)

                VStack(alignment: contentAlignment, spacing: interItemSpacing) {
                    ForEach(models) { model in
                        content(model)
                            .padding(.horizontal, horizontalPadding)

                        if models.last?.id != model.id {
                            separator
                        }
                    }
                }
                .padding(.vertical, interSectionPadding)
                .background(backgroundColor)
                .cornerRadius(12)

                footer()
                    .padding(.horizontal, horizontalPadding)
            }
            .padding(.vertical, verticalPadding)
        }
    }

    @ViewBuilder private var separator: some View {
        switch separatorStyle {
        case .none:
            EmptyView()
        case .single:
            Colors.Stroke.primary
                .frame(maxWidth: .infinity)
                .frame(height: 1)
                .padding(.leading, separatorPadding)
        case .minimum:
            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.leading, separatorPadding)
        }
    }
}

extension GroupedSection {
    enum SeparatorStyle: Int, Hashable {
        case none
        case single
        case minimum
    }
}

extension GroupedSection: Setupable {
    func verticalPadding(_ padding: CGFloat) -> Self {
        map { $0.verticalPadding = padding }
    }

    func horizontalPadding(_ padding: CGFloat) -> Self {
        map { $0.horizontalPadding = padding }
    }

    func separatorPadding(_ padding: CGFloat) -> Self {
        map { $0.separatorPadding = padding }
    }

    func separatorStyle(_ style: SeparatorStyle) -> Self {
        map { $0.separatorStyle = style }
    }

    func interItemSpacing(_ spacing: CGFloat) -> Self {
        map { $0.interItemSpacing = spacing }
    }

    func interSectionPadding(_ spacing: CGFloat) -> Self {
        map { $0.interSectionPadding = spacing }
    }

    func backgroundColor(_ color: Color) -> Self {
        map { $0.backgroundColor = color }
    }

    func contentAlignment(_ alignment: HorizontalAlignment) -> Self {
        map { $0.contentAlignment = alignment }
    }
}
