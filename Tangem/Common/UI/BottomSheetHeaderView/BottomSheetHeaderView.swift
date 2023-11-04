//
//  BottomSheetHeaderView.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct BottomSheetHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .style(Fonts.Bold.body, color: Colors.Text.primary1)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
    }
}
