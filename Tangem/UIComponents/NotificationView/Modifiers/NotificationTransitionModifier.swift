//
//  NotificationTransitionModifier.swift
//  Tangem
//
//  Created by Andrew Son on 05/10/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NotificationTransitionModifier: ViewModifier {
    enum Direction: CGFloat {
        case topDown = 1
        case bottomUp = -1
    }

    let verticalScale: CGFloat
    let direction: Direction

    private let verticalMovementOffset: CGFloat = 75

    func body(content: Content) -> some View {
        content.scaleEffect(y: verticalScale, anchor: .top)
            // Adding up movement to slightly hide vertical scaling effect and make it little bit more natural
            .offset(y: (-verticalMovementOffset + verticalMovementOffset * verticalScale) * direction.rawValue)
    }
}

extension AnyTransition {
    static var notificationTransition: AnyTransition {
        AnyTransition.modifier(
            active: NotificationTransitionModifier(verticalScale: 0.6, direction: .topDown),
            identity: NotificationTransitionModifier(verticalScale: 1, direction: .topDown)
        )
        .animation(.easeInOut(duration: 0.3))
        .combined(with: .asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.4)),
            removal: .opacity.animation(.easeOut(duration: 0.3))
        ))
    }

    static var bottomNotificationTransition: AnyTransition {
        AnyTransition.modifier(
            active: NotificationTransitionModifier(verticalScale: 0.6, direction: .bottomUp),
            identity: NotificationTransitionModifier(verticalScale: 1, direction: .bottomUp)
        )
        .animation(.easeInOut(duration: 0.3))
        .combined(with: .asymmetric(
            insertion: .opacity.animation(.easeIn(duration: 0.4)),
            removal: .opacity.animation(.easeOut(duration: 0.3))
        ))
    }
}
