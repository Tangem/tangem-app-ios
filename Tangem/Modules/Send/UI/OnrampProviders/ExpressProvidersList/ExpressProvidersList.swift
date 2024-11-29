//
//  ExpressProvidersList.swift
//  TangemApp
//
//  Created by Sergey Balashov on 26.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct ExpressProvidersList: View {
    let providersViewData: [OnrampProviderRowViewData]

    var body: some View {
        ForEach(providersViewData) { data in
            OnrampProviderRowView(data: data)

            if providersViewData.last?.id != data.id {
                Separator(height: .minimal, color: Colors.Stroke.primary)
                    .padding(.leading, 62)
            }
        }
    }
}
