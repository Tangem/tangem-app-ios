//
//  OnrampWebViewRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 07.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol OnrampWebViewRoutable: AnyObject {
    func openURL(url: URL)
}
