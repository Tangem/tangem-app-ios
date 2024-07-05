//
//  WelcomeViewLifecycleListener.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol WelcomeViewLifecycleListener: AnyObject {
    func resignActve()
    func becomeActive()
}
