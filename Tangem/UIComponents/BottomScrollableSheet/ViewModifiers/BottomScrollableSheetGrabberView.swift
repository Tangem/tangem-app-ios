//
//  BottomScrollableSheetGrabberView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 29.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

private struct BottomScrollableSheetGrabberView: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(Colors.Icon.inactive)
            .frame(size: Constants.grabberSize)
            .padding(.vertical, 8.0)
            .infinityFrame(axis: .horizontal)
    }
}

// MARK: - Constants

private extension BottomScrollableSheetGrabberView {
    enum Constants {
        static var grabberSize: CGSize { CGSize(width: 32.0, height: 4.0) }
    }
}

// MARK: - Convenience extensions

extension View {
    func bottomScrollableSheetGrabber() -> some View {
        overlay(BottomScrollableSheetGrabberView(), alignment: .top)
    }
}
