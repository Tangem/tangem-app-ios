//
//  DefaultRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultRowView: View {
    @ObservedObject private var viewModel: DefaultRowViewModel
    private var appearance: Appearance = .init()

    init(viewModel: DefaultRowViewModel) {
        self.viewModel = viewModel
    }

    private var isTappable: Bool { viewModel.action != nil }

    var body: some View {
        if isTappable {
            Button {
                viewModel.action?()
            } label: {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack {
            Text(viewModel.title)
                .style(appearance.font, color: appearance.textColor)

            Spacer()

            detailsView

            if isTappable, appearance.isChevronVisible {
                Assets.chevron.image
            }
        }
        .lineLimit(1)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var detailsView: some View {
        switch viewModel.detailsType {
        case .none:
            EmptyView()
        case .loader:
            ActivityIndicatorView(style: .medium, color: .gray)
        case .text(let string):
            Text(string)
                .style(appearance.font, color: appearance.detailsColor)
        case .icon(let imageType):
            imageType.image
        }
    }
}

extension DefaultRowView: Setupable {
    func appearance(_ appearance: Appearance) -> Self {
        map { $0.appearance = appearance }
    }
}

extension DefaultRowView {
    struct Appearance {
        let isChevronVisible: Bool
        let font: Font
        let textColor: Color
        let detailsColor: Color

        static let destructiveButton = Appearance(isChevronVisible: false, textColor: Colors.Text.warning)
        static let accentButton = Appearance(isChevronVisible: false, textColor: Colors.Text.accent)

        init(
            isChevronVisible: Bool = true,
            font: Font = Fonts.Regular.body,
            textColor: Color = Colors.Text.primary1,
            detailsColor: Color = Colors.Text.tertiary
        ) {
            self.isChevronVisible = isChevronVisible
            self.font = font
            self.textColor = textColor
            self.detailsColor = detailsColor
        }
    }
}

struct DefaultRowView_Preview: PreviewProvider {
    static let viewModel = DefaultRowViewModel(
        title: "App settings",
        detailsType: .text("A Long long long long long long long text"),
        action: nil
    )

    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            DefaultRowView(viewModel: viewModel)
                .padding(.horizontal, 16)
        }
    }
}
