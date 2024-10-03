//
//  AlertBinder.swift
//  Tangem
//
//  Created by Andrew Son on 16/04/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ActionSheetBinder: Identifiable {
    let id = UUID()
    let sheet: ActionSheet

    init(sheet: ActionSheet) {
        self.sheet = sheet
    }
}

struct AlertBinder: Identifiable {
    let id = UUID()
    let alert: Alert

    init(alert: Alert) {
        self.alert = alert
    }

    init(title: String, message: String) {
        alert = Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(Localization.commonOk))
        )
    }
}
