//
//  LogFileProvider.swift
//  Tangem
//
//  Created by Alexander Osokin on 25.04.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol LogFileProvider {
    var fileName: String { get }
    var logData: Data? { get }
    func prepareLogFile() -> URL
}
