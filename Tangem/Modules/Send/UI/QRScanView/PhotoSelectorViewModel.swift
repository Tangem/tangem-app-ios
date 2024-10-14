//
//  PhotoSelectorViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

class PhotoSelectorViewModel: Identifiable {
    let didSelectPhoto: (UIImage?) -> Void

    init(didSelectPhoto: @escaping (UIImage?) -> Void) {
        self.didSelectPhoto = didSelectPhoto
    }
}
