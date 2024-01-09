//
//  SendCurrencyPicker.swift
//  Tangem
//
//  Created by Andrey Chukavin on 18.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher

struct SendCurrencyPicker: View {
    let cryptoIconURL: URL
    let cryptoCurrencyCode: String

    let fiatIconURL: URL
    let fiatCurrencyCode: String

    @Binding var useFiatCalculation: Bool

    private let iconSize: CGFloat = 18

    private static var defaultLowContrastBackgroundColor: UIColor {
        UIColor.backgroundPrimary.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    // Can't use buttons because that interferes with the drag gesture
    var body: some View {
        HStack(spacing: 0) {
            selectorItem(with: cryptoCurrencyCode, url: cryptoIconURL, iconRadius: 6, selected: !useFiatCalculation)

            selectorItem(with: fiatCurrencyCode, url: fiatIconURL, iconRadius: iconSize / 2, selected: useFiatCalculation)
        }
        .overlay(
            GeometryReader { reader in
                HStack(spacing: 0) {
                    selectorItemHitBox(fiatItem: false)
                    selectorItemHitBox(fiatItem: true)
                }
                .gesture(handleDragGesture(containerSize: reader.size))
            }
        )
        .background(
            GeometryReader { reader in
                handle(containerSize: reader.size)
            }
        )
        .padding(2)
        .background(Colors.Button.secondary)
        .cornerRadiusContinuous(14)
    }

    private func selectorItem(with name: String, url: URL, iconRadius: CGFloat, selected: Bool) -> some View {
        ZStack {
            HStack(spacing: 6) {
                KFImage(url)
                    .appendProcessor(ContrastBackgroundImageProcessor(backgroundColor: Self.defaultLowContrastBackgroundColor))
                    .cancelOnDisappear(true)
                    .cacheOriginalImage()
                    .resizable()
                    .frame(size: CGSize(bothDimensions: iconSize))
                    .cornerRadiusContinuous(iconRadius)

                Text(name)
                    .style(selected ? Fonts.Bold.footnote : Fonts.Regular.footnote, color: Colors.Text.primary1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
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
            .shadow(color: .black.opacity(0.04), radius: 0.5, y: 3)
            .shadow(color: .black.opacity(0.12), radius: 4, y: 3)
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

struct PickerExample: View {
    @State private var currency = 0
    @State private var useFiatCalculation = false

    var body: some View {
        VStack {
            SendCurrencyPicker(
                cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/solana.png")!,
                cryptoCurrencyCode: "SOL",
                fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                fiatCurrencyCode: "USD",
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
                cryptoIconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/coins/large/tether.png")!,
                cryptoCurrencyCode: "USDT",
                fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
                fiatCurrencyCode: "USD",
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
