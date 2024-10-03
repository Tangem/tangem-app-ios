//
//  ScrollView+.swift
//  Tangem
//
//  Created by Andrey Chukavin on 27.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    @ViewBuilder
    func scrollDismissesKeyboardCompat(_ type: ScrollDismissesKeyboardCompatType) -> some View {
        if #available(iOS 16.0, *) {
            switch type {
            case .interactively:
                scrollDismissesKeyboard(.interactively)
            case .immediately:
                scrollDismissesKeyboard(.immediately)
            case .never:
                scrollDismissesKeyboard(.never)
            }
        } else {
            switch type {
            case .interactively, .immediately:
                onTapGesture {
                    UIApplication.shared.endEditing()
                }
            case .never:
                self
            }
        }
    }
}

enum ScrollDismissesKeyboardCompatType {
    case interactively
    case immediately
    case never
}
