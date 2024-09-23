//
//  LockView.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct LockView: View {
    @Namespace private var namespace

    var body: some View {
        VStack(spacing: 0) {
            TangemIconView()
                .matchedGeometryEffect(id: TangemIconView.namespaceId, in: namespace)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Background.primary)
        .edgesIgnoringSafeArea(.all)
    }
}
