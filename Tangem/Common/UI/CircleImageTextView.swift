//
//  CircleImageTextView.swift
//  Tangem
//
//  Created by Alexander Osokin on 04.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct CircleImageTextView: View {
    var name: String
    var color: Color

    let size: CGSize

    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(Colors.Button.secondary)
            Text(String(name.first ?? " "))
                .font(Font.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(Colors.Text.primary2)
        }
        .frame(size: size)
        .clipped()
    }
}

struct TokenImage_Previews: PreviewProvider {
    static var previews: some View {
        CircleImageTextView(name: "Aave (OLD)", color: .gray, size: CGSize(bothDimensions: 40))
    }
}
