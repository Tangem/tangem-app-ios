//
//  CircleCheckmarkIcon.swift
//  Tangem
//
//  Created by Sergey Balashov on 11.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

struct CircleCheckmarkIcon: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Colors.Control.checked : Colors.Control.unchecked)

            if isSelected {
                Assets.check.image
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Colors.Background.action)
                    .frame(width: 12, height: 12)
            }
        }
        .frame(width: 22, height: 22)
    }
}

#Preview {
    struct ContentView: View {
        @State private var size: CGSize = .zero
        var body: some View {
            ZStack {
                Colors.Background.action

                VStack {
                    CircleCheckmarkIcon(isSelected: true)
                        .readGeometry(\.size, bindTo: $size)

                    CircleCheckmarkIcon(isSelected: false)

                    Text(size.description)
                }
            }
        }
    }

    return ContentView()
}
