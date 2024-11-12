//
//  OnrampCountryDetectionRoutable.swift
//  TangemApp
//
//  Created by Sergey Balashov on 18.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

protocol OnrampCountryDetectionRoutable: AnyObject {
    func openChangeCountry()
    func dismissConfirmCountryView()
    func dismiss()
}
