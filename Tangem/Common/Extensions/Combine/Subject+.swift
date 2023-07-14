//
//  Subject+.swift
//  Tangem
//
//  Created by Andrey Fedorov on 07.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

extension CurrentValueSubject {
    var asBinding: Binding<Output> {
        return Binding(
            get: { self.value },
            set: { self.send($0) }
        )
    }
}
