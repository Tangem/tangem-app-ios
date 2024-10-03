//
//  DefaultMenuRowView.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct DefaultMenuRowView<Action: DefaultMenuRowViewModelAction>: View {
    private let viewModel: DefaultMenuRowViewModel<Action>
    @Binding private var selection: Action

    init(viewModel: DefaultMenuRowViewModel<Action>, selection: Binding<Action>) {
        self.viewModel = viewModel
        _selection = selection
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(viewModel.title)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            Spacer()

            pickerView
        }
        .padding(.vertical, 12)
    }

    private var pickerView: some View {
        OptionPicker(selection: $selection, options: viewModel.actions) {
            HStack(spacing: 8) {
                Text(selection.title)
                    .style(Fonts.Regular.body, color: Colors.Text.primary1)
                    .animation(.none, value: selection.title)

                Assets.chevronDownMini.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.primary1)
            }
        } content: { action in
            Text(action.title)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
        }
    }
}

struct DefaultMenuRowView_Preview: PreviewProvider {
    struct PreviewView: View {
        @State private var selectedAction: ActionType = .unlimited

        var viewModel: DefaultMenuRowViewModel<ActionType> {
            DefaultMenuRowViewModel(
                title: "Select action",
                actions: ActionType.allCases
            )
        }

        var body: some View {
            DefaultMenuRowView(viewModel: viewModel, selection: $selectedAction)
                .padding(.horizontal, 16)
                .background(Colors.Background.secondary)
        }

        enum ActionType: DefaultMenuRowViewModelAction, CaseIterable {
            case current
            case unlimited

            var id: Int { hashValue }

            var title: String {
                switch self {
                case .current:
                    return "Current transaction"
                case .unlimited:
                    return "Unlimited"
                }
            }
        }
    }

    static var previews: some View {
        PreviewView()
            .preferredColorScheme(.light)

        PreviewView()
            .preferredColorScheme(.dark)
    }
}
