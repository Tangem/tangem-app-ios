//
//  BackUpWarningView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct BackUpWarningButton: View {
    let tapAction: () -> Void

    var body: some View {
        Button {
            tapAction()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                Assets.warningIcon.image
                    .frame(width: 42, height: 42)
                    .background(Color.tangemBgGray)
                    .cornerRadius(21)
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.warningNoBackupTitle)
                        .font(.system(size: 15, weight: .medium))

                    Text(Localization.warningNoBackupMessage)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.tangemTextGray)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)

                Spacer()

                Assets.chevron.image
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .contentShape(Rectangle())
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BackUpWarningView_Previews: PreviewProvider {
    static var previews: some View {
        BackUpWarningButton(tapAction: {})
    }
}
