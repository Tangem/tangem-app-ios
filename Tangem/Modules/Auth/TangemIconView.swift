//
//  TangemIconView.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct TangemIconView: View {
    var body: some View {
        Assets.tangemIconBig.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 96, height: 96)
            .foregroundColor(Colors.Text.primary1)
            .padding(.bottom, 48)
    }

    static var namespaceId: String { "TangemIconViewAuth" }
}
