//
//  TransactionPlaceholderView.swift
//  Tangem
//
//  Created by Andrew Son on 15/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TransactionViewPlaceholder: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SkeletonView()
                .frame(width: 40, height: 40)
                .cornerRadius(20)

            VStack(alignment: .leading, spacing: 6.5) {
                SkeletonView()
                    .frame(width: 70, height: 12)
                    .cornerRadius(3)

                SkeletonView()
                    .frame(width: 52, height: 12)
                    .cornerRadius(3)
            }

            Spacer()

            SkeletonView()
                .frame(width: 40, height: 12)
                .cornerRadius(3)
        }
    }
}

struct TransactionViewPlaceholder_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TransactionViewPlaceholder()
            TransactionViewPlaceholder()
            TransactionViewPlaceholder()
        }
        .padding(.horizontal, 8)
    }
}
