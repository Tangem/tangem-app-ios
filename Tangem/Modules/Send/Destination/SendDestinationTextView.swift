//
//  SendDestinationTextView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationTextView: View {
    @ObservedObject var viewModel: SendDestinationTextViewModel

    var body: some View {
        GroupedSection(viewModel) { _ in
            if viewModel.showAddressIcon {
                VStack(alignment: .leading, spacing: 14) {
                    fieldName

                    HStack(spacing: 12) {
                        addressIconView
                        input
                        pasteButton
                    }
                }
                .padding(.vertical, 12)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldName
                        input
                    }

                    pasteButton
                }
                .padding(.vertical, 12)
            }
        } footer: {
            Text(viewModel.description)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
        .horizontalPadding(14)
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var fieldName: some View {
        if let errorText = viewModel.errorText {
            Text(errorText)
                .style(Fonts.Regular.caption1, color: Colors.Text.warning)
                .lineLimit(1)
        } else {
            Text(viewModel.name)
                .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
        }
    }

    private var addressIconView: some View {
        AddressIconView(viewModel: AddressIconViewModel(address: viewModel.input))
            .frame(size: CGSize(bothDimensions: 36))
    }

    private var input: some View {
        HStack {
            TextField(viewModel.placeholder, text: $viewModel.input)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

            if !viewModel.input.isEmpty {
                Button(action: viewModel.clearInput) {
                    Assets.clear.image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.informative)
                }
            }
        }
    }

    @ViewBuilder
    private var pasteButton: some View {
        if viewModel.input.isEmpty {
            if #available(iOS 16.0, *) {
                PasteButton(payloadType: String.self) { strings in
                    guard let string = strings.first else { return }

                    // We receive the value on the non-GUI thread
                    DispatchQueue.main.async {
                        viewModel.didEnterDestination(string)
                    }
                }
                .tint(Color.black)
                .labelStyle(.titleOnly)
                .buttonBorderShape(.capsule)
            } else {
                Button(action: viewModel.didTapLegacyPasteButton) {
                    Text(Localization.commonPaste)
                        .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(viewModel.hasTextInClipboard ? Colors.Button.primary : Colors.Button.disabled)
                        .clipShape(Capsule())
                }
                .disabled(!viewModel.hasTextInClipboard)
            }
        }
    }
}

#Preview {
    GroupedScrollView {
        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .address(networkName: "Ethereum"), input: .just(output: ""), errorText: .just(output: nil), didEnterDestination: { _ in }))

        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .address(networkName: "Ethereum"), input: .just(output: "0x391316d97a07027a0702c8A002c8A0C25d8470"), errorText: .just(output: nil), didEnterDestination: { _ in }))

        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: ""), errorText: .just(output: nil), didEnterDestination: { _ in }))

        SendDestinationTextView(viewModel: SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: "123456789"), errorText: .just(output: nil), didEnterDestination: { _ in }))
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
