//
//  ExpressSuccessSentRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 20.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol ExpressSuccessSentRoutable: AnyObject {
    func openWebView(url: URL?, title: String)
    func close()
}
