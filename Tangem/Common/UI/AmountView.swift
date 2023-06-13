//
//  AmountView.swift
//  Tangem
//
//  Created by Andrew Son on 16/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AmountView: View {
    let label: String
    let labelColor: Color
    var labelFont: Font = .system(size: 14.0, weight: .medium, design: .default)

    var isLoading: Bool = false

    let amountText: String
    var amountColor: Color?
    var amountFont: Font?
    var amountScaleFactor: CGFloat?
    var amountLineLimit: Int?

    var blinkPublisher: Published<Bool>.Publisher?

    @ViewBuilder
    var valueText: some View {
        let mainColor = amountColor ?? labelColor
        let txt = Text(amountText)
            .font(amountFont ?? labelFont)
            .lineLimit(amountLineLimit)
            .minimumScaleFactor(amountScaleFactor ?? 1)
            .fixedSize(horizontal: false, vertical: true)

        if blinkPublisher != nil {
            txt
                .blink(
                    publisher: blinkPublisher!,
                    originalColor: mainColor,
                    color: .red,
                    duration: 0.25
                )
        } else {
            txt
        }
    }

    var body: some View {
        HStack {
            Text(label)
                .font(labelFont)
                .foregroundColor(labelColor)
            Spacer()
            if isLoading {
                ActivityIndicatorView(color: UIColor.tangemGrayDark)
                    .offset(x: 8)
            } else {
                valueText
            }
        }
    }
}

private class Blinker: ObservableObject {
    @Published var blink: Bool = false
}

struct AmountView_Previews: PreviewProvider {
    @ObservedObject fileprivate static var blinker = Blinker()
    static var previews: some View {
        VStack {
            Button("Blink") {
                blinker.blink.toggle()
            }
            AmountView(
                label: "Amount",
                labelColor: .tangemGrayDark6,
                labelFont: .system(size: 14, weight: .regular, design: .default),
                isLoading: false,
                amountText: "0 BTC",
                amountColor: .tangemGrayDark6,
                amountFont: .system(size: 15, weight: .regular, design: .default),
                amountScaleFactor: 1,
                amountLineLimit: 1,
                blinkPublisher: blinker.$blink
            )
        }
    }
}
