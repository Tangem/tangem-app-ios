//
//  DateComponentsFormatter.swift
//  TangemApp
//
//  Created by Sergey Balashov on 03.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public extension DateComponentsFormatter {
    static func stakingFormatter() -> DateComponentsFormatter {
        formatter(unitsStyle: .short, allowedUnits: [.second, .day])
    }

    static func formatter(
        unitsStyle: DateComponentsFormatter.UnitsStyle,
        allowedUnits: NSCalendar.Unit
    ) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = unitsStyle
        formatter.allowedUnits = allowedUnits
        return formatter
    }
}
