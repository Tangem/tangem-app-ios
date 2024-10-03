//
//  BiometryLogoImage.swift
//  Tangem
//
//  Created by Andrey Chukavin on 25.08.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BiometryLogoImage {
    static var image: ImageType {
        switch BiometricAuthorizationUtils.biometryType {
        case .faceID:
            return Assets.Biometry.faceId
        case .touchID:
            return Assets.Biometry.touchId
        case .opticID:
            return ImageType(name: "opticid") // Built-in from SF Symbols
        case .none:
            return ImageType(name: "")
        @unknown default:
            return ImageType(name: "")
        }
    }
}
