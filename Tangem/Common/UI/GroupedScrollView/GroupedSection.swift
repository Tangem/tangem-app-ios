//
//  GroupedSection.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

/**
 Layout:
 `Background`
    `- innerContentPadding`
        `Header`
        `- interItemSpacing`
        `Content 1`
        `- interItemSpacing`
        `Content 2`
    `- innerContentPadding`
 `Background`
 `- footerSpacing`
 `Footer`
 */
struct GroupedSection<Model: Identifiable, Content: View, Footer: View, Header: View>: View {
    private let models: [Model]
    private let content: (Model) -> Content
    private let header: () -> Header
    private let footer: () -> Footer

    private var horizontalPadding: CGFloat = GroupedSectionConstants.defaultHorizontalPadding
    private var separatorStyle: SeparatorStyle = .minimum
    private var interItemSpacing: CGFloat = 0
    private var innerContentPadding: CGFloat = 0

    // Use "Colors.Background.primary" as default with "Colors.Background.secondary" background
    // Use "Colors.Background.action" on sheets with "Colors.Background.teritary" background
    private var backgroundColor: Color = Colors.Background.primary
    private var contentAlignment: HorizontalAlignment = .leading
    private var innerHeaderPadding: CGFloat = GroupedSectionConstants.headerSpacing
    private var geometryEffect: GeometryEffect?

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
        models = model.map { [$0] } ?? []
        self.content = content
        self.header = header
        self.footer = footer
    }

    var body: some View {
        if !models.isEmpty {
            VStack(alignment: .leading, spacing: GroupedSectionConstants.footerSpacing) {
                VStack(alignment: contentAlignment, spacing: interItemSpacing) {
                    header()
                        .padding(.horizontal, horizontalPadding)

                    ForEach(models) { model in
                        content(model)
                            .padding(.horizontal, horizontalPadding)

                        if models.last?.id != model.id {
                            separator
                        }
                    }
                }
                .padding(.vertical, innerContentPadding)
                .background(
                    backgroundColor
                        .modifier(ifLet: geometryEffect) {
                            $0.matchedGeometryEffect(id: $1.id, in: $1.namespace, isSource: $1.isSource)
                        }
                )
                .cornerRadiusContinuous(GroupedSectionConstants.defaultCornerRadius)

                footer()
                    .padding(.horizontal, horizontalPadding)
            }
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
                .padding(.leading, horizontalPadding)
        case .minimum:
            Separator(height: .minimal, color: Colors.Stroke.primary)
                .padding(.leading, horizontalPadding)
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

enum GroupedSectionConstants {
    static let defaultHorizontalPadding: CGFloat = 14
    static let defaultCornerRadius: CGFloat = 14
    static let headerSpacing: CGFloat = 12
    static let footerSpacing: CGFloat = 8
}

extension GroupedSection: Setupable {
    func horizontalPadding(_ padding: CGFloat) -> Self {
        map { $0.horizontalPadding = padding }
    }

    func separatorStyle(_ style: SeparatorStyle) -> Self {
        map { $0.separatorStyle = style }
    }

    func interItemSpacing(_ spacing: CGFloat) -> Self {
        map { $0.interItemSpacing = spacing }
    }

    func innerContentPadding(_ padding: CGFloat) -> Self {
        map { $0.innerContentPadding = padding }
    }

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
