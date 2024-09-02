//
//  BottomScrollableSheetGrabberView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 29.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

extension View {
    func bottomScrollableSheetGrabber() -> some View {
        overlay(alignment: .top) {
            GrabberViewFactory()
                .makeSwiftUIView()
        }
    }
}
