//
//  EmailDataProvider.swift
//  Tangem
//
//  Created by Andrey Chukavin on 13.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol EmailDataProvider {
    var emailData: [EmailCollectedData] { get }
    var emailConfig: EmailConfig? { get }
}
