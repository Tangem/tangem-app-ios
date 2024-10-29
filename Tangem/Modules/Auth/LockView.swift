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
    private var namespace: Namespace.ID?

    var body: some View {
        VStack(spacing: 0) {
            TangemIconView()
                .matchedGeometryEffectOptional(id: TangemIconView.namespaceId, in: namespace)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Background.primary)
        .edgesIgnoringSafeArea(.all)
    }
}

// Copy of the view without matchedGeometryEffect
struct LockViewCompat: View {
    var body: some View {
        VStack(spacing: 0) {
            TangemIconView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Background.primary)
        .edgesIgnoringSafeArea(.all)
    }
}

extension LockView: Setupable {
    func setNamespace(_ namespace: Namespace.ID) -> Self {
        map { $0.namespace = namespace }
    }
}
