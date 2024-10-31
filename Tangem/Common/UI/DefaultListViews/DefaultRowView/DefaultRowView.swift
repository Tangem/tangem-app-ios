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
        if let action = viewModel.action {
            Button(action: action) {
                content
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack {
            titleView

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

    private var titleView: some View {
        HStack(spacing: 0) {
            Text(viewModel.title)
                .style(appearance.font, color: appearance.textColor)

            if let secondaryAction = viewModel.secondaryAction {
                Button(action: secondaryAction) {
                    Assets.infoCircle16.image
                        .padding(.horizontal, 4)
                        .foregroundColor(Colors.Icon.informative)
                }
            }
        }
    }

    @ViewBuilder
    private var detailsView: some View {
        switch viewModel.detailsType {
        case .none:
            EmptyView()
        case .loader:
            ActivityIndicatorView(style: .medium, color: .gray)
        case .text(let string, let sensitive):
            if sensitive {
                SensitiveText(string)
                    .style(appearance.font, color: appearance.detailsColor)
            } else {
                Text(string)
                    .style(appearance.font, color: appearance.detailsColor)
            }
        case .loadable(let state):
            LoadableTextView(
                state: state,
                font: appearance.font,
                textColor: appearance.detailsColor,
                loaderSize: CGSize(width: 60, height: 14)
            )
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
            font: Font = Fonts.Regular.callout,
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
    static var previews: some View {
        ZStack {
            Colors.Background.secondary.ignoresSafeArea()

            GroupedSection(
                [
                    DefaultRowViewModel(
                        title: "App settings",
                        detailsType: .text("A Long long long long long long long text"),
                        action: nil
                    ),
                    DefaultRowViewModel(
                        title: "App settings",
                        detailsType: .loadable(state: .loading),
                        action: nil
                    ),
                    DefaultRowViewModel(
                        title: "App settings",
                        detailsType: .loader,
                        action: nil
                    ),
                ]
            ) {
                DefaultRowView(viewModel: $0)
            }
            .padding()
        }
    }
}
