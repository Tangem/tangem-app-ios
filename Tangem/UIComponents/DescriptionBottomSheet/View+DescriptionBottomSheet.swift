//
//  View+DescriptionBottomSheet.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func descriptionBottomSheet(
        info: Binding<DescriptionBottomSheetInfo?>,
        sheetHeight: Binding<CGFloat>, backgroundColor: Color?
    ) -> some View {
        if #available(iOS 16, *) {
            sheet(item: info) { info in
                DescriptionBottomSheetView(info: info, sheetHeight: sheetHeight)
                    .adaptivePresentationDetents()
            }
        } else {
            selfSizingDetentBottomSheet(
                item: info,
                detents: [.custom(sheetHeight.wrappedValue)],
                settings: .init(backgroundColor: backgroundColor, contentHeightBinding: sheetHeight)
            ) { info in
                DescriptionBottomSheetView(info: info, sheetHeight: sheetHeight)
            }
        }
    }
}
