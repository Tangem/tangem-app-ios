//
//  EmailDataProviderMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 07.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class EmailDataProviderMock: EmailDataProvider {
    var emailData: [EmailCollectedData] { [] }
    var emailConfig: EmailConfig? { nil }
}
