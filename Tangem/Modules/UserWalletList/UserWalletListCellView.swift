//
//  UserWalletListCellView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 26.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListCellView: View {
    @ObservedObject private var viewModel: UserWalletListCellViewModel

    init(viewModel: UserWalletListCellViewModel) {
        self.viewModel = viewModel
    }

    private let selectionIconSize: CGSize = .init(width: 14, height: 14)
    private let selectionIconBorderWidth: Double = 2

    var body: some View {
        if #available(iOS 15.0, *) {
            content
                .listRowInsets(EdgeInsets())
                .swipeActions {
                    Button(Localization.commonDelete) { [weak viewModel] in
                        viewModel?.delete()
                    }
                    .tint(.red)

                    Button(Localization.commonRename) { [weak viewModel] in
                        viewModel?.edit()
                    }
                    .tint(Colors.Icon.informative)
                }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            cardImage
                .overlay(selectionIcon.offset(x: 4, y: -4), alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text(viewModel.name)
                        .style(Fonts.Bold.subheadline, color: viewModel.isSelected ? Colors.Text.accent : Colors.Text.primary1)
                        .lineLimit(1)

                    Spacer(minLength: 12)

                    if !viewModel.isUserWalletLocked {
                        Text(viewModel.balance)
                            .style(Font.subheadline, color: Colors.Text.primary1)
                            .lineLimit(1)
                            .layoutPriority(1)
                            .skeletonable(isShown: viewModel.isBalanceLoading, radius: 6)

                        if viewModel.hasError {
                            Assets.attention.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 17, height: 17)
                                .padding(.leading, 2)
                        }
                    }
                }

                HStack(spacing: 0) {
                    Text(viewModel.subtitle)
                        .style(Font.footnote, color: Colors.Text.tertiary)

                    Spacer(minLength: 12)

                    if !viewModel.isUserWalletLocked {
                        Text(viewModel.numberOfTokens ?? "")
                            .style(Font.footnote, color: Colors.Text.tertiary)
                    }
                }
            }

            if viewModel.isUserWalletLocked {
                lockIcon
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 67)
        .contentShape(Rectangle())
        .background(Colors.Background.primary)
        .onTapGesture {
            viewModel.didTapUserWallet()
        }
        .onAppear(perform: viewModel.onAppear)
        .contextMenu {
            Button {
                viewModel.edit()
            } label: {
                HStack {
                    Text(Localization.commonRename)
                    Image(systemName: "pencil")
                }
            }

            if #available(iOS 15, *) {
                Button(role: .destructive) {
                    viewModel.delete()
                } label: {
                    deleteButtonLabel
                }
            } else {
                Button {
                    viewModel.delete()
                } label: {
                    deleteButtonLabel
                }
            }
        }
    }

    @ViewBuilder
    private var cardImage: some View {
        if let image = viewModel.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 50, minHeight: viewModel.imageHeight, maxHeight: viewModel.imageHeight)
        } else {
            Color.tangemGrayLight4
                .transition(.opacity)
                .opacity(0.5)
                .cornerRadius(3)
                .frame(width: 50, height: viewModel.imageHeight)
        }
    }

    @ViewBuilder
    private var selectionIcon: some View {
        if viewModel.isSelected {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: selectionIconSize.width, height: selectionIconSize.height)
                .foregroundColor(Colors.Text.accent)
                .background(
                    Colors.Background.primary
                        .clipShape(Circle())
                        .frame(size: selectionIconSize + CGSize(width: 2 * selectionIconBorderWidth, height: 2 * selectionIconBorderWidth))
                )
        }
    }

    @ViewBuilder
    private var lockIcon: some View {
        Assets.lock.image
            .foregroundColor(Colors.Icon.primary1)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Colors.Background.secondary)
            .cornerRadius(10)
    }

    @ViewBuilder
    private var deleteButtonLabel: some View {
        HStack {
            Text(Localization.commonDelete)
            Image(systemName: "trash")
        }
    }
}
