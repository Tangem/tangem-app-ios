//
//  SendDestinationAddressSummaryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendDestinationAddressSummaryView: View {
    @ObservedObject var addressTextViewHeightModel: AddressTextViewHeightModel
    let address: String

    private var namespace: Namespace?

    init(addressTextViewHeightModel: AddressTextViewHeightModel, address: String) {
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.address = address
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Localization.sendRecipient)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .matchedGeometryEffect(namespace.map { .init(id: $0.names.addressTitle, namespace: $0.id) })

            HStack(spacing: 12) {
                AddressIconView(viewModel: AddressIconViewModel(address: address))
                    .matchedGeometryEffect(namespace.map { .init(id: $0.names.addressIcon, namespace: $0.id) })
                    .frame(size: CGSize(bothDimensions: 36))
                    .padding(.vertical, 10)

                AddressTextView(
                    heightModel: addressTextViewHeightModel,
                    text: .constant(address),
                    placeholder: "",
                    font: UIFonts.Regular.subheadline,
                    color: .textPrimary1
                )
                .disabled(true)
                .matchedGeometryEffect(namespace.map { .init(id: $0.names.addressText, namespace: $0.id) })

                Assets.clear.image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
                    .opacity(0)
                    .matchedGeometryEffect(namespace.map { .init(id: $0.names.addressClearButton, namespace: $0.id) })
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
    }
}

extension SendDestinationAddressSummaryView: Setupable {
    func namespace(_ namespace: Namespace) -> Self {
        map { $0.namespace = namespace }
    }
}

extension SendDestinationAddressSummaryView {
    struct Namespace {
        let id: SwiftUI.Namespace.ID
        let names: any SendDestinationViewGeometryEffectNames
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(SendDestinationSummaryViewType.address(address: "1230123", corners: .allCorners)) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }

        GroupedSection(SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", corners: .allCorners)) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }

        GroupedSection(
            [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470", corners: [.topLeft, .topRight]),
                SendDestinationSummaryViewType.additionalField(type: .memo, value: "123456789"),
            ]
        ) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }
        .backgroundColor(Colors.Button.disabled)

        GroupedSection(
            [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d84700x391316d97a07027a0702c8A002c8A0C25d8470", corners: [.topLeft, .topRight]),
                SendDestinationSummaryViewType.additionalField(type: .destinationTag, value: "123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789123456789"),
            ]
        ) { type in
            switch type {
            case .address(let address, _):
                SendDestinationAddressSummaryView(addressTextViewHeightModel: .init(), address: address)
            case .additionalField(let type, let value):
                DefaultTextWithTitleRowView(data: .init(title: type.name, text: value))
            }
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
