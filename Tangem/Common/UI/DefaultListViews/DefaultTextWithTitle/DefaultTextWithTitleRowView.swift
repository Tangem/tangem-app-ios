//
//  DefaultTextWithTitleRowView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct DefaultTextWithTitleRowView: View {
    let data: DefaultTextWithTitleRowViewData

    private var titleGeometryEffect: GeometryEffect?
    private var textGeometryEffect: GeometryEffect?

    init(data: DefaultTextWithTitleRowViewData) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(data.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .lineLimit(1)
                .matchedGeometryEffect(titleGeometryEffect)

            Text(data.text)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .matchedGeometryEffect(textGeometryEffect)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension DefaultTextWithTitleRowView: Setupable {
    func titleGeometryEffect(_ effect: GeometryEffect?) -> Self {
        map { $0.titleGeometryEffect = effect }
    }

    func textGeometryEffect(_ effect: GeometryEffect?) -> Self {
        map { $0.textGeometryEffect = effect }
    }
}

#Preview {
    GroupedScrollView {
        GroupedSection(DefaultTextWithTitleRowViewData(title: "Title", text: "Text")) { data in
            DefaultTextWithTitleRowView(data: data)
        }

        GroupedSection(DefaultTextWithTitleRowViewData(title: "Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title Title ", text: "Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text Text ")) { data in
            DefaultTextWithTitleRowView(data: data)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
