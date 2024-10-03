//
//  CardsInfoPagerSwipeDiscoveryAnimationTrigger.swift
//  Tangem
//
//  Created by Andrey Fedorov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

/// A dedicated entity because we don't want to pollute views with reactive stuff from Combine.
final class CardsInfoPagerSwipeDiscoveryAnimationTrigger: ObservableObject {
    @Published private(set) var trigger = false

    private var triggerSubscription: AnyCancellable?

    init<T>(_ triggerPublisher: some Publisher<T, Never>) {
        triggerSubscription = triggerPublisher
            .withWeakCaptureOf(self)
            .map(\.0)
            .sink { $0.triggerDiscoveryAnimation() }
    }

    func triggerDiscoveryAnimation() {
        trigger.toggle()
    }
}

// MARK: - Convenience extensions

extension CardsInfoPagerSwipeDiscoveryAnimationTrigger {
    /// Constructs a trigger that can be triggered manually.
    convenience init() {
        self.init(Empty<Void, Never>())
    }
}
