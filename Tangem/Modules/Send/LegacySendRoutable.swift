//
//  LegacySendRoutable.swift
//  Tangem
//
//  Created by Alexander Osokin on 17.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol LegacySendRoutable: AnyObject {
    func openMail(with dataCollector: EmailDataCollector, recipient: String)
    func closeModule()
    func openQRScanner(with codeBinding: Binding<String>)
}
