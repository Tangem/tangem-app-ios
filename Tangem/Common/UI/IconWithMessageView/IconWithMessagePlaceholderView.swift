//
//  IconWithMessagePlaceholderView.swift
//  Tangem
//
//  Created by Andrew Son on 02/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct IconWithMessagePlaceholderView: View {
    private let icon: ImageType

    init(icon: ImageType) {
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 14) {
            IconWithBackground(icon: icon)

            VStack(alignment: .leading) {
                Color.white
                    .skeletonable(isShown: true, size: .init(width: 40, height: 11), radius: 3)

                Color.white
                    .skeletonable(isShown: true, size: .init(width: 102, height: 21), radius: 6)
            }

            Spacer()
        }
    }
}

struct IconWithMessagePlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        IconWithMessagePlaceholderView(icon: Assets.cryptoCurrencies)
    }
}
