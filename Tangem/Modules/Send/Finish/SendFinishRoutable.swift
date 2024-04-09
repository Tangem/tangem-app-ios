//
//  SendFinishRoutable.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol SendFinishRoutable: AnyObject {
    func explore(url: URL)
    func share(url: URL)
}
