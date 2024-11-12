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
    private let usesNamespace: Bool
    private var namespace: Namespace.ID?

    init(usesNamespace: Bool) {
        self.usesNamespace = usesNamespace
    }

    var body: some View {
        VStack(spacing: 0) {
            TangemIconView()
                .if(usesNamespace) {
                    $0.matchedGeometryEffectOptional(id: TangemIconView.namespaceId, in: namespace)
                }
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
