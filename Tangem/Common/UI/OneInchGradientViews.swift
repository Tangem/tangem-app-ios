//
//  OneInchGradientViews.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct OneInchGradientView: View {
    let startColor: Color
    let stopColor: Color
    let radius: Double

    var body: some View {
        RadialGradient(
            colors: [startColor.opacity(0.9), stopColor.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
    }
}

struct OneInchBlueGradientView: View {
    let radius: Double

    var body: some View {
        OneInchGradientView(startColor: Colors.Old.OneInch.blueGradientStart, stopColor: Colors.Old.OneInch.blueGradientStop, radius: radius)
    }
}

struct OneInchRedGradientView: View {
    let radius: Double

    var body: some View {
        OneInchGradientView(startColor: Colors.Old.OneInch.redGradientStart, stopColor: Colors.Old.OneInch.redGradientStop, radius: radius)
    }
}

struct OneInchPinkGradientView: View {
    let radius: Double

    var body: some View {
        OneInchGradientView(startColor: Colors.Old.OneInch.pinkGradientStart, stopColor: Colors.Old.OneInch.pinkGradientStop, radius: radius)
    }
}
