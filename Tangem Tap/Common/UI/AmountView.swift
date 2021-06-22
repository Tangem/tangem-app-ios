//
//  AmountView.swift
//  Tangem Tap
//
//  Created by Andrew Son on 16/06/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AmountView: View {
    
    let label: LocalizedStringKey
    let labelColor: Color
    var labelFont: Font = .system(size: 14.0, weight: .medium, design: .default)
    
    var isLoading: Bool = false
    
    let amountText: String
    var amountColor: Color? = nil
    var amountFont: Font? = nil
    var amountScaleFactor: CGFloat? = nil
    var amountLineLimit: Int? = nil
    
    var body: some View {
        HStack{
            Text(label)
                .font(labelFont)
                .foregroundColor(labelColor)
            Spacer()
            if isLoading {
                ActivityIndicatorView(color: UIColor.tangemTapGrayDark)
                    .offset(x: 8)
            } else {
                Text(amountText)
                    .font(amountFont ?? labelFont)
                    .lineLimit(amountLineLimit)
                    .minimumScaleFactor(amountScaleFactor ?? 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(amountColor ?? labelColor)
            }
        }
    }
}

struct AmountView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    static var previews: some View {
        AmountView(label: "Amount",
                   labelColor: .tangemTapGrayDark6,
                   labelFont: .system(size: 14, weight: .regular, design: .default),
                   isLoading: false,
                   amountText: "0 BTC",
                   amountColor: .tangemTapGrayDark6,
                   amountFont: .system(size: 15, weight: .regular, design: .default),
                   amountScaleFactor: 1,
                   amountLineLimit: 1)
    }
}
