//
//  VisaUtilities+FeatureStorage.swift
//  Tangem
//
//  Created by Andrew Son on 17/06/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemVisa

extension VisaUtilities {
    init() {
        self = VisaUtilities(isTestnet: FeatureStorage.instance.isVisaTestnet)
    }
}
