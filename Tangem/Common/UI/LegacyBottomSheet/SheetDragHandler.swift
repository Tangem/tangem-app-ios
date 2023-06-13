//
//  SheetDragHandler.swift
//  Tangem
//
//  Created by Andrey Chukavin on 08.02.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct SheetDragHandler: View {
    var body: some View {
        Rectangle()
            .frame(size: .init(width: 33, height: 5))
            .cornerRadius(2.5)
            .padding(.top, 12)
            .foregroundColor(.tangemGrayLight4)
    }
}

struct SheetDragHandler_Previews: PreviewProvider {
    static var previews: some View {
        SheetDragHandler()
    }
}
