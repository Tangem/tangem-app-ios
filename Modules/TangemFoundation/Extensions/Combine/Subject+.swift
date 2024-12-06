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

public extension CurrentValueSubject {
    /// Resend the current `value`
    func resend() {
        send(value)
    }
}

// MARK: - Binding

public extension CurrentValueSubject {
    var asBinding: Binding<Output> {
        return Binding(
            get: { self.value },
            set: { self.send($0) }
        )
    }
}

public extension Subject {
    func asWriteOnlyBinding(_ defaultValue: Output) -> Binding<Output> {
        return Binding(
            get: { defaultValue },
            set: { self.send($0) }
        )
    }
}
