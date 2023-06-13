//
//  View+InfinityFrame.swift
//  Tangem
//
//  Created by m3g0byt3 on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func infinityFrame(alignment: Alignment = .center) -> some View {
        modifier(InfinityFrameViewModifier(alignment: alignment))
    }
}

private struct InfinityFrameViewModifier: ViewModifier {
    var alignment: Alignment

    func body(content: Content) -> some View {
        content
            .frame(
                minWidth: 0.0,
                maxWidth: .infinity,
                minHeight: 0.0,
                maxHeight: .infinity,
                alignment: alignment
            )
    }
}
