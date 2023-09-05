//
//  OnboardingProgressCircle.swift
//  Tangem
//
//  Created by Andrew Son on 23.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnboardingProgressCircle: View {
    enum CircleState {
        case future
        case current
        case passed

        var animValue: CGFloat {
            switch self {
            case .future: return 0
            default: return 1
            }
        }
    }

    var index: Int
    var selectedIndex: Int
    var circleDiameter: CGFloat = 17
    var outerCircleDiameter: CGFloat = 31
    var lineWidth: CGFloat = 3

    var state: CircleState {
        if index == selectedIndex {
            return .current
        } else if index > selectedIndex {
            return .future
        } else {
            return .passed
        }
    }

    var gradientStop: CGFloat {
        state.animValue
    }

    var body: some View {
        ZStack {
            Rectangle()
                .modifier(AnimatableGradient(
                    backgroundColor: Colors.Icon.accent,
                    progressColor: Colors.Icon.accent,
                    gradientStop: gradientStop
                )
                )
                .frame(width: circleDiameter, height: circleDiameter)
                .cornerRadius(circleDiameter / 2)
            Rectangle()
                .foregroundColor(state == .passed ? Colors.Icon.accent : .white)
                .frame(width: circleDiameter - lineWidth * 2, height: circleDiameter - lineWidth * 2)
                .cornerRadius(circleDiameter / 2)
            Checkmark(filled: state == .passed)
                .frame(width: circleDiameter, height: circleDiameter)
        }
    }
}

struct OnboardingProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            OnboardingProgressCircle(index: 0, selectedIndex: 0)
            OnboardingProgressCircle(index: 1, selectedIndex: 0)
            OnboardingProgressCircle(index: 2, selectedIndex: 4)
        }
    }
}
