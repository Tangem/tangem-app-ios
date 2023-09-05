//
//  CheckIconView.swift
//  Tangem
//
//  Created by Sergey Balashov on 30.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct CheckIconView: View {
    let isSelected: Bool

    var body: some View {
        Assets.check.image
            .resizable()
            .foregroundColor(Colors.Icon.accent)
            /// Need to cover empty place if unchecking
            .opacity(isSelected ? 1 : 0)
            .frame(width: 20, height: 20)
    }
}

struct CheckIconView_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            CheckIconView(isSelected: true)

            CheckIconView(isSelected: false)
        }
        .background(Color.white)
    }
}
