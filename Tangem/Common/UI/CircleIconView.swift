//
//  CircleIconView.swift
//  Tangem
//
//  Created by skibinalexander on 27.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CircleIconView: View {
    let image: Image
    var imageSize: CGSize = .init(width: 16, height: 16)
    var circleSize: CGSize = .init(bothDimensions: 46)

    var body: some View {
        image
            .resizable()
            .frame(width: imageSize.width, height: imageSize.height)
            .background(background)
    }

    @ViewBuilder
    private var background: some View {
        Circle()
            .frame(width: circleSize.width, height: circleSize.height)
            .foregroundColor(Colors.Button.secondary)
    }
}

struct CircleIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CircleIconView(image: Assets.plusMini.image)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
