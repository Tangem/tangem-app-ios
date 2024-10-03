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

    private var namespace: Namespace.ID?
    private var containerNamespaceId: String?
    private var iconNamespaceId: String?
    private var titleNamespaceId: String?
    private var textNamespaceId: String?
    private var clearButtonNamespaceId: String?

    private let inputFieldFont = Fonts.Regular.subheadline
    private let inputFieldUIFont = UIFonts.Regular.subheadline

    private let inputFieldColor = Colors.Text.primary1
    private let inputFieldUIColor = UIColor.textPrimary1

    @StateObject private var placeholderHeightModel: AddressTextViewHeightModel = .init()

    init(viewModel: SendDestinationTextViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.showAddressIcon {
                VStack(alignment: .leading, spacing: 2) {
                    fieldName

                    ZStack(alignment: .trailing) {
                        HStack(spacing: 12) {
                            addressIconView
                                .padding(.vertical, 10)

                            input
                        }

                        if viewModel.shouldShowPasteButton {
                            pasteButton
                        }

                        pasteButton
                            .opacity(0)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 2)
            } else {
                ZStack(alignment: .trailing) {
                    VStack(alignment: .leading, spacing: 2) {
                        fieldName
                        input
                    }

                    if viewModel.shouldShowPasteButton {
                        pasteButton
                    }

                    pasteButton
                        .opacity(0)
                }
                .padding(.vertical, 12)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var fieldName: some View {
        if let errorText = viewModel.errorText {
            Text(errorText)
                .style(Fonts.Regular.footnote, color: Colors.Text.warning)
                .lineLimit(1)
        } else {
            Text(viewModel.name)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .matchedGeometryEffectOptional(id: titleNamespaceId, in: namespace)
        }
    }

    private var addressIconView: some View {
        Group {
            if viewModel.isValidating {
                Circle()
                    .foregroundColor(Colors.Button.secondary)
                    .overlay(
                        ActivityIndicatorView(style: .medium, color: .iconInformative)
                    )
            } else {
                AddressIconView(viewModel: AddressIconViewModel(address: viewModel.text))
            }
        }
        .matchedGeometryEffectOptional(id: iconNamespaceId, in: namespace)
        .frame(size: CGSize(bothDimensions: 36))
    }

    private var input: some View {
        ZStack {
            // Hidden views to ensure the layout stays the same way
            Group {
                clearIcon

                if viewModel.allowMultilineText {
                    AddressTextView(heightModel: placeholderHeightModel, text: .constant("Two\nLines"), placeholder: "Placeholder", font: inputFieldUIFont, color: inputFieldUIColor)
                } else {
                    TextField("", text: .constant("One Line"))
                        .style(inputFieldFont, color: .black)
                }
            }
            .opacity(0)

            HStack(spacing: 12) {
                Group {
                    if viewModel.allowMultilineText {
                        AddressTextView(
                            heightModel: viewModel.addressTextViewHeightModel,
                            text: $viewModel.text,
                            placeholder: viewModel.placeholder,
                            font: inputFieldUIFont,
                            color: inputFieldUIColor
                        )
                    } else {
                        TextField(viewModel.placeholder, text: $viewModel.text)
                            .style(inputFieldFont, color: inputFieldColor)
                    }
                }
                .disabled(viewModel.isDisabled)
                .autocapitalization(.none)
                .keyboardType(.asciiCapable)
                .disableAutocorrection(true)
                .matchedGeometryEffectOptional(id: textNamespaceId, in: namespace)

                Button(action: viewModel.clearInput) {
                    clearIcon
                        .matchedGeometryEffectOptional(id: clearButtonNamespaceId, in: namespace)
                }
                .hidden(viewModel.text.isEmpty)
                .disabled(viewModel.text.isEmpty)
            }
        }
    }

    private var clearIcon: some View {
        Assets.clear.image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
    }

    @ViewBuilder
    private var pasteButton: some View {
        if #available(iOS 16.0, *) {
            PasteButton(payloadType: String.self) { strings in
                guard let string = strings.first else { return }

                // We receive the value on the non-GUI thread
                DispatchQueue.main.async {
                    viewModel.didTapPasteButton(string)
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

extension SendDestinationTextView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }

    func setContainerNamespaceId(_ containerNamespaceId: String) -> Self {
        map { $0.containerNamespaceId = containerNamespaceId }
    }

    func setIconNamespaceId(_ iconNamespaceId: String) -> Self {
        map { $0.iconNamespaceId = iconNamespaceId }
    }

    func setTitleNamespaceId(_ titleNamespaceId: String) -> Self {
        map { $0.titleNamespaceId = titleNamespaceId }
    }

    func setTextNamespaceId(_ textNamespaceId: String) -> Self {
        map { $0.textNamespaceId = textNamespaceId }
    }

    func setClearButtonNamespaceId(_ clearButtonNamespaceId: String) -> Self {
        map { $0.clearButtonNamespaceId = clearButtonNamespaceId }
    }
}

#Preview("Different cases") {
    GroupedScrollView(spacing: 14) {
        GroupedSection(SendDestinationTextViewModel(style: .address, input: .just(output: ""), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
            SendDestinationTextView(viewModel: $0)
        }

        GroupedSection(SendDestinationTextViewModel(style: .address, input: .just(output: "0x391316d97a07027a0702c8A002c8A0C25d8470"), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
            SendDestinationTextView(viewModel: $0)
        }

        GroupedSection(SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: ""), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
            SendDestinationTextView(viewModel: $0)
        }

        GroupedSection(SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: "123456789"), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
            SendDestinationTextView(viewModel: $0)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}

#Preview("Alignment") {
    GroupedScrollView(spacing: 14) {
        // MARK: address alignment test

        Text("There are two **ADDRESS** fields and they must be aligned 👇")
            .foregroundColor(.blue)
            .font(.caption)

        // To make sure everything's aligned and doesn't jump when entering stuff
        ZStack {
            GroupedSection(SendDestinationTextViewModel(style: .address, input: .just(output: ""), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
                SendDestinationTextView(viewModel: $0)
                    .opacity(0.5)
            }

            GroupedSection(SendDestinationTextViewModel(style: .address, input: .just(output: "0x391316d97a07027a0702c8A002c8A0C25d8470"), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
                SendDestinationTextView(viewModel: $0)
                    .opacity(0.5)
            }
        }

        // MARK: memo alignment test

        Text("There are two **MEMO** fields and they must be aligned 👇")
            .foregroundColor(.blue)
            .font(.caption)

        // To make sure everything's aligned and doesn't jump when entering stuff
        ZStack {
            GroupedSection(SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: ""), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
                SendDestinationTextView(viewModel: $0)
                    .opacity(0.5)
            }

            GroupedSection(SendDestinationTextViewModel(style: .additionalField(name: "Memo"), input: .just(output: "Optional"), isValidating: .just(output: false), isDisabled: .just(output: false), addressTextViewHeightModel: .init(), errorText: .just(output: nil), didEnterDestination: { _ in }, didPasteDestination: { _ in })) {
                SendDestinationTextView(viewModel: $0)
                    .opacity(0.5)
            }
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
