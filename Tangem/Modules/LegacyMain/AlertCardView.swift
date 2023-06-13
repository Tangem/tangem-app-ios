//
//  AlertCardView.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.09.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct AlertCardView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !title.isEmpty {
                Text(title)
                    .font(Font.system(size: 14, weight: .bold, design: .default))
                    .padding(.bottom, 8)
            }
            Text(message)
                .font(Font.system(size: 13, weight: .medium, design: .default))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)

            Color.clear.frame(height: 0, alignment: .center)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24.0)
        .padding(.vertical, 16.0)
        .background(Color.tangemGrayDark)
        .cornerRadius(6.0)
    }
}

struct AlertCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            AlertCardView(title: "Warning", message: "Tangem cards manufactured before September 2019 cannot currently be extracted with an iPhone. We're working hard with Apple to make it possible in future versions of iOS.")

            AlertCardView(title: "", message: "Tangem cards manufactured before September 2019 cannot currently be extracted")
        }
    }
}
