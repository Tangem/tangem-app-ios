//
//  SendCurrencyPicker.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendCurrencyPickerData {
    let cryptoIconURL: URL?
    let cryptoCurrencyCode: String

    let fiatIconURL: URL?
    let fiatCurrencyCode: String

    let disabled: Bool
}

struct SendCurrencyPicker: View {
    let data: SendCurrencyPickerData
    @Binding var useFiatCalculation: Bool

    private let iconSize: CGFloat = 18

    // Can't use buttons because that interferes with the drag gesture
    var body: some View {
        HStack(spacing: 0) {
            selectorItem(with: data.cryptoCurrencyCode, url: data.cryptoIconURL, iconRadius: 2, selected: !useFiatCalculation) {
                Colors.Button.secondary
            }

            selectorItem(with: data.fiatCurrencyCode, url: data.fiatIconURL, iconRadius: iconSize / 2, selected: useFiatCalculation) {
                Assets.fiatIconPlaceholder
                    .image
                    .renderingMode(.template)
                    .foregroundColor(Colors.Icon.informative)
            }
        }
        .overlay(
            GeometryReader { reader in
                HStack(spacing: 0) {
                    selectorItemHitBox(fiatItem: false)
                    selectorItemHitBox(fiatItem: true)
                }
                .allowsHitTesting(!data.disabled)
                .gesture(handleDragGesture(containerSize: reader.size))
            }
        )
        .background(
            GeometryReader { reader in
                if data.disabled {
                    handle(containerSize: reader.size)
                } else {
                    handle(containerSize: reader.size)
                        .shadow(color: .black.opacity(0.04), radius: 0.5, y: 3)
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 3)
                }
            }
        )
        .padding(2)
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(14)
    }

    private func selectorItem(with name: String, url: URL?, iconRadius: CGFloat, selected: Bool, @ViewBuilder placeholder: @escaping () -> some View) -> some View {
        ZStack {
            HStack(spacing: 6) {
                IconView(url: url, size: CGSize(bothDimensions: iconSize), cornerRadius: iconRadius, forceKingfisher: true, placeholder: placeholder)
                    .saturation(data.disabled ? 0 : 1)

                ZStack {
                    selectorItemText(with: name, selected: selected)

                    // To make sure that the text doesn't jump when switching between bold/regular fonts
                    selectorItemText(with: name, selected: true)
                        .opacity(0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
    }

    private func selectorItemText(with name: String, selected: Bool) -> some View {
        Text(name)
            .style(
                selected ? Fonts.Bold.footnote : Fonts.Regular.footnote,
                color: data.disabled ? Colors.Text.disabled : Colors.Text.primary1
            )
            .lineLimit(1)
    }

    private func selectorItemHitBox(fiatItem: Bool) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                useFiatCalculation = fiatItem
            }
    }

    private func handle(containerSize: CGSize) -> some View {
        Colors.Background.primary
            .frame(width: containerSize.width * 0.5, height: containerSize.height)
            .cornerRadiusContinuous(12)
            .offset(x: useFiatCalculation ? containerSize.width / 2 : 0)
            .animation(.easeOut(duration: 0.21), value: useFiatCalculation)
    }

    private func handleDragGesture(containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                let swipeDistance = 10.0
                if abs(drag.translation.width) < swipeDistance {
                    return
                }

                if drag.location.x > containerSize.width / 2 {
                    useFiatCalculation = true
                } else {
                    useFiatCalculation = false
                }
            }
    }
}

private struct PickerExample: View {
    @State private var currency = 0
    @State private var useFiatCalculation = false

    var body: some View {
        VStack {
            SendCurrencyPicker(
                data: .init(
                    cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
                    cryptoCurrencyCode: "USDT",
                    fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                    fiatCurrencyCode: "USD",
                    disabled: false
                ),
                useFiatCalculation: $useFiatCalculation
            )

            Picker("Currency", selection: $useFiatCalculation) {
                Text("USDT").tag(false)
                Text("USD").tag(true)
            }
            .pickerStyle(.segmented)

            Button("Toggle") {
                useFiatCalculation.toggle()
            }

            SendCurrencyPicker(
                data: .init(
                    cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
                    cryptoCurrencyCode: "USDT",
                    fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                    fiatCurrencyCode: "USD",
                    disabled: false
                ),
                useFiatCalculation: $useFiatCalculation
            )
            .frame(maxWidth: 227)

            SendCurrencyPicker(
                data: .init(
                    cryptoIconURL: URL(string: "XXX://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
                    cryptoCurrencyCode: "USDT",
                    fiatIconURL: URL(string: "XXX://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                    fiatCurrencyCode: "USD",
                    disabled: false
                ),
                useFiatCalculation: $useFiatCalculation
            )
            .frame(maxWidth: 227)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    PickerExample()
}
