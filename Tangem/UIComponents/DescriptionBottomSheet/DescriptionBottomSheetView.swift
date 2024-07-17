//
//  DescriptionBottomSheetView.swift
//  Tangem
//
//  Created by Andrew Son on 16/07/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct DescriptionBottomSheetInfo: Identifiable, Equatable {
    let id: UUID = .init()

    let title: String?
    let description: String

    static func == (lhs: DescriptionBottomSheetInfo, rhs: DescriptionBottomSheetInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct DescriptionBottomSheetView: View {
    let info: DescriptionBottomSheetInfo
    var availableHeight: CGFloat

    var sheetHeight: Binding<CGFloat> = .constant(0)
    @State private var containerHeight: CGFloat = 0

    var body: some View {
        textContent
            .overlay {
                textContent
                    .opacity(0)
                    .readGeometry(\.size.height, onChange: { value in
                        sheetHeight.wrappedValue = value
                    })
            }
            .padding(.horizontal, 16)
    }

    private var textContent: some View {
        VStack(spacing: 14) {
            if let title = info.title {
                Text(title)
                    .multilineTextAlignment(.center)
                    .style(Fonts.Bold.body, color: Colors.Text.primary1)
                    .padding(.vertical, 12)
            }

            Text(info.description)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 16)
    }
}

extension DescriptionBottomSheetView: SelfSizingBottomSheetContent, Setupable {
    func setContentHeightBinding(_ binding: ContentHeightBinding) -> Self {
        map { $0.sheetHeight = binding }
    }
}
