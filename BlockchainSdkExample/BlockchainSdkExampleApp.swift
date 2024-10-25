//
//  BlockchainSdkExampleApp.swift
//  BlockchainSdkExample
//
//  Created by Andrey Chukavin on 08.03.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI

@main
struct BlockchainSdkExampleApp: App {
    @StateObject private var model = BlockchainSdkExampleViewModel()

    var body: some Scene {
        WindowGroup {
            BlockchainSdkExampleView()
                .environmentObject(model)
        }
    }
}
