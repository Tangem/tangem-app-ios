//
//  SensitiveInformationModifier.swift
//  Tangem
//
//  Created by Andrey Chukavin on 02.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SensitiveInformationModifier: ViewModifier {
    let showSensitiveInformation: Bool

    func body(content: Content) -> some View {
        if showSensitiveInformation {
            content
        } else {
            Text("•••")
        }
    }
}

extension View {
    @ViewBuilder
    func showSensitiveInformation(_ showSensitiveInformation: Bool) -> some View {
        modifier(
            SensitiveInformationModifier(showSensitiveInformation: showSensitiveInformation)
        )
    }
}

private struct SensitiveInformationTestView: View {
    @State var showBalance = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showBalance.toggle()
            } label: {
                Image(systemName: showBalance ? "eye" : "eye.slash")
            }

            HStack {
                Text("$1 000 000,00")
                    .showSensitiveInformation(showBalance)
                    .style(Fonts.Bold.largeTitle, color: Colors.Text.primary1)
                    .border(Color.red)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SensitiveInformation_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            SensitiveInformationTestView()
                .padding()
                .previewLayout(.fixed(width: 300, height: 200))
                .preferredColorScheme($0)
        }
    }
}
