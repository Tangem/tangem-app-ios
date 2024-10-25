//
//  CardImageResult.swift
//  Tangem
//
//  Created by Andrew Son on 14/12/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import class UIKit.UIImage
import struct SwiftUI.Image

enum CardImageResult {
    case cached(UIImage)
    case downloaded(UIImage)
    case embedded(UIImage)

    var uiImage: UIImage {
        switch self {
        case .cached(let image), .downloaded(let image), .embedded(let image):
            return image
        }
    }

    var image: Image {
        Image(uiImage: uiImage)
    }
}
