//
//  BottomSheetSettings.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 12.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BottomSheetSettings: Identifiable {
    var id: UUID = .init()
    var showClosedButton: Bool = true
    var swipeDownToDismissEnabled: Bool = true
    var tapOutsideToDismissEnabled: Bool = true
    var cornerRadius: CGFloat = 10
    var overlayColor: Color = .init(red: 0, green: 0, blue: 0).opacity(0.7)
    var contentBackgroundColor: Color = .init(red: 1, green: 1, blue: 1)
}

extension BottomSheetSettings {
    static var `default`: BottomSheetSettings {
        BottomSheetSettings()
    }

    static var qr: BottomSheetSettings {
        BottomSheetSettings()
    }

    static var warning: BottomSheetSettings {
        BottomSheetSettings(showClosedButton: false)
    }

    static var swappingPermission: BottomSheetSettings {
        BottomSheetSettings(
            showClosedButton: false,
            swipeDownToDismissEnabled: true,
            contentBackgroundColor: Colors.Background.secondary
        )
    }
}
